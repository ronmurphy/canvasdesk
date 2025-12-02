#include "LayoutManager.h"
#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QProcessEnvironment>
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
  Q_UNUSED(path); // For now, runtime always loads layout.json from current dir

  // Find the runtime executable relative to the editor
  QString runtimePath;

  // Try build directory structure first (for development)
  QString buildDirRuntime = QCoreApplication::applicationDirPath() + "/../app/canvasdesk-runtime";
  if (QFile::exists(buildDirRuntime)) {
    runtimePath = buildDirRuntime;
  } else {
    // Try installed location
    runtimePath = QCoreApplication::applicationDirPath() + "/canvasdesk-runtime";
  }

  if (!QFile::exists(runtimePath)) {
    qWarning() << "Runtime not found at:" << runtimePath;
    return;
  }

  qDebug() << "Launching runtime:" << runtimePath;

  // Set working directory to build root so runtime finds layout.json
  // Runtime is at: build/src/app/canvasdesk-runtime
  // We need to go to: build/
  QFileInfo runtimeInfo(runtimePath);
  QString buildDir = runtimeInfo.absoluteDir().absolutePath(); // Get src/app directory
  buildDir = QDir(buildDir).absoluteFilePath("../.."); // Go up two levels to build root
  buildDir = QDir(buildDir).canonicalPath(); // Resolve to absolute path

  qDebug() << "Runtime working directory:" << buildDir;

  // Launch in the build directory so it finds layout.json
  QProcess *process = new QProcess();
  process->setWorkingDirectory(buildDir);
  process->setProcessChannelMode(QProcess::ForwardedChannels); // Forward stdout/stderr to parent

  // Set up environment to find shared libraries and QML modules
  QProcessEnvironment env = QProcessEnvironment::systemEnvironment();

  // Add library paths
  QString ldPath = buildDir + "/src/core:" + buildDir + "/src/qml";
  QString existingLdPath = env.value("LD_LIBRARY_PATH");
  if (!existingLdPath.isEmpty()) {
    ldPath = ldPath + ":" + existingLdPath;
  }
  env.insert("LD_LIBRARY_PATH", ldPath);

  // Add QML import paths
  QString qmlPath = buildDir + "/src/core:" + buildDir + "/src/qml";
  QString existingQmlPath = env.value("QML2_IMPORT_PATH");
  if (!existingQmlPath.isEmpty()) {
    qmlPath = qmlPath + ":" + existingQmlPath;
  }
  env.insert("QML2_IMPORT_PATH", qmlPath);

  process->setProcessEnvironment(env);

  process->start(runtimePath, QStringList());

  if (!process->waitForStarted(3000)) {
    qWarning() << "Failed to start runtime:" << process->errorString();
    delete process;
  } else {
    qDebug() << "Runtime started successfully";
    // Don't delete process - let it run independently
  }
}
