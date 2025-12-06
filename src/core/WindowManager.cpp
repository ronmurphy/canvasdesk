#include "WindowManager.h"
#include "MonitorManager.h"
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

    // Initialize monitor manager (needs Display* from X11WindowManager)
    m_monitorManager = new MonitorManager(this);
    if (m_monitorManager->initialize(m_x11Manager->display())) {
      qInfo() << "✓ Monitor manager initialized";
    } else {
      qWarning() << "✗ Monitor manager failed to initialize";
    }
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

    // Show all windows (including minimized ones) so taskbar can restore them
    // Note: We previously only showed mapped windows, but minimized windows
    // need to appear in taskbar so user can click to restore
    if (!x11Window->mapped && x11Window->state != X11Window::Minimized) {
      continue;
    }

    QVariantMap win;
    win["id"] = (qulonglong)x11Window->window;
    win["title"] = x11Window->title;
    win["appId"] = x11Window->appId;
    win["icon"] = x11Window->appId; // Use appId as icon name

    // Check if this is the active window
    bool isActive =
        (m_x11Manager && m_x11Manager->activeWindow() == x11Window->window);
    win["active"] = isActive;
    win["workspace"] = 0;

    // Expose window state to QML
    QString stateStr = "normal";
    if (x11Window->state == X11Window::Minimized) {
      stateStr = "minimized";
    } else if (x11Window->state == X11Window::Maximized) {
      stateStr = "maximized";
    }
    win["state"] = stateStr;

    result.append(win);
  }

  return result;
}

int WindowManager::currentWorkspace() const { return m_currentWorkspace; }

void WindowManager::setCurrentWorkspace(int workspace) {
  if (workspace >= 0 && workspace < m_workspaceCount &&
      workspace != m_currentWorkspace) {
    m_currentWorkspace = workspace;
    emit currentWorkspaceChanged();
    emit windowsChanged();
  }
}

int WindowManager::workspaceCount() const { return m_workspaceCount; }

void WindowManager::activate(int id) {
  if (!m_x11Manager) {
    qWarning() << "[WindowManager] Cannot activate window - X11 manager not "
                  "initialized";
    return;
  }

  qInfo() << "[WindowManager] Activating window" << id;
  m_x11Manager->activateWindow((Window)id);
}

void WindowManager::close(int id) {
  if (!m_x11Manager) {
    qWarning()
        << "[WindowManager] Cannot close window - X11 manager not initialized";
    return;
  }

  qInfo() << "[WindowManager] Closing window" << id;
  m_x11Manager->closeWindow((Window)id);
}

void WindowManager::minimize(int id) {
  if (!m_x11Manager) {
    qWarning() << "[WindowManager] Cannot minimize window - X11 manager not "
                  "initialized";
    return;
  }

  qInfo() << "[WindowManager] Minimizing window" << id;
  m_x11Manager->minimizeWindow((Window)id);
}

void WindowManager::switchToWorkspace(int index) { setCurrentWorkspace(index); }

void WindowManager::moveWindowToWorkspace(int windowId, int workspaceIndex) {
  Q_UNUSED(windowId)
  Q_UNUSED(workspaceIndex)
  qDebug() << "TODO: Move window to workspace";
}

bool WindowManager::isTiling() const {
  if (!m_x11Manager)
    return false;
  return m_x11Manager->isTilingMode();
}

void WindowManager::toggleTiling() {
  if (m_x11Manager) {
    m_x11Manager->toggleTilingMode();
    emit tilingChanged();
    emit windowsChanged();
  }
}

void WindowManager::setStrut(int top, int bottom, int left, int right) {
  if (m_x11Manager) {
    m_x11Manager->setManualStrut(top, bottom, left, right);
  }
}
