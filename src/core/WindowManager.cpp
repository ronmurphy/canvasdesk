#include "WindowManager.h"
#include <QDebug>

WindowManager::WindowManager(QObject *parent) : QObject(parent) {
  // Create some initial mock windows
  createMockWindow("Firefox", "firefox");
  createMockWindow("Terminal", "utilities-terminal");
  createMockWindow("File Manager", "system-file-manager");
}

QVariantList WindowManager::windows() const { return m_windows; }

void WindowManager::activate(int id) {
  qDebug() << "Activating window" << id;
  for (int i = 0; i < m_windows.size(); ++i) {
    QVariantMap win = m_windows[i].toMap();
    if (win["id"].toInt() == id) {
      win["active"] = true;
    } else {
      win["active"] = false;
    }
    m_windows[i] = win;
  }
  emit windowsChanged();
}

void WindowManager::close(int id) {
  qDebug() << "Closing window" << id;
  for (int i = 0; i < m_windows.size(); ++i) {
    QVariantMap win = m_windows[i].toMap();
    if (win["id"].toInt() == id) {
      m_windows.removeAt(i);
      emit windowsChanged();
      return;
    }
  }
}

void WindowManager::minimize(int id) {
  qDebug() << "Minimizing window" << id;
  for (int i = 0; i < m_windows.size(); ++i) {
    QVariantMap win = m_windows[i].toMap();
    if (win["id"].toInt() == id) {
      win["active"] = false;
      m_windows[i] = win;
      emit windowsChanged();
      return;
    }
  }
}

void WindowManager::createMockWindow(const QString &title,
                                     const QString &icon) {
  QVariantMap win;
  win["id"] = m_nextId++;
  win["title"] = title;
  win["icon"] = icon;
  win["active"] = false;
  m_windows.append(win);
  emit windowsChanged();
}
