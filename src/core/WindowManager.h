#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>

class WindowManager : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

  Q_PROPERTY(QVariantList windows READ windows NOTIFY windowsChanged)

public:
  explicit WindowManager(QObject *parent = nullptr);

  QVariantList windows() const;

  Q_INVOKABLE void activate(int id);
  Q_INVOKABLE void close(int id);
  Q_INVOKABLE void minimize(int id);
  Q_INVOKABLE void createMockWindow(const QString &title, const QString &icon);

signals:
  void windowsChanged();

private:
  void updateMockWindows();

  QVariantList m_windows;
  int m_nextId = 1;
};
