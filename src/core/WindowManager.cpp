#include "WindowManager.h"
#include <QDebug>
#include <QMetaObject>
#include <QIcon>

using namespace KWayland::Client;

WindowManager::WindowManager(QObject *parent) : QObject(parent) {
  // Use the Wayland display from environment
  QByteArray waylandDisplay = qgetenv("WAYLAND_DISPLAY");
  if (waylandDisplay.isEmpty()) {
    qWarning() << "WAYLAND_DISPLAY not set, window management unavailable";
    return;
  }

  // Delay Wayland initialization to avoid crashes during early QML setup
  QMetaObject::invokeMethod(this, [this, waylandDisplay]() {
    // Initialize KWayland connection
    m_connection = new ConnectionThread(this);
    m_connection->setSocketName(QString::fromUtf8(waylandDisplay));

    // Create registry to discover Wayland interfaces
    m_registry = new Registry(this);

    // Connect to signals before starting connection
    connect(m_connection, &ConnectionThread::connected, this, [this]() {
      qDebug() << "Connected to Wayland display";
      
      // Now setup registry after connection is established
      m_registry->create(m_connection);
      
      // Connect to PlasmaWindowManagement announcement
      connect(m_registry, &Registry::plasmaWindowManagementAnnounced, this,
              &WindowManager::setupPlasmaWindowManagement);
      
      m_registry->setup();
    });
    
    connect(m_connection, &ConnectionThread::failed, this, []() {
      qWarning() << "Failed to connect to Wayland display";
    });

    // Start connection
    m_connection->initConnection();
  }, Qt::QueuedConnection);
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

QVariantList WindowManager::windows() const {
  QVariantList result;
  qDebug() << "WindowManager::windows() called, count:" << m_plasmaWindows.size();

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
