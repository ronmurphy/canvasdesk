#include "ThemeManager.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <QDir>
#include <QDebug>
#include <QMap>
#include <vector>
#include <algorithm>
#include <cmath>

ThemeManager::ThemeManager(QObject *parent) : QObject(parent) {
    loadColors();
}

QString ThemeManager::wallpaperPath() const {
    return m_wallpaperPath;
}

void ThemeManager::setWallpaperPath(const QString &path) {
    if (m_wallpaperPath != path) {
        m_wallpaperPath = path;
        emit wallpaperPathChanged();
        analyzeWallpaper(path);
    }
}

int ThemeManager::wallpaperFillMode() const {
    return m_wallpaperFillMode;
}

void ThemeManager::setWallpaperFillMode(int mode) {
    if (m_wallpaperFillMode != mode) {
        m_wallpaperFillMode = mode;
        emit wallpaperFillModeChanged();
        saveColors(); // Save settings
    }
}

QColor ThemeManager::primaryColor() const { return m_primary; }
QColor ThemeManager::secondaryColor() const { return m_secondary; }
QColor ThemeManager::tertiaryColor() const { return m_tertiary; }
QColor ThemeManager::accentColor() const { return m_accent; }
QColor ThemeManager::neutralColor() const { return m_neutral; }
QColor ThemeManager::brightestColor() const { return m_brightest; }

void ThemeManager::analyzeWallpaper(const QString &path) {
    QString localPath = path;
    if (localPath.startsWith("file://")) {
        localPath = localPath.mid(7);
    }

    QImage image(localPath);
    if (image.isNull()) {
        qWarning() << "Failed to load wallpaper for analysis:" << localPath;
        return;
    }

    extractColors(image);
    saveColors();
}

struct ColorCount {
    QRgb color;
    int count;
};

// Simple color distance
double colorDistance(QRgb c1, QRgb c2) {
    long rmean = ((long)qRed(c1) + (long)qRed(c2)) / 2;
    long r = (long)qRed(c1) - (long)qRed(c2);
    long g = (long)qGreen(c1) - (long)qGreen(c2);
    long b = (long)qBlue(c1) - (long)qBlue(c2);
    return std::sqrt((((512+rmean)*r*r)>>8) + 4*g*g + (((767-rmean)*b*b)>>8));
}

void ThemeManager::extractColors(const QImage &sourceImage) {
    // Scale down for performance
    QImage image = sourceImage.scaled(100, 100, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
    
    QMap<QRgb, int> histogram;
    int totalPixels = 0;

    // Quantize colors to reduce noise (5-bit per channel)
    for (int y = 0; y < image.height(); ++y) {
        for (int x = 0; x < image.width(); ++x) {
            QRgb pixel = image.pixel(x, y);
            int r = (qRed(pixel) / 8) * 8;
            int g = (qGreen(pixel) / 8) * 8;
            int b = (qBlue(pixel) / 8) * 8;
            QRgb quantized = qRgb(r, g, b);
            histogram[quantized]++;
            totalPixels++;
        }
    }

    std::vector<ColorCount> sortedColors;
    for (auto it = histogram.begin(); it != histogram.end(); ++it) {
        sortedColors.push_back({it.key(), it.value()});
    }

    // Sort by frequency
    std::sort(sortedColors.begin(), sortedColors.end(), [](const ColorCount &a, const ColorCount &b) {
        return a.count > b.count;
    });

    // Pick distinct top colors
    std::vector<QRgb> palette;
    double minDistance = 50.0; // Minimum distance to be considered distinct

    for (const auto &cc : sortedColors) {
        bool distinct = true;
        for (const auto &existing : palette) {
            if (colorDistance(cc.color, existing) < minDistance) {
                distinct = false;
                break;
            }
        }
        if (distinct) {
            palette.push_back(cc.color);
        }
        if (palette.size() >= 10) break; // Get top 10 candidates
    }

    // Assign colors
    if (palette.size() > 0) m_primary = QColor(palette[0]);
    if (palette.size() > 1) m_secondary = QColor(palette[1]);
    if (palette.size() > 2) m_tertiary = QColor(palette[2]);

    // Find brightest
    double maxLuma = -1;
    for (const auto &c : palette) {
        double luma = 0.299 * qRed(c) + 0.587 * qGreen(c) + 0.114 * qBlue(c);
        if (luma > maxLuma) {
            maxLuma = luma;
            m_brightest = QColor(c);
        }
    }

    // Find neutral (lowest saturation but not black/white)
    double minSat = 255;
    for (const auto &c : palette) {
        QColor col(c);
        if (col.saturation() < minSat && col.value() > 30 && col.value() < 230) {
            minSat = col.saturation();
            m_neutral = col;
        }
    }

    // Find accent (least common of the top set, or just a colorful one)
    // Let's pick the one with highest saturation that isn't primary
    double maxSat = -1;
    for (const auto &c : palette) {
        if (c == m_primary.rgb()) continue;
        QColor col(c);
        if (col.saturation() > maxSat) {
            maxSat = col.saturation();
            m_accent = col;
        }
    }
    
    // Fallback if palette is small
    if (palette.size() < 3) {
        m_accent = m_primary.lighter(150);
    }

    emit colorsChanged();
}

QString ThemeManager::getColorsFilePath() const {
    QString configDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + "/canvasdesk";
    QDir dir(configDir);
    if (!dir.exists()) dir.mkpath(".");
    return configDir + "/colors.json";
}

void ThemeManager::saveColors() {
    QJsonObject root;
    root["wallpaper"] = m_wallpaperPath;
    root["fillMode"] = m_wallpaperFillMode;

    QJsonObject colors;
    colors["primary"] = m_primary.name();
    colors["secondary"] = m_secondary.name();
    colors["tertiary"] = m_tertiary.name();
    colors["accent"] = m_accent.name();
    colors["neutral"] = m_neutral.name();
    colors["brightest"] = m_brightest.name();

    root["colors"] = colors;

    QFile file(getColorsFilePath());
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(root).toJson());
    }
}

void ThemeManager::loadColors() {
    QFile file(getColorsFilePath());
    if (file.open(QIODevice::ReadOnly)) {
        QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
        QJsonObject root = doc.object();

        m_wallpaperPath = root["wallpaper"].toString();
        m_wallpaperFillMode = root["fillMode"].toInt(1);

        QJsonObject colors = root["colors"].toObject();
        if (!colors.isEmpty()) {
            m_primary = QColor(colors["primary"].toString(m_primary.name()));
            m_secondary = QColor(colors["secondary"].toString(m_secondary.name()));
            m_tertiary = QColor(colors["tertiary"].toString(m_tertiary.name()));
            m_accent = QColor(colors["accent"].toString(m_accent.name()));
            m_neutral = QColor(colors["neutral"].toString(m_neutral.name()));
            m_brightest = QColor(colors["brightest"].toString(m_brightest.name()));
        }
        emit colorsChanged();
        emit wallpaperPathChanged();
        emit wallpaperFillModeChanged();
    }
}
