#include "MonitorManager.h"
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <X11/Xlib.h>
#include <X11/extensions/Xrandr.h>

MonitorManager::MonitorManager(QObject *parent) : QObject(parent) {
  // Set up config directory
  m_configDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)
                + "/canvasdesk/monitor-configs";

  QDir dir;
  if (!dir.exists(m_configDir)) {
    dir.mkpath(m_configDir);
    qInfo() << "[MonitorManager] Created config directory:" << m_configDir;
  }
}

MonitorManager::~MonitorManager() {
  // Nothing to clean up (Display* is owned by X11WindowManager)
}

bool MonitorManager::initialize(Display *display) {
  if (!display) {
    qWarning() << "[MonitorManager] Invalid display";
    return false;
  }

  m_display = display;
  m_root = DefaultRootWindow(m_display);

  // Check if XRandR is available
  int eventBase, errorBase;
  if (!XRRQueryExtension(m_display, &eventBase, &errorBase)) {
    qWarning() << "[MonitorManager] XRandR extension not available";
    return false;
  }

  qInfo() << "[MonitorManager] Initialized successfully";
  updateMonitors();
  return true;
}

void MonitorManager::updateMonitors() {
  if (!m_display) return;

  m_monitors.clear();
  m_outputMap.clear();
  m_crtcMap.clear();

  XRRScreenResources *res = XRRGetScreenResources(m_display, m_root);
  if (!res) {
    qWarning() << "[MonitorManager] Failed to get screen resources";
    return;
  }

  RROutput primaryOutput = XRRGetOutputPrimary(m_display, m_root);

  qInfo() << "[MonitorManager] Scanning monitors...";

  for (int i = 0; i < res->noutput; i++) {
    XRROutputInfo *outputInfo = XRRGetOutputInfo(m_display, res, res->outputs[i]);
    if (!outputInfo) continue;

    // Only process connected outputs
    if (outputInfo->connection == RR_Connected) {
      MonitorConfig config;
      config.name = QString::fromUtf8(outputInfo->name);
      config.primary = (res->outputs[i] == primaryOutput);
      config.enabled = (outputInfo->crtc != None);

      // Store output ID
      m_outputMap[config.name] = res->outputs[i];

      if (outputInfo->crtc) {
        XRRCrtcInfo *crtcInfo = XRRGetCrtcInfo(m_display, res, outputInfo->crtc);
        if (crtcInfo) {
          config.x = crtcInfo->x;
          config.y = crtcInfo->y;
          config.width = crtcInfo->width;
          config.height = crtcInfo->height;

          // Get rotation
          switch (crtcInfo->rotation) {
            case RR_Rotate_0: config.rotation = 0; break;
            case RR_Rotate_90: config.rotation = 90; break;
            case RR_Rotate_180: config.rotation = 180; break;
            case RR_Rotate_270: config.rotation = 270; break;
            default: config.rotation = 0;
          }

          m_crtcMap[config.name] = outputInfo->crtc;
          XRRFreeCrtcInfo(crtcInfo);
        }
      }

      // Get available modes (resolutions)
      for (int j = 0; j < outputInfo->nmode; j++) {
        for (int k = 0; k < res->nmode; k++) {
          if (res->modes[k].id == outputInfo->modes[j]) {
            QString mode = QString("%1x%2").arg(res->modes[k].width).arg(res->modes[k].height);
            if (!config.availableModes.contains(mode)) {
              config.availableModes.append(mode);
            }
            break;
          }
        }
      }

      m_monitors.append(config);
      qInfo() << "[MonitorManager] Found:" << config.name
              << config.width << "x" << config.height
              << "at" << config.x << "," << config.y
              << (config.primary ? "(PRIMARY)" : "")
              << (config.enabled ? "" : "(DISABLED)");
    }

    XRRFreeOutputInfo(outputInfo);
  }

  XRRFreeScreenResources(res);
  emit monitorsChanged();
}

QVariantList MonitorManager::monitors() const {
  QVariantList list;
  for (const auto &mon : m_monitors) {
    QVariantMap map;
    map["name"] = mon.name;
    map["x"] = mon.x;
    map["y"] = mon.y;
    map["width"] = mon.width;
    map["height"] = mon.height;
    map["rotation"] = mon.rotation;
    map["enabled"] = mon.enabled;
    map["primary"] = mon.primary;
    map["availableModes"] = mon.availableModes;
    list.append(map);
  }
  return list;
}

QVariantList MonitorManager::getAvailableResolutions(const QString &monitorName) {
  QVariantList list;
  MonitorConfig *mon = findMonitor(monitorName);
  if (mon) {
    for (const QString &mode : mon->availableModes) {
      list.append(mode);
    }
  }
  return list;
}

MonitorConfig *MonitorManager::findMonitor(const QString &name) {
  for (auto &mon : m_monitors) {
    if (mon.name == name) {
      return &mon;
    }
  }
  return nullptr;
}

