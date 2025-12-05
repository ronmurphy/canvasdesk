#include "SystemMonitor.h"
#include <QDebug>
#include <QFile>
#include <QRegularExpression>
#include <QTextStream>
#include <sys/statvfs.h>

SystemMonitor::SystemMonitor(QObject *parent) : QObject(parent) {
  m_timer = new QTimer(this);
  connect(m_timer, &QTimer::timeout, this, &SystemMonitor::updateStats);
  m_timer->start(1000); // Update every second

  // Initial update
  updateStats();
}

SystemMonitor::~SystemMonitor() {}

void SystemMonitor::updateStats() {
  readCpuUsage();
  readMemoryUsage();
  readDiskUsage();
  emit statsChanged();
}

void SystemMonitor::readCpuUsage() {
  QFile file("/proc/stat");
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
    return;

  QTextStream in(&file);
  QString line = in.readLine();
  if (line.startsWith("cpu ")) {
    QStringList parts =
        line.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
    if (parts.size() >= 5) {
      unsigned long long user = parts[1].toULongLong();
      unsigned long long nice = parts[2].toULongLong();
      unsigned long long system = parts[3].toULongLong();
      unsigned long long idle = parts[4].toULongLong();

      unsigned long long total = user + nice + system + idle;

      if (m_prevTotal > 0) {
        unsigned long long totalDelta = total - m_prevTotal;
        unsigned long long idleDelta = idle - m_prevIdle;

        if (totalDelta > 0) {
          m_cpuUsage = (double)(totalDelta - idleDelta) / totalDelta;
        }
      }

      m_prevTotal = total;
      m_prevIdle = idle;
    }
  }
}

void SystemMonitor::readMemoryUsage() {
  QFile file("/proc/meminfo");
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
    return;

  QTextStream in(&file);
  unsigned long totalMem = 0;
  unsigned long availableMem = 0;

  while (!in.atEnd()) {
    QString line = in.readLine();
    if (line.startsWith("MemTotal:")) {
      QStringList parts =
          line.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
      if (parts.size() >= 2)
        totalMem = parts[1].toULong();
    } else if (line.startsWith("MemAvailable:")) {
      QStringList parts =
          line.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
      if (parts.size() >= 2)
        availableMem = parts[1].toULong();
    }

    if (totalMem > 0 && availableMem > 0)
      break;
  }

  if (totalMem > 0) {
    m_memoryUsage = (double)(totalMem - availableMem) / totalMem;
  }
}

void SystemMonitor::readDiskUsage() {
  struct statvfs buffer;
  if (statvfs("/", &buffer) == 0) {
    unsigned long long total = buffer.f_blocks * buffer.f_frsize;
    unsigned long long available = buffer.f_bavail * buffer.f_frsize;
    unsigned long long used = total - available;

    if (total > 0) {
      m_diskUsage = (double)used / total;
    }
  }
}
