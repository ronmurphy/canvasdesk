#pragma once

#include <QObject>
#include <QHash>
#include <QVariantMap>
#include <wayland-client.h>

extern "C" {
#include "ext-foreign-toplevel-list-v1-client-protocol.h"
}

class ExtWindow : public QObject {
    Q_OBJECT
public:
    QString title;
    QString appId;
    QString identifier; // Unique stable identifier from protocol
    struct ext_foreign_toplevel_handle_v1 *handle = nullptr;

    explicit ExtWindow(QObject *parent = nullptr) : QObject(parent) {}
};

class ExtForeignToplevelManager : public QObject {
    Q_OBJECT
public:
    explicit ExtForeignToplevelManager(QObject *parent = nullptr);
    ~ExtForeignToplevelManager();

    bool initialize();
    QList<ExtWindow*> windows() const { return m_windows.values(); }

    static void registryGlobal(void *data, struct wl_registry *registry,
                              uint32_t name, const char *interface, uint32_t version);
    static void registryGlobalRemove(void *data, struct wl_registry *registry, uint32_t name);

    static void handleToplevel(void *data, struct ext_foreign_toplevel_list_v1 *list,
                               struct ext_foreign_toplevel_handle_v1 *handle);
    static void handleFinished(void *data, struct ext_foreign_toplevel_list_v1 *list);

    static void toplevelTitle(void *data, struct ext_foreign_toplevel_handle_v1 *handle, const char *title);
    static void toplevelAppId(void *data, struct ext_foreign_toplevel_handle_v1 *handle, const char *app_id);
    static void toplevelIdentifier(void *data, struct ext_foreign_toplevel_handle_v1 *handle, const char *identifier);
    static void toplevelDone(void *data, struct ext_foreign_toplevel_handle_v1 *handle);
    static void toplevelClosed(void *data, struct ext_foreign_toplevel_handle_v1 *handle);

signals:
    void windowAdded(ExtWindow *window);
    void windowRemoved(const QString &identifier);
    void windowChanged(ExtWindow *window);

private:
    struct wl_display *m_display = nullptr;
    struct wl_registry *m_registry = nullptr;
    struct ext_foreign_toplevel_list_v1 *m_list = nullptr;

    QHash<QString, ExtWindow*> m_windows; // Key is identifier string
};
