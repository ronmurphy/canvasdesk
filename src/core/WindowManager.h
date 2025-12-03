#pragma once

#include <QHash>
#include <QJSEngine>
#include <QObject>
#include <QQmlEngine>
#include <QVariantList>
#include <QVariantMap>

// KWayland includes
#include <KWayland/Client/connection_thread.h>
#include <KWayland/Client/plasmawindowmanagement.h>
#include <KWayland/Client/registry.h>

class WlrWindowManager;
class ExtForeignToplevelManager;

class WindowManager : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

  Q_PROPERTY(QVariantList windows READ windows NOTIFY windowsChanged)
  Q_PROPERTY(int currentWorkspace READ currentWorkspace WRITE
                 setCurrentWorkspace NOTIFY currentWorkspaceChanged)
  Q_PROPERTY(int workspaceCount READ workspaceCount CONSTANT)

public:
  static WindowManager *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine) {
    Q_UNUSED(qmlEngine)
    Q_UNUSED(jsEngine)
    auto *wm = new WindowManager();
    wm->setParent(qmlEngine);
    return wm;
  }

  explicit WindowManager(QObject *parent = nullptr);

  QVariantList windows() const;
  int currentWorkspace() const;
  void setCurrentWorkspace(int workspace);
  int workspaceCount() const;

  Q_INVOKABLE void activate(int id);
  Q_INVOKABLE void close(int id);
  Q_INVOKABLE void minimize(int id);
  Q_INVOKABLE void switchToWorkspace(int index);
  Q_INVOKABLE void moveWindowToWorkspace(int windowId, int workspaceIndex);

signals:
  void windowsChanged();
  void currentWorkspaceChanged();

private slots:
  void setupPlasmaWindowManagement(quint32 name, quint32 version);
  void onWindowCreated(KWayland::Client::PlasmaWindow *window);
  void onWindowUnmapped();

private:
  KWayland::Client::PlasmaWindow *findWindow(const QString &uuid) const;
  void updateMockWindows();
  void onWlrWindowChanged();

  // KWayland members
  KWayland::Client::ConnectionThread *m_connection = nullptr;
  KWayland::Client::Registry *m_registry = nullptr;
  KWayland::Client::PlasmaWindowManagement *m_windowManagement = nullptr;
  QHash<QString, KWayland::Client::PlasmaWindow *> m_plasmaWindows;

  // wlr backend
  WlrWindowManager *m_wlrManager = nullptr;
  bool m_usingWlr = false;

  // ext_foreign_toplevel_list_v1 backend (for KWin)
  ExtForeignToplevelManager *m_extManager = nullptr;
  bool m_usingExt = false;

  // Workspace tracking
  int m_currentWorkspace = 0;
  int m_workspaceCount = 4;
};
