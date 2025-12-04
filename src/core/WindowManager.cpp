#include "WindowManager.h"
#include "X11WindowManager.h"
#include <QDebug>

WindowManager::WindowManager(QObject *parent) : QObject(parent) {
  qInfo() << "╔══════════════════════════════════════════╗";
  qInfo() << "║ WindowManager initialized (X11)         ║";
  qInfo() << "╚══════════════════════════════════════════╝";

  // Initialize X11 window manager
  m_x11Manager = new X11WindowManager(this);
  if (m_x11Manager->initialize()) {
    qInfo() << "✓ X11 window manager active";

    connect(m_x11Manager, &X11WindowManager::windowAdded, this,
            &WindowManager::onX11WindowChanged);
    connect(m_x11Manager, &X11WindowManager::windowRemoved, this,
            &WindowManager::onX11WindowChanged);
    connect(m_x11Manager, &X11WindowManager::windowChanged, this,
            &WindowManager::onX11WindowChanged);

    emit windowsChanged();
  } else {
    qWarning() << "✗ X11 window manager failed to initialize";
  }
}

void WindowManager::onX11WindowChanged() {
  qInfo() << "[WindowManager] Window list changed";
  emit windowsChanged();
}

QVariantList WindowManager::windows() const {
  QVariantList result;

  if (!m_x11Manager) {
    return result;
  }

  for (auto *x11Window : m_x11Manager->windows()) {
    // Skip CanvasDesk itself
    if (x11Window->appId.toLower() == "canvasdesk") {
      continue;
    }

    // Only show mapped windows
    if (!x11Window->mapped) {
      continue;
    }

    QVariantMap win;
    win["id"] = (qulonglong)x11Window->window;
    win["title"] = x11Window->title;
    win["appId"] = x11Window->appId;
    win["icon"] = x11Window->appId; // Use appId as icon name
    win["active"] = false;          // TODO: track active window
    win["workspace"] = 0;
    result.append(win);
  }

  return result;
}

int WindowManager::currentWorkspace() const {
  return m_currentWorkspace;
}

void WindowManager::setCurrentWorkspace(int workspace) {
  if (workspace >= 0 && workspace < m_workspaceCount &&
      workspace != m_currentWorkspace) {
    m_currentWorkspace = workspace;
    emit currentWorkspaceChanged();
    emit windowsChanged();
  }
}

int WindowManager::workspaceCount() const {
  return m_workspaceCount;
}

void WindowManager::activate(int id) {
  Q_UNUSED(id)
  qDebug() << "TODO: Activate window" << id;
}

void WindowManager::close(int id) {
  Q_UNUSED(id)
  qDebug() << "TODO: Close window" << id;
}

void WindowManager::minimize(int id) {
  Q_UNUSED(id)
  qDebug() << "TODO: Minimize window" << id;
}

void WindowManager::switchToWorkspace(int index) {
  setCurrentWorkspace(index);
}

void WindowManager::moveWindowToWorkspace(int windowId, int workspaceIndex) {
  Q_UNUSED(windowId)
  Q_UNUSED(workspaceIndex)
  qDebug() << "TODO: Move window to workspace";
}
