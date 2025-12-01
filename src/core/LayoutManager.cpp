#include "LayoutManager.h"
#include <QDebug>
#include <QFile>
#include <QProcess>
#include <QTextStream>

LayoutManager::LayoutManager(QObject *parent) : QObject(parent) {}

bool LayoutManager::saveLayout(const QString &path,
                               const QString &jsonContent) {
  QFile file(path);
  if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
    qWarning() << "Failed to open file for writing:" << path;
    return false;
  }

  QTextStream out(&file);
  out << jsonContent;
  file.close();
  return true;
}

QString LayoutManager::loadLayout(const QString &path) {
  QFile file(path);
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    qWarning() << "Failed to open file for reading:" << path;
    return "";
  }

  QTextStream in(&file);
  return in.readAll();
}

void LayoutManager::runProject(const QString &path) {
  // Assuming canvasdesk-runtime is in the same directory as the editor or in a
  // known location For development, we'll try to find it relative to the
  // current executable or build dir
  QString runtimePath =
      "./src/app/canvasdesk-runtime"; // Default for build dir structure

  // In a real scenario, we'd find the runtime in bin/ or lib/
  // For now, let's just try to run it.

  QString command = runtimePath + " --layout " + path;
  // We need to implement argument parsing in runtime later, but for now just
  // launching it is enough. Actually, the runtime currently doesn't take
  // arguments. We should make the runtime load "layout.json" by default or take
  // an arg.

  // Let's just launch it.
  QProcess::startDetached(runtimePath, QStringList());
}
