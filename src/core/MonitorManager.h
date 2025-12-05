#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

// Forward declare X11 types to avoid including headers in .h
typedef struct _XDisplay Display;
typedef unsigned long Window;
typedef unsigned long RROutput;
typedef unsigned long RRCrtc;

// Monitor configuration structure
struct MonitorConfig {
  QString name;
  int x = 0;
  int y = 0;
  int width = 1920;
  int height = 1080;
  int rotation = 0;  // 0, 90, 180, 270 degrees
  bool enabled = true;
  bool primary = false;

  // Available modes for this monitor
  QStringList availableModes;
};

class MonitorManager : public QObject {
  Q_OBJECT

public:
  explicit MonitorManager(QObject *parent = nullptr);
  ~MonitorManager();

  bool initialize(Display *display);

  // QML-accessible methods
  Q_INVOKABLE QVariantList monitors() const;
  Q_INVOKABLE QVariantList getAvailableResolutions(const QString &monitorName);
  Q_INVOKABLE bool setMonitorPosition(const QString &name, int x, int y);
  Q_INVOKABLE bool setMonitorRotation(const QString &name, int rotation);
  Q_INVOKABLE bool setMonitorResolution(const QString &name, int width, int height);
  Q_INVOKABLE bool setMonitorEnabled(const QString &name, bool enabled);
  Q_INVOKABLE bool setPrimaryMonitor(const QString &name);
  Q_INVOKABLE bool applyConfiguration();
  Q_INVOKABLE bool saveConfiguration(const QString &configName);
  Q_INVOKABLE bool loadConfiguration(const QString &configName);
  Q_INVOKABLE QStringList savedConfigurations() const;
  Q_INVOKABLE bool deleteConfiguration(const QString &configName);

  // Update monitor list from X11
  void updateMonitors();

signals:
  void monitorsChanged();
  void configurationApplied();
  void configurationSaved(const QString &name);
  void configurationLoaded(const QString &name);
  void errorOccurred(const QString &message);

private:
  Display *m_display = nullptr;
  Window m_root = 0;  // X11 None = 0
  QList<MonitorConfig> m_monitors;
  QHash<QString, RROutput> m_outputMap;  // Map monitor name to X11 output
  QHash<QString, RRCrtc> m_crtcMap;      // Map monitor name to X11 CRTC

  QString m_configDir;

  MonitorConfig *findMonitor(const QString &name);
  bool saveConfigToFile(const QString &filePath, const QList<MonitorConfig> &monitors);
  bool loadConfigFromFile(const QString &filePath, QList<MonitorConfig> &monitors);
  QString rotationToString(int rotation) const;
  int stringToRotation(const QString &rotation) const;
};
