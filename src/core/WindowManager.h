#pragma once

#include <QHash>
#include <QJSEngine>
#include <QObject>
#include <QQmlEngine>
#include <QVariantList>
#include <QVariantMap>

class X11WindowManager;

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

private:
  void onX11WindowChanged();

  // X11 window manager
  X11WindowManager *m_x11Manager = nullptr;

  // Workspace tracking
  int m_currentWorkspace = 0;
  int m_workspaceCount = 4;
};
