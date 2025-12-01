#include "Component.h"

Component::Component(QObject *parent) : QObject(parent) {}

QString Component::type() const { return m_type; }

void Component::setType(const QString &type) {
  if (m_type == type)
    return;
  m_type = type;
  emit typeChanged();
}

QString Component::role() const { return m_role; }

void Component::setRole(const QString &role) {
  if (m_role == role)
    return;
  m_role = role;
  emit roleChanged();
}

QVariantMap Component::properties() const { return m_properties; }

void Component::setProperties(const QVariantMap &properties) {
  if (m_properties == properties)
    return;
  m_properties = properties;
  emit propertiesChanged();
}

QList<Component *> Component::childrenList() const { return m_children; }

QQmlListProperty<Component> Component::childComponents() {
  return QQmlListProperty<Component>(
      this, &m_children, &Component::appendComponent,
      &Component::componentCount, &Component::componentAt,
      &Component::clearComponents);
}

void Component::appendComponent(QQmlListProperty<Component> *list,
                                Component *component) {
  Component *parent = qobject_cast<Component *>(list->object);
  if (parent && component) {
    component->setParent(parent);
    parent->m_children.append(component);
  }
}

Component *Component::componentAt(QQmlListProperty<Component> *list,
                                  qsizetype index) {
  Component *parent = qobject_cast<Component *>(list->object);
  if (parent && index >= 0 && index < parent->m_children.count())
    return parent->m_children.at(index);
  return nullptr;
}

qsizetype Component::componentCount(QQmlListProperty<Component> *list) {
  Component *parent = qobject_cast<Component *>(list->object);
  if (parent)
    return parent->m_children.count();
  return 0;
}

void Component::clearComponents(QQmlListProperty<Component> *list) {
  Component *parent = qobject_cast<Component *>(list->object);
  if (parent) {
    qDeleteAll(parent->m_children);
    parent->m_children.clear();
  }
}
