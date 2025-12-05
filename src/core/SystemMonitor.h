#pragma once

#include <QObject>
#include <QTimer>
#include <QVector>

class SystemMonitor : public QObject {
  Q_OBJECT
  Q_PROPERTY(double cpuUsage READ cpuUsage NOTIFY statsChanged)
  Q_PROPERTY(double memoryUsage READ memoryUsage NOTIFY statsChanged)
  Q_PROPERTY(double diskUsage READ diskUsage NOTIFY statsChanged)

public:
  explicit SystemMonitor(QObject *parent = nullptr);
  ~SystemMonitor();

  double cpuUsage() const { return m_cpuUsage; }
  double memoryUsage() const { return m_memoryUsage; }
  double diskUsage() const { return m_diskUsage; }

public slots:
  void updateStats();

signals:
  void statsChanged();

private:
  void readCpuUsage();
  void readMemoryUsage();
  void readDiskUsage();

  QTimer *m_timer;
  double m_cpuUsage = 0.0;
  double m_memoryUsage = 0.0;
  double m_diskUsage = 0.0;

  // CPU calculation helpers
  unsigned long long m_prevIdle = 0;
  unsigned long long m_prevTotal = 0;
};
