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

    // UI Role Colors (Assignable)
    Q_PROPERTY(QColor uiPrimaryColor READ uiPrimaryColor WRITE setUiPrimaryColor NOTIFY uiColorsChanged)
    Q_PROPERTY(QColor uiSecondaryColor READ uiSecondaryColor WRITE setUiSecondaryColor NOTIFY uiColorsChanged)
    Q_PROPERTY(QColor uiTertiaryColor READ uiTertiaryColor WRITE setUiTertiaryColor NOTIFY uiColorsChanged)
    Q_PROPERTY(QColor uiHighlightColor READ uiHighlightColor WRITE setUiHighlightColor NOTIFY uiColorsChanged)
    Q_PROPERTY(QColor uiTextColor READ uiTextColor WRITE setUiTextColor NOTIFY uiColorsChanged)
    Q_PROPERTY(QColor uiTitleBarLeftColor READ uiTitleBarLeftColor WRITE setUiTitleBarLeftColor NOTIFY uiColorsChanged)
    Q_PROPERTY(QColor uiTitleBarRightColor READ uiTitleBarRightColor WRITE setUiTitleBarRightColor NOTIFY uiColorsChanged)

public:
    explicit ThemeManager(QObject *parent = nullptr);

    QString wallpaperPath() const;
    void setWallpaperPath(const QString &path);

    int wallpaperFillMode() const;
    void setWallpaperFillMode(int mode);

    // Extracted Colors
    QColor primaryColor() const;
    QColor secondaryColor() const;
    QColor tertiaryColor() const;
    QColor accentColor() const;
    QColor neutralColor() const;
    QColor brightestColor() const;

    // UI Role Colors
    QColor uiPrimaryColor() const { return m_uiPrimary; }
    void setUiPrimaryColor(const QColor &c);

    QColor uiSecondaryColor() const { return m_uiSecondary; }
    void setUiSecondaryColor(const QColor &c);

    QColor uiTertiaryColor() const { return m_uiTertiary; }
    void setUiTertiaryColor(const QColor &c);

    QColor uiHighlightColor() const { return m_uiHighlight; }
    void setUiHighlightColor(const QColor &c);

    QColor uiTextColor() const { return m_uiText; }
    void setUiTextColor(const QColor &c);

    QColor uiTitleBarLeftColor() const { return m_uiTitleBarLeft; }
    void setUiTitleBarLeftColor(const QColor &c);

    QColor uiTitleBarRightColor() const { return m_uiTitleBarRight; }
    void setUiTitleBarRightColor(const QColor &c);

    QColor whiteColor() const { return QColor("#ffffff"); }
    QColor greyColor() const { return QColor("#808080"); }
    QColor blackColor() const { return QColor("#000000"); }

    Q_INVOKABLE void analyzeWallpaper(const QString &path);
    Q_INVOKABLE void saveColors();
    Q_INVOKABLE void loadColors();
    
    // Helper to assign an extracted color to a role by name
    Q_INVOKABLE void assignColorToRole(const QColor &color, const QString &roleName);

signals:
    void wallpaperPathChanged();
    void wallpaperFillModeChanged();
    void colorsChanged();
    void uiColorsChanged();

private:
    QString m_wallpaperPath;
    int m_wallpaperFillMode = 1; // PreserveAspectCrop (default)
    
    // Extracted
    QColor m_primary = "#3a3a3a";
    QColor m_secondary = "#2a2a2a";
    QColor m_tertiary = "#1a1a1a";
    QColor m_accent = "#4a90e2";
    QColor m_neutral = "#808080";
    QColor m_brightest = "#ffffff";

    // UI Roles
    QColor m_uiPrimary = "#3a3a3a";
    QColor m_uiSecondary = "#2a2a2a";
    QColor m_uiTertiary = "#1a1a1a";
    QColor m_uiHighlight = "#4a90e2";
    QColor m_uiText = "#ffffff";
    QColor m_uiTitleBarLeft = "#2a2a2a";
    QColor m_uiTitleBarRight = "#3a3a3a";

    void extractColors(const QImage &image);
    QString getColorsFilePath() const;
};

#endif // THEMEMANAGER_H