bool MonitorManager::setMonitorPosition(const QString &name, int x, int y) {
  MonitorConfig *mon = findMonitor(name);
  if (!mon) {
    emit errorOccurred("Monitor not found: " + name);
    return false;
  }

  mon->x = x;
  mon->y = y;
  qInfo() << "[MonitorManager] Set position for" << name << "to" << x << "," << y;
  emit monitorsChanged();
  return true;
}

bool MonitorManager::setMonitorRotation(const QString &name, int rotation) {
  MonitorConfig *mon = findMonitor(name);
  if (!mon) {
    emit errorOccurred("Monitor not found: " + name);
    return false;
  }

  if (rotation != 0 && rotation != 90 && rotation != 180 && rotation != 270) {
    emit errorOccurred("Invalid rotation: " + QString::number(rotation));
    return false;
  }

  mon->rotation = rotation;
  qInfo() << "[MonitorManager] Set rotation for" << name << "to" << rotation;
  emit monitorsChanged();
  return true;
}

bool MonitorManager::setMonitorResolution(const QString &name, int width, int height) {
  MonitorConfig *mon = findMonitor(name);
  if (!mon) {
    emit errorOccurred("Monitor not found: " + name);
    return false;
  }

  mon->width = width;
  mon->height = height;
  qInfo() << "[MonitorManager] Set resolution for" << name << "to" << width << "x" << height;
  emit monitorsChanged();
  return true;
}

bool MonitorManager::setMonitorEnabled(const QString &name, bool enabled) {
  MonitorConfig *mon = findMonitor(name);
  if (!mon) {
    emit errorOccurred("Monitor not found: " + name);
    return false;
  }

  mon->enabled = enabled;
  qInfo() << "[MonitorManager] Set enabled for" << name << "to" << enabled;
  emit monitorsChanged();
  return true;
}

bool MonitorManager::setPrimaryMonitor(const QString &name) {
  MonitorConfig *mon = findMonitor(name);
  if (!mon) {
    emit errorOccurred("Monitor not found: " + name);
    return false;
  }

  // Unset primary on all monitors
  for (auto &m : m_monitors) {
    m.primary = false;
  }

  mon->primary = true;
  qInfo() << "[MonitorManager] Set primary monitor to" << name;
  emit monitorsChanged();
  return true;
}

// Helper function to convert Qt rotation to X11 Rotation
static Rotation qtRotationToX11(int rotation) {
  switch (rotation) {
    case 90: return RR_Rotate_90;
    case 180: return RR_Rotate_180;
    case 270: return RR_Rotate_270;
    default: return RR_Rotate_0;
  }
}

bool MonitorManager::applyConfiguration() {
  if (!m_display) {
    emit errorOccurred("Display not initialized");
    return false;
  }

  qInfo() << "[MonitorManager] Applying monitor configuration...";

  XRRScreenResources *res = XRRGetScreenResources(m_display, m_root);
  if (!res) {
    emit errorOccurred("Failed to get screen resources");
    return false;
  }

  bool success = true;

  // Apply settings for each monitor
  for (const auto &mon : m_monitors) {
    if (!m_outputMap.contains(mon.name)) {
      qWarning() << "[MonitorManager] Output not found for" << mon.name;
      continue;
    }

    RROutput output = m_outputMap[mon.name];
    XRROutputInfo *outputInfo = XRRGetOutputInfo(m_display, res, output);
    if (!outputInfo) continue;

    if (!mon.enabled) {
      // Disable monitor by setting CRTC to None
      if (m_crtcMap.contains(mon.name)) {
        XRRSetCrtcConfig(m_display, res, m_crtcMap[mon.name],
                        CurrentTime, 0, 0, None, RR_Rotate_0,
                        nullptr, 0);
        qInfo() << "[MonitorManager] Disabled" << mon.name;
      }
      XRRFreeOutputInfo(outputInfo);
      continue;
    }

    // Find matching mode
    RRMode selectedMode = None;
    for (int i = 0; i < outputInfo->nmode; i++) {
      for (int j = 0; j < res->nmode; j++) {
        if (res->modes[j].id == outputInfo->modes[i]) {
          if ((int)res->modes[j].width == mon.width &&
              (int)res->modes[j].height == mon.height) {
            selectedMode = res->modes[j].id;
            break;
          }
        }
      }
      if (selectedMode != None) break;
    }

    if (selectedMode == None) {
      qWarning() << "[MonitorManager] Mode not found for" << mon.name
                 << mon.width << "x" << mon.height;
      XRRFreeOutputInfo(outputInfo);
      continue;
    }

    // Get or create CRTC
    RRCrtc crtc = outputInfo->crtc;
    if (crtc == None && outputInfo->ncrtc > 0) {
      crtc = outputInfo->crtcs[0];
    }

    if (crtc == None) {
      qWarning() << "[MonitorManager] No CRTC available for" << mon.name;
      XRRFreeOutputInfo(outputInfo);
      continue;
    }

    // Apply configuration
    Rotation rotation = qtRotationToX11(mon.rotation);
    Status status = XRRSetCrtcConfig(m_display, res, crtc,
                                     CurrentTime,
                                     mon.x, mon.y,
                                     selectedMode,
                                     rotation,
                                     &output, 1);

    if (status != Success) {
      qWarning() << "[MonitorManager] Failed to configure" << mon.name;
      success = false;
    } else {
      qInfo() << "[MonitorManager] Configured" << mon.name
              << mon.width << "x" << mon.height << "at" << mon.x << "," << mon.y
              << "rotation:" << mon.rotation;
    }

    // Set primary
    if (mon.primary) {
      XRRSetOutputPrimary(m_display, m_root, output);
      qInfo() << "[MonitorManager] Set" << mon.name << "as primary";
    }

    XRRFreeOutputInfo(outputInfo);
  }

  XRRFreeScreenResources(res);
  XSync(m_display, False);

  if (success) {
    emit configurationApplied();
    qInfo() << "[MonitorManager] Configuration applied successfully";
  }

  return success;
}

