#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QVariantList>
#include <QVariantMap>

class AppManager : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

  Q_PROPERTY(QVariantList apps READ apps NOTIFY appsChanged)

public:
  explicit AppManager(QObject *parent = nullptr);

  QVariantList apps() const;
  Q_INVOKABLE void launch(const QString &exec);
  Q_INVOKABLE void rescan();
  Q_INVOKABLE QString homeDir() const;

signals:
  void appsChanged();

private:
  void scanApps();
  QVariantMap parseDesktopFile(const QString &path);

  QVariantList m_apps;
};
