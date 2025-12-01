#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>

class LayoutManager : public QObject {
  Q_OBJECT
  QML_ELEMENT

public:
  explicit LayoutManager(QObject *parent = nullptr);

  Q_INVOKABLE bool saveLayout(const QString &path, const QString &jsonContent);
  Q_INVOKABLE QString loadLayout(const QString &path);
  Q_INVOKABLE void runProject(const QString &path);
};