bool MonitorManager::saveConfiguration(const QString &configName) {
  QString filePath = m_configDir + "/" + configName + ".json";

  if (saveConfigToFile(filePath, m_monitors)) {
    emit configurationSaved(configName);
    qInfo() << "[MonitorManager] Configuration saved:" << configName;
    return true;
  }

  return false;
}

bool MonitorManager::saveConfigToFile(const QString &filePath, const QList<MonitorConfig> &monitors) {
  QJsonObject root;
  QJsonArray monArray;

  for (const auto &mon : monitors) {
    QJsonObject monObj;
    monObj["name"] = mon.name;
    monObj["x"] = mon.x;
    monObj["y"] = mon.y;
    monObj["width"] = mon.width;
    monObj["height"] = mon.height;
    monObj["rotation"] = mon.rotation;
    monObj["enabled"] = mon.enabled;
    monObj["primary"] = mon.primary;
    monArray.append(monObj);
  }

  root.insert("monitors", monArray);

  QJsonDocument doc(root);
  QFile file(filePath);
  if (!file.open(QIODevice::WriteOnly)) {
    emit errorOccurred("Failed to open file for writing: " + filePath);
    return false;
  }

  file.write(doc.toJson());
  file.close();
  return true;
}

bool MonitorManager::loadConfiguration(const QString &configName) {
  QString filePath = m_configDir + "/" + configName + ".json";

  QList<MonitorConfig> loadedMonitors;
  if (!loadConfigFromFile(filePath, loadedMonitors)) {
    return false;
  }

  // Update current monitors with loaded settings
  for (const auto &loaded : loadedMonitors) {
    MonitorConfig *mon = findMonitor(loaded.name);
    if (mon) {
      mon->x = loaded.x;
      mon->y = loaded.y;
      mon->width = loaded.width;
      mon->height = loaded.height;
      mon->rotation = loaded.rotation;
      mon->enabled = loaded.enabled;
      mon->primary = loaded.primary;
    }
  }

  emit monitorsChanged();
  emit configurationLoaded(configName);
  qInfo() << "[MonitorManager] Configuration loaded:" << configName;
  return true;
}

bool MonitorManager::loadConfigFromFile(const QString &filePath, QList<MonitorConfig> &monitors) {
  QFile file(filePath);
  if (!file.open(QIODevice::ReadOnly)) {
    emit errorOccurred("Failed to open file for reading: " + filePath);
    return false;
  }

  QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
  file.close();

  if (!doc.isObject()) {
    emit errorOccurred("Invalid JSON format");
    return false;
  }

  QJsonObject root = doc.object();
  QJsonArray monArray = root["monitors"].toArray();

  monitors.clear();
  for (const auto &value : monArray) {
    QJsonObject monObj = value.toObject();
    MonitorConfig mon;
    mon.name = monObj["name"].toString();
    mon.x = monObj["x"].toInt();
    mon.y = monObj["y"].toInt();
    mon.width = monObj["width"].toInt();
    mon.height = monObj["height"].toInt();
    mon.rotation = monObj["rotation"].toInt();
    mon.enabled = monObj["enabled"].toBool();
    mon.primary = monObj["primary"].toBool();
    monitors.append(mon);
  }

  return true;
}

QStringList MonitorManager::savedConfigurations() const {
  QDir dir(m_configDir);
  QStringList filters;
  filters << "*.json";
  QStringList files = dir.entryList(filters, QDir::Files);

  // Remove .json extension
  for (auto &file : files) {
    file.chop(5);  // Remove ".json"
  }

  return files;
}

bool MonitorManager::deleteConfiguration(const QString &configName) {
  QString filePath = m_configDir + "/" + configName + ".json";
  QFile file(filePath);

  if (file.remove()) {
    qInfo() << "[MonitorManager] Deleted configuration:" << configName;
    return true;
  }

  emit errorOccurred("Failed to delete configuration: " + configName);
  return false;
}
