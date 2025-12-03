#include "WindowManager.h"
#include "ExtForeignToplevelManager.h"
#include "WlrWindowManager.h"
#include <QDebug>
#include <QIcon>
#include <QMetaObject>

using namespace KWayland::Client;

WindowManager::WindowManager(QObject *parent) : QObject(parent) {
  qWarning() << "╔══════════════════════════════════════════╗";
  qWarning() << "║ WindowManager::WindowManager() CALLED   ║";
  qWarning() << "╚══════════════════════════════════════════╝";

  // Use the Wayland display from environment
  QByteArray waylandDisplay = qgetenv("WAYLAND_DISPLAY");
  qInfo() << "=== WindowManager initialization starting ===";
  qInfo() << "WAYLAND_DISPLAY:" << waylandDisplay;
  qInfo() << "XDG_SESSION_TYPE:" << qgetenv("XDG_SESSION_TYPE");
  qInfo() << "XDG_CURRENT_DESKTOP:" << qgetenv("XDG_CURRENT_DESKTOP");
  if (waylandDisplay.isEmpty()) {
    qWarning() << "WAYLAND_DISPLAY not set, window management unavailable";
    return;
  }

  // Try wlr_foreign_toplevel_management_v1 first (works on Sway, Hyprland,
  // labwc, etc.)
  qInfo() << "Trying wlr_foreign_toplevel_management_v1...";
  m_wlrManager = new WlrWindowManager(this);
  if (m_wlrManager->initialize()) {
    m_usingWlr = true;
    qInfo()
        << "✓ Using wlr_foreign_toplevel_management_v1 for window management";

    connect(m_wlrManager, &WlrWindowManager::windowAdded, this,
            &WindowManager::onWlrWindowChanged);
    connect(m_wlrManager, &WlrWindowManager::windowRemoved, this,
            &WindowManager::onWlrWindowChanged);
    connect(m_wlrManager, &WlrWindowManager::windowChanged, this,
            &WindowManager::onWlrWindowChanged);

    emit windowsChanged();
    qInfo() << "=== WindowManager initialization complete (wlr) ===";
    return;
  }
  qInfo() << "✗ wlr_foreign_toplevel_management_v1 not available";

  // Try ext_foreign_toplevel_list_v1 (works on KWin/Plasma 6 and other modern
  // compositors)
  qInfo() << "Trying ext_foreign_toplevel_list_v1...";
  delete m_wlrManager;
  m_wlrManager = nullptr;

  m_extManager = new ExtForeignToplevelManager(this);
  if (m_extManager->initialize()) {
    m_usingExt = true;
    qInfo() << "✓ Using ext_foreign_toplevel_list_v1 for window management";

    connect(m_extManager, &ExtForeignToplevelManager::windowAdded, this,
            &WindowManager::onWlrWindowChanged);
    connect(m_extManager, &ExtForeignToplevelManager::windowRemoved, this,
            &WindowManager::onWlrWindowChanged);
    connect(m_extManager, &ExtForeignToplevelManager::windowChanged, this,
            &WindowManager::onWlrWindowChanged);

    emit windowsChanged();
    qInfo() << "=== WindowManager initialization complete (ext) ===";
    return;
  }
  qInfo() << "✗ ext_foreign_toplevel_list_v1 not available";

  // Fall back to trying KWayland PlasmaWindowManagement (for older KDE or
  // special cases)
  qInfo() << "Trying KWayland PlasmaWindowManagement...";
  delete m_extManager;
  m_extManager = nullptr;

  // Delay Wayland initialization to avoid crashes during early QML setup
  QMetaObject::invokeMethod(
      this,
      [this, waylandDisplay]() {
        // Initialize KWayland connection
        m_connection = new ConnectionThread(this);
        m_connection->setSocketName(QString::fromUtf8(waylandDisplay));

        // Create registry to discover Wayland interfaces
        m_registry = new Registry(this);

        // Connect to signals before starting connection
        connect(m_connection, &ConnectionThread::connected, this, [this]() {
          if (!m_connection || !m_registry) {
            qWarning() << "Connection or registry null after connect";
            return;
          }

          qDebug() << "Wayland connected, setting up registry...";

          // Now setup registry after connection is established
          m_registry->create(m_connection);
          m_registry->setParent(m_connection);

          // Connect to PlasmaWindowManagement announcement
          connect(m_registry, &Registry::plasmaWindowManagementAnnounced, this,
                  &WindowManager::setupPlasmaWindowManagement);

          connect(m_registry, &Registry::interfacesAnnounced, this, [this]() {
            qDebug() << "All Wayland interfaces announced";

            // Check if PlasmaWindowManagement is available
            if (!m_registry->hasInterface(
                    Registry::Interface::PlasmaWindowManagement)) {
              qWarning() << "PlasmaWindowManagement not available";
              qWarning() << "Window management unavailable - use X11 session "
                            "or wlroots compositor";
            }
          });

          m_registry->setup();
        });

        connect(m_connection, &ConnectionThread::failed, this,
                []() { qWarning() << "Failed to connect to Wayland display"; });

        // Start connection
        m_connection->initConnection();
      },
      Qt::QueuedConnection);
}

