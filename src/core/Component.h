#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QVariantMap>

class Component : public QObject {
  Q_OBJECT
  Q_PROPERTY(QString type READ type WRITE setType NOTIFY typeChanged)
  Q_PROPERTY(QString role READ role WRITE setRole NOTIFY roleChanged)
  Q_PROPERTY(QVariantMap properties READ properties WRITE setProperties NOTIFY
                 propertiesChanged)
  Q_PROPERTY(QQmlListProperty<Component> childComponents READ childComponents)
  QML_ELEMENT

public:
  explicit Component(QObject *parent = nullptr);

  QString type() const;
  void setType(const QString &type);

  QString role() const;
  void setRole(const QString &role);

  QVariantMap properties() const;
  void setProperties(const QVariantMap &properties);

  QList<Component *> childrenList() const;
  QQmlListProperty<Component> childComponents();

signals:
  void typeChanged();
  void roleChanged();
  void propertiesChanged();

private:
  static void appendComponent(QQmlListProperty<Component> *list,
                              Component *component);
  static Component *componentAt(QQmlListProperty<Component> *list,
                                qsizetype index);
  static qsizetype componentCount(QQmlListProperty<Component> *list);
  static void clearComponents(QQmlListProperty<Component> *list);

  QString m_type;
  QString m_role;
  QVariantMap m_properties;
  QList<Component *> m_children;
};
