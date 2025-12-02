#pragma once

#include <QObject>
#include <QHash>
#include <QVariantMap>
#include <wayland-client.h>

extern "C" {
#include "wlr-foreign-toplevel-management-unstable-v1-client-protocol.h"
}

class WlrWindow : public QObject {
    Q_OBJECT
public:
    QString title;
    QString appId;
    uint32_t id;
    bool active = false;
    struct zwlr_foreign_toplevel_handle_v1 *handle = nullptr;
    
    explicit WlrWindow(QObject *parent = nullptr) : QObject(parent) {}
};

class WlrWindowManager : public QObject {
    Q_OBJECT
public:
    explicit WlrWindowManager(QObject *parent = nullptr);
    ~WlrWindowManager();
    
    bool initialize();
    QList<WlrWindow*> windows() const { return m_windows.values(); }
    
    static void registryGlobal(void *data, struct wl_registry *registry,
                              uint32_t name, const char *interface, uint32_t version);
    static void registryGlobalRemove(void *data, struct wl_registry *registry, uint32_t name);
    
    static void handleToplevel(void *data, struct zwlr_foreign_toplevel_manager_v1 *manager,
                               struct zwlr_foreign_toplevel_handle_v1 *handle);
    static void handleFinished(void *data, struct zwlr_foreign_toplevel_manager_v1 *manager);
    
    static void toplevelTitle(void *data, struct zwlr_foreign_toplevel_handle_v1 *handle, const char *title);
    static void toplevelAppId(void *data, struct zwlr_foreign_toplevel_handle_v1 *handle, const char *app_id);
    static void toplevelState(void *data, struct zwlr_foreign_toplevel_handle_v1 *handle, struct wl_array *state);
    static void toplevelDone(void *data, struct zwlr_foreign_toplevel_handle_v1 *handle);
    static void toplevelClosed(void *data, struct zwlr_foreign_toplevel_handle_v1 *handle);
    
signals:
    void windowAdded(WlrWindow *window);
    void windowRemoved(uint32_t id);
    void windowChanged(WlrWindow *window);
    
private:
    
    struct wl_display *m_display = nullptr;
    struct wl_registry *m_registry = nullptr;
    struct zwlr_foreign_toplevel_manager_v1 *m_manager = nullptr;
    
    QHash<uint32_t, WlrWindow*> m_windows;
    uint32_t m_nextId = 0;
};
