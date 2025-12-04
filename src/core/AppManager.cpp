#include "AppManager.h"
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QTextStream>

AppManager::AppManager(QObject *parent) : QObject(parent) {
  // Delay scanning to avoid issues during initialization
  QMetaObject::invokeMethod(this, &AppManager::scanApps, Qt::QueuedConnection);
}

QVariantList AppManager::apps() const { return m_apps; }

void AppManager::launch(const QString &exec) {
  // Basic launch logic: split by space, handle quotes roughly
  // For a real DE, use QProcess::startDetached with argument parsing
  // This is a simplified version.

  // Remove % field codes (e.g. %u, %F) which are common in .desktop files
  QString cleanExec = exec;
  cleanExec.replace(QRegularExpression("%[a-zA-Z]"), "");
  cleanExec = cleanExec.trimmed();

  qDebug() << "Launching:" << cleanExec;

  // Create process with current environment (inherits DISPLAY, etc.)
  QProcess process;
  process.setProgram("/bin/sh");
  process.setArguments(QStringList() << "-c" << cleanExec);
  process.startDetached();
}

void AppManager::rescan() { scanApps(); }

QString AppManager::homeDir() const { return QDir::homePath(); }

void AppManager::scanApps() {
  m_apps.clear();

  QStringList paths;
  paths << QStandardPaths::standardLocations(
      QStandardPaths::ApplicationsLocation);
  // Add common fallback if not in standard paths
  if (!paths.contains("/usr/share/applications")) {
    paths << "/usr/share/applications";
  }

  for (const QString &path : paths) {
    QDir dir(path);
    if (!dir.exists())
      continue;

    QStringList filters;
    filters << "*.desktop";
    dir.setNameFilters(filters);

    QFileInfoList list = dir.entryInfoList(QDir::Files);
    for (const QFileInfo &fileInfo : list) {
      QVariantMap app = parseDesktopFile(fileInfo.absoluteFilePath());
      if (!app.isEmpty() && !app["name"].toString().isEmpty()) {
        m_apps.append(app);
      }
    }
  }

  emit appsChanged();
}

QVariantMap AppManager::parseDesktopFile(const QString &path) {
  QFile file(path);
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
    return {};

  QVariantMap app;
  app["id"] = QFileInfo(path).fileName();

  QTextStream in(&file);
  bool inDesktopEntry = false;

  while (!in.atEnd()) {
    QString line = in.readLine().trimmed();
    if (line == "[Desktop Entry]") {
      inDesktopEntry = true;
      continue;
    }

    if (line.startsWith("[") && line != "[Desktop Entry]") {
      inDesktopEntry = false;
    }

    if (!inDesktopEntry)
      continue;

    if (line.startsWith("Name=")) {
      if (!app.contains(
              "name")) // Don't overwrite if already found (e.g. localized)
        app["name"] = line.mid(5);
    } else if (line.startsWith("Icon=")) {
      app["icon"] = line.mid(5);
    } else if (line.startsWith("Exec=")) {
      app["exec"] = line.mid(5);
    } else if (line.startsWith("NoDisplay=true")) {
      return {}; // Skip hidden apps
    }
  }

  return app;
}
