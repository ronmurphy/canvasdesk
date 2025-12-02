#include "WlrWindowManager.h"
#include <QDebug>
#include <cstring>

// Wayland registry listener
static const struct wl_registry_listener registry_listener = {
    .global = WlrWindowManager::registryGlobal,
    .global_remove = WlrWindowManager::registryGlobalRemove
};

// Foreign toplevel manager listener
static const struct zwlr_foreign_toplevel_manager_v1_listener manager_listener = {
    .toplevel = WlrWindowManager::handleToplevel,
    .finished = WlrWindowManager::handleFinished
};

// Foreign toplevel handle listener
static const struct zwlr_foreign_toplevel_handle_v1_listener toplevel_listener = {
    .title = WlrWindowManager::toplevelTitle,
    .app_id = WlrWindowManager::toplevelAppId,
    .output_enter = nullptr,
    .output_leave = nullptr,
    .state = WlrWindowManager::toplevelState,
    .done = WlrWindowManager::toplevelDone,
    .closed = WlrWindowManager::toplevelClosed,
    .parent = nullptr
};

WlrWindowManager::WlrWindowManager(QObject *parent) : QObject(parent) {
}

WlrWindowManager::~WlrWindowManager() {
    qDeleteAll(m_windows);
    if (m_manager) {
        zwlr_foreign_toplevel_manager_v1_destroy(m_manager);
    }
    if (m_registry) {
        wl_registry_destroy(m_registry);
    }
    if (m_display) {
        wl_display_disconnect(m_display);
    }
}

bool WlrWindowManager::initialize() {
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
    
    if (!m_manager) {
        qWarning() << "wlr_foreign_toplevel_management_v1 not available";
        return false;
    }
    
    // Initial roundtrip to get all toplevels
    wl_display_roundtrip(m_display);
    
    qInfo() << "wlr_foreign_toplevel_management_v1 initialized successfully";
    return true;
}

void WlrWindowManager::registryGlobal(void *data, struct wl_registry *registry,
                                      uint32_t name, const char *interface, uint32_t version) {
    auto *self = static_cast<WlrWindowManager*>(data);
    
    if (strcmp(interface, zwlr_foreign_toplevel_manager_v1_interface.name) == 0) {
        self->m_manager = static_cast<zwlr_foreign_toplevel_manager_v1*>(
            wl_registry_bind(registry, name, &zwlr_foreign_toplevel_manager_v1_interface, version)
        );
        zwlr_foreign_toplevel_manager_v1_add_listener(self->m_manager, &manager_listener, self);
        qDebug() << "Bound to wlr_foreign_toplevel_manager_v1";
    }
}

void WlrWindowManager::registryGlobalRemove(void *data, struct wl_registry *registry, uint32_t name) {
    Q_UNUSED(data)
    Q_UNUSED(registry)
    Q_UNUSED(name)
}

void WlrWindowManager::handleToplevel(void *data, struct zwlr_foreign_toplevel_manager_v1 *manager,
                                      struct zwlr_foreign_toplevel_handle_v1 *handle) {
    Q_UNUSED(manager)
    auto *self = static_cast<WlrWindowManager*>(data);
    
    auto *window = new WlrWindow(self);
    window->id = self->m_nextId++;
    window->handle = handle;
    
    self->m_windows.insert(window->id, window);
    zwlr_foreign_toplevel_handle_v1_add_listener(handle, &toplevel_listener, window);
    
    qDebug() << "New toplevel window ID:" << window->id;
}

void WlrWindowManager::handleFinished(void *data, struct zwlr_foreign_toplevel_manager_v1 *manager) {
    Q_UNUSED(manager)
    auto *self = static_cast<WlrWindowManager*>(data);
    qDebug() << "Foreign toplevel manager finished";
    self->m_manager = nullptr;
}

void WlrWindowManager::toplevelTitle(void *data, struct zwlr_foreign_toplevel_handle_v1 *handle,
                                     const char *title) {
    Q_UNUSED(handle)
    auto *window = static_cast<WlrWindow*>(data);
    window->title = QString::fromUtf8(title);
    qDebug() << "Window" << window->id << "title:" << window->title;
}

void WlrWindowManager::toplevelAppId(void *data, struct zwlr_foreign_toplevel_handle_v1 *handle,
                                     const char *app_id) {
    Q_UNUSED(handle)
    auto *window = static_cast<WlrWindow*>(data);
    window->appId = QString::fromUtf8(app_id);
    qDebug() << "Window" << window->id << "app_id:" << window->appId;
}

void WlrWindowManager::toplevelState(void *data, struct zwlr_foreign_toplevel_handle_v1 *handle,
                                     struct wl_array *state) {
    Q_UNUSED(handle)
    auto *window = static_cast<WlrWindow*>(data);
    
    window->active = false;
    uint32_t *entry = static_cast<uint32_t*>(state->data);
    for (size_t i = 0; i < state->size / sizeof(uint32_t); i++) {
        if (entry[i] == ZWLR_FOREIGN_TOPLEVEL_HANDLE_V1_STATE_ACTIVATED) {
            window->active = true;
        }
    }
}

void WlrWindowManager::toplevelDone(void *data, struct zwlr_foreign_toplevel_handle_v1 *handle) {
    Q_UNUSED(handle)
    auto *window = static_cast<WlrWindow*>(data);
    auto *manager = qobject_cast<WlrWindowManager*>(window->parent());
    if (manager) {
        emit manager->windowChanged(window);
    }
}

void WlrWindowManager::toplevelClosed(void *data, struct zwlr_foreign_toplevel_handle_v1 *handle) {
    auto *window = static_cast<WlrWindow*>(data);
    auto *manager = qobject_cast<WlrWindowManager*>(window->parent());
    
    qDebug() << "Window" << window->id << "closed";
    
    if (manager) {
        uint32_t id = window->id;
        manager->m_windows.remove(id);
        emit manager->windowRemoved(id);
        window->deleteLater();
    }
    
    zwlr_foreign_toplevel_handle_v1_destroy(handle);
}
