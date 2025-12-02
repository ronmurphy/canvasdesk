#include "ExtForeignToplevelManager.h"
#include <QDebug>
#include <cstring>

// Wayland registry listener
static const struct wl_registry_listener registry_listener = {
    .global = ExtForeignToplevelManager::registryGlobal,
    .global_remove = ExtForeignToplevelManager::registryGlobalRemove
};

// Foreign toplevel list listener
static const struct ext_foreign_toplevel_list_v1_listener list_listener = {
    .toplevel = ExtForeignToplevelManager::handleToplevel,
    .finished = ExtForeignToplevelManager::handleFinished
};

// Foreign toplevel handle listener
static const struct ext_foreign_toplevel_handle_v1_listener toplevel_listener = {
    .closed = ExtForeignToplevelManager::toplevelClosed,
    .done = ExtForeignToplevelManager::toplevelDone,
    .title = ExtForeignToplevelManager::toplevelTitle,
    .app_id = ExtForeignToplevelManager::toplevelAppId,
    .identifier = ExtForeignToplevelManager::toplevelIdentifier
};

ExtForeignToplevelManager::ExtForeignToplevelManager(QObject *parent) : QObject(parent) {
}

ExtForeignToplevelManager::~ExtForeignToplevelManager() {
    qDeleteAll(m_windows);
    if (m_list) {
        ext_foreign_toplevel_list_v1_stop(m_list);
        ext_foreign_toplevel_list_v1_destroy(m_list);
    }
    if (m_registry) {
        wl_registry_destroy(m_registry);
    }
    if (m_display) {
        wl_display_disconnect(m_display);
    }
}

bool ExtForeignToplevelManager::initialize() {
    m_display = wl_display_connect(nullptr);
    if (!m_display) {
        qWarning() << "Failed to connect to Wayland display";
        return false;
    }

    m_registry = wl_display_get_registry(m_display);
    if (!m_registry) {
        qWarning() << "Failed to get Wayland registry";
        return false;
    }

    wl_registry_add_listener(m_registry, &registry_listener, this);
    wl_display_roundtrip(m_display);

    if (!m_list) {
        qWarning() << "ext_foreign_toplevel_list_v1 not available";
        return false;
    }

    // Initial roundtrip to get all toplevels
    wl_display_roundtrip(m_display);

    qInfo() << "ext_foreign_toplevel_list_v1 initialized successfully";
    return true;
}

void ExtForeignToplevelManager::registryGlobal(void *data, struct wl_registry *registry,
                                               uint32_t name, const char *interface, uint32_t version) {
    auto *self = static_cast<ExtForeignToplevelManager*>(data);

    if (strcmp(interface, ext_foreign_toplevel_list_v1_interface.name) == 0) {
        self->m_list = static_cast<ext_foreign_toplevel_list_v1*>(
            wl_registry_bind(registry, name, &ext_foreign_toplevel_list_v1_interface, 1)
        );
        ext_foreign_toplevel_list_v1_add_listener(self->m_list, &list_listener, self);
        qDebug() << "Bound to ext_foreign_toplevel_list_v1";
    }
}

void ExtForeignToplevelManager::registryGlobalRemove(void *data, struct wl_registry *registry, uint32_t name) {
    Q_UNUSED(data)
    Q_UNUSED(registry)
    Q_UNUSED(name)
}

void ExtForeignToplevelManager::handleToplevel(void *data, struct ext_foreign_toplevel_list_v1 *list,
                                                struct ext_foreign_toplevel_handle_v1 *handle) {
    Q_UNUSED(list)
    auto *self = static_cast<ExtForeignToplevelManager*>(data);

    auto *window = new ExtWindow(self);
    window->handle = handle;

    // Note: We don't add to m_windows yet - wait for identifier event
    ext_foreign_toplevel_handle_v1_add_listener(handle, &toplevel_listener, window);

    qDebug() << "New toplevel window (waiting for identifier)";
}

void ExtForeignToplevelManager::handleFinished(void *data, struct ext_foreign_toplevel_list_v1 *list) {
    Q_UNUSED(list)
    auto *self = static_cast<ExtForeignToplevelManager*>(data);
    qDebug() << "Foreign toplevel list finished";
    self->m_list = nullptr;
}

void ExtForeignToplevelManager::toplevelTitle(void *data, struct ext_foreign_toplevel_handle_v1 *handle,
                                              const char *title) {
    Q_UNUSED(handle)
    auto *window = static_cast<ExtWindow*>(data);
    window->title = QString::fromUtf8(title);
    qDebug() << "Window" << window->identifier << "title:" << window->title;
}

void ExtForeignToplevelManager::toplevelAppId(void *data, struct ext_foreign_toplevel_handle_v1 *handle,
                                              const char *app_id) {
    Q_UNUSED(handle)
    auto *window = static_cast<ExtWindow*>(data);
    window->appId = QString::fromUtf8(app_id);
    qDebug() << "Window" << window->identifier << "app_id:" << window->appId;
}

void ExtForeignToplevelManager::toplevelIdentifier(void *data, struct ext_foreign_toplevel_handle_v1 *handle,
                                                    const char *identifier) {
    Q_UNUSED(handle)
    auto *window = static_cast<ExtWindow*>(data);
    auto *manager = qobject_cast<ExtForeignToplevelManager*>(window->parent());

    window->identifier = QString::fromUtf8(identifier);

    // Now that we have the identifier, add to the hash
    if (manager) {
        manager->m_windows.insert(window->identifier, window);
        qDebug() << "Window identifier:" << window->identifier;
    }
}

void ExtForeignToplevelManager::toplevelDone(void *data, struct ext_foreign_toplevel_handle_v1 *handle) {
    Q_UNUSED(handle)
    auto *window = static_cast<ExtWindow*>(data);
    auto *manager = qobject_cast<ExtForeignToplevelManager*>(window->parent());
    if (manager) {
        emit manager->windowChanged(window);
    }
}

void ExtForeignToplevelManager::toplevelClosed(void *data, struct ext_foreign_toplevel_handle_v1 *handle) {
    auto *window = static_cast<ExtWindow*>(data);
    auto *manager = qobject_cast<ExtForeignToplevelManager*>(window->parent());

    qDebug() << "Window" << window->identifier << "closed";

    if (manager) {
        QString identifier = window->identifier;
        manager->m_windows.remove(identifier);
        emit manager->windowRemoved(identifier);
        window->deleteLater();
    }

    ext_foreign_toplevel_handle_v1_destroy(handle);
}
