#ifndef THEMEMANAGER_H
#define THEMEMANAGER_H

#include <QObject>
#include <QColor>
#include <QVariantMap>
#include <QImage>
#include <QJsonObject>

class ThemeManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString wallpaperPath READ wallpaperPath WRITE setWallpaperPath NOTIFY wallpaperPathChanged)
    Q_PROPERTY(int wallpaperFillMode READ wallpaperFillMode WRITE setWallpaperFillMode NOTIFY wallpaperFillModeChanged)
    
    // Theme Colors
    Q_PROPERTY(QColor primaryColor READ primaryColor NOTIFY colorsChanged)
    Q_PROPERTY(QColor secondaryColor READ secondaryColor NOTIFY colorsChanged)
    Q_PROPERTY(QColor tertiaryColor READ tertiaryColor NOTIFY colorsChanged)
    Q_PROPERTY(QColor accentColor READ accentColor NOTIFY colorsChanged) // "Least common" / Distinctive
    Q_PROPERTY(QColor neutralColor READ neutralColor NOTIFY colorsChanged)
    Q_PROPERTY(QColor brightestColor READ brightestColor NOTIFY colorsChanged)
    
    // Standard Colors
    Q_PROPERTY(QColor whiteColor READ whiteColor CONSTANT)
    Q_PROPERTY(QColor greyColor READ greyColor CONSTANT)
    Q_PROPERTY(QColor blackColor READ blackColor CONSTANT)

public:
    explicit ThemeManager(QObject *parent = nullptr);

    QString wallpaperPath() const;
    void setWallpaperPath(const QString &path);

    int wallpaperFillMode() const;
    void setWallpaperFillMode(int mode);

    QColor primaryColor() const;
    QColor secondaryColor() const;
    QColor tertiaryColor() const;
    QColor accentColor() const;
    QColor neutralColor() const;
    QColor brightestColor() const;

    QColor whiteColor() const { return QColor("#ffffff"); }
    QColor greyColor() const { return QColor("#808080"); }
    QColor blackColor() const { return QColor("#000000"); }

    Q_INVOKABLE void analyzeWallpaper(const QString &path);
    Q_INVOKABLE void saveColors();
    Q_INVOKABLE void loadColors();

signals:
    void wallpaperPathChanged();
    void wallpaperFillModeChanged();
    void colorsChanged();

private:
    QString m_wallpaperPath;
    int m_wallpaperFillMode = 1; // PreserveAspectCrop (default)
    
    QColor m_primary = "#3a3a3a";
    QColor m_secondary = "#2a2a2a";
    QColor m_tertiary = "#1a1a1a";
    QColor m_accent = "#4a90e2";
    QColor m_neutral = "#808080";
    QColor m_brightest = "#ffffff";

    void extractColors(const QImage &image);
    QString getColorsFilePath() const;
};

#endif // THEMEMANAGER_H