void WindowManager::setupPlasmaWindowManagement(quint32 name, quint32 version) {
  m_windowManagement =
      m_registry->createPlasmaWindowManagement(name, version, this);

  if (!m_windowManagement) {
    qWarning() << "Failed to create PlasmaWindowManagement";
    return;
  }

  // Connect to window creation signal
  connect(m_windowManagement, &PlasmaWindowManagement::windowCreated, this,
          &WindowManager::onWindowCreated);
}

void WindowManager::onWindowCreated(PlasmaWindow *window) {
  if (!window)
    return;

  QString uuid = window->uuid();

  // Store the window
  m_plasmaWindows[uuid] = window;

  // Connect to window property changes
  connect(window, &PlasmaWindow::titleChanged, this,
          &WindowManager::windowsChanged);
  connect(window, &PlasmaWindow::activeChanged, this,
          &WindowManager::windowsChanged);
  connect(window, &PlasmaWindow::unmapped, this,
          &WindowManager::onWindowUnmapped);

  // Safety against dangling pointers
  connect(window, &QObject::destroyed, this, [this, uuid]() {
    if (m_plasmaWindows.contains(uuid)) {
      m_plasmaWindows.remove(uuid);
      emit windowsChanged();
    }
  });

  emit windowsChanged();
}

void WindowManager::onWindowUnmapped() {
  auto *window = qobject_cast<PlasmaWindow *>(sender());
  if (!window)
    return;

  QString uuid = window->uuid();
  m_plasmaWindows.remove(uuid);
  emit windowsChanged();
}

void WindowManager::onWlrWindowChanged() {
  qInfo() << "WindowManager::onWlrWindowChanged() called";
  emit windowsChanged();
}

QVariantList WindowManager::windows() const {
  QVariantList result;

  // If using wlr backend
  if (m_usingWlr && m_wlrManager) {
    for (auto *wlrWindow : m_wlrManager->windows()) {
      // Filter out the desktop window itself
      if (wlrWindow->appId == "canvasdesk" ||
          wlrWindow->title == "CanvasDesk") {
        continue;
      }

      QVariantMap win;
      win["id"] = wlrWindow->id;
      win["title"] = wlrWindow->title;
      win["appId"] = wlrWindow->appId;
      win["icon"] = wlrWindow->appId; // Use appId as icon name
      win["active"] = wlrWindow->active;
      win["workspace"] = 0;
      result.append(win);
    }
    return result;
  }

  // If using ext_foreign_toplevel_list_v1 backend
  if (m_usingExt && m_extManager) {
    for (auto *extWindow : m_extManager->windows()) {
      QVariantMap win;
      win["id"] = extWindow->identifier; // Use identifier as ID
      win["title"] = extWindow->title;
      win["appId"] = extWindow->appId;
      win["icon"] = extWindow->appId; // Use appId as icon name
      win["active"] = false; // ext protocol doesn't provide active state
      win["workspace"] = 0;
      result.append(win);
    }
    return result;
  }

  // KWayland backend
  for (auto *window : m_plasmaWindows) {
    if (!window) {
      qWarning() << "Null window pointer in m_plasmaWindows";
      continue;
    }
    // TODO: Implement proper virtual desktop filtering
    // For now, show all windows

    QVariantMap win;
    win["id"] = window->uuid();
    win["title"] = window->title();
    win["appId"] = window->appId();

    // Safely get icon
    QString iconName;
    if (!window->icon().isNull()) {
      iconName = window->icon().name();
    }
    win["icon"] = iconName;

    win["active"] = window->isActive();
    win["workspace"] = 0; // Default to workspace 0 for now

    qDebug() << "Window:" << win["title"] << "Icon:" << win["icon"];
    // Filter out the desktop window itself
    if (win["title"] == "CanvasDesk" || win["appId"] == "CanvasDesk") {
      continue;
    }

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

PlasmaWindow *WindowManager::findWindow(const QString &uuid) const {
  return m_plasmaWindows.value(uuid, nullptr);
}

void WindowManager::activate(int id) {
  // id is actually the UUID string passed from QML
  QString uuid = QString::number(id);
  auto *window = findWindow(uuid);
  if (window) {
    qDebug() << "Activating window:" << window->title();
    window->requestActivate();
  }
}

void WindowManager::close(int id) {
  QString uuid = QString::number(id);
  auto *window = findWindow(uuid);
  if (window) {
    qDebug() << "Closing window:" << window->title();
    window->requestClose();
  }
}

void WindowManager::minimize(int id) {
  QString uuid = QString::number(id);
  auto *window = findWindow(uuid);
  if (window) {
    qDebug() << "Toggling minimize for window:" << window->title();
    window->requestToggleMinimized();
  }
}

void WindowManager::switchToWorkspace(int index) { setCurrentWorkspace(index); }

void WindowManager::moveWindowToWorkspace(int windowId, int workspaceIndex) {
  // Note: PlasmaWindow virtual desktop management
  QString uuid = QString::number(windowId);
  auto *window = findWindow(uuid);
  if (window && workspaceIndex >= 0 && workspaceIndex < m_workspaceCount) {
    qDebug() << "Moving window to workspace:" << workspaceIndex + 1;
    // Use requestEnterVirtualDesktop with desktop ID as string
    window->requestEnterVirtualDesktop(QString::number(workspaceIndex + 1));
  }
}

void WindowManager::updateMockWindows() {
  // No-op with real windows
}
