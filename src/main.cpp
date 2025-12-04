#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QCommandLineParser>
#include <QUrl>
#include <QQuickImageProvider>
#include <QIcon>
#include <QPixmap>
#include <QFile>
#include <QTextStream>
#include <QDir>
#include <QDebug>
#include <QStandardPaths>

class ThemeImageProvider : public QQuickImageProvider {
public:
    ThemeImageProvider() : QQuickImageProvider(QQuickImageProvider::Pixmap) {}

    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) override {
        QIcon icon = QIcon::fromTheme(id);
        if (icon.isNull()) {
             icon = QIcon::fromTheme("application-x-executable");
        }

        QSize actualSize = requestedSize;
        if (!actualSize.isValid()) {
            actualSize = QSize(64, 64);
        }
        
        if (size) *size = actualSize;
        return icon.pixmap(actualSize);
    }
};

int main(int argc, char *argv[]) {
  QGuiApplication app(argc, argv);
  app.setApplicationName("CanvasDesk");
  app.setApplicationVersion("0.1");
  app.setOrganizationName("CanvasDesk");

  // Parse command line arguments
  QCommandLineParser parser;
  parser.setApplicationDescription("CanvasDesk - Customizable Wayland Desktop Environment");
  parser.addHelpOption();
  parser.addVersionOption();
  
  QCommandLineOption runtimeOption(QStringList() << "r" << "runtime",
      "Run as desktop runtime only (no editor UI)");
  parser.addOption(runtimeOption);
  
  QCommandLineOption previewOption(QStringList() << "p" << "preview",
      "Start in preview mode");
  parser.addOption(previewOption);
  
  QCommandLineOption installSessionOption("installsession",
      "Install CanvasDesk as a desktop session (requires sudo/root)");
  parser.addOption(installSessionOption);
  
  QCommandLineOption uninstallSessionOption("uninstallsession",
      "Uninstall CanvasDesk desktop session (requires sudo/root)");
  parser.addOption(uninstallSessionOption);
  
  parser.process(app);
  
  // Handle session installation
  if (parser.isSet(installSessionOption)) {
    QString execPath = QCoreApplication::applicationFilePath();
    QString execDir = QFileInfo(execPath).absolutePath();
    QString wrapperScript = execDir + "/../canvasdesk-session";
    QString sessionDir = "/usr/share/xsessions";
    QString sessionFile = sessionDir + "/canvasdesk.desktop";

    // Check if directory exists
    if (!QDir(sessionDir).exists()) {
      qWarning() << "Directory" << sessionDir << "does not exist.";
      qWarning() << "You may need to create it first or check your X11 support.";
      return 1;
    }

    // Check if wrapper script exists
    if (!QFile::exists(wrapperScript)) {
      qWarning() << "Session wrapper script not found at" << wrapperScript;
      qWarning() << "Please ensure canvasdesk-session exists in the project root.";
      return 1;
    }

    // Create desktop entry content pointing to wrapper script
    QString desktopEntry =
      "[Desktop Entry]\n"
      "Name=CanvasDesk\n"
      "Comment=Customizable X11 Desktop Environment with Built-in Window Manager\n"
      "Exec=" + wrapperScript + "\n"
      "Type=Application\n"
      "DesktopNames=CanvasDesk\n"
      "X-KDE-PluginInfo-Name=canvasdesk\n";

    // Try to write the file
    QFile file(sessionFile);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
      QTextStream out(&file);
      out << desktopEntry;
      file.close();
      qInfo() << "Successfully installed session file to" << sessionFile;
      qInfo() << "Session wrapper:" << wrapperScript;
      qInfo() << "CanvasDesk should now appear in your login manager (as an X11 session).";
      qInfo() << "";
      qInfo() << "NOTE: Ensure xcb-cursor library is installed:";
      qInfo() << "      sudo pacman -S xcb-util-cursor";
      return 0;
    } else {
      qWarning() << "Failed to write to" << sessionFile;
      qWarning() << "Error:" << file.errorString();
      qWarning() << "You may need to run this with sudo:";
      qWarning() << "  sudo" << execPath << "--installsession";
      return 1;
    }
  }
  
  // Handle session uninstallation
  if (parser.isSet(uninstallSessionOption)) {
    QString sessionFile = "/usr/share/xsessions/canvasdesk.desktop";
    
    if (!QFile::exists(sessionFile)) {
      qInfo() << "Session file" << sessionFile << "does not exist. Nothing to uninstall.";
      return 0;
    }
    
    if (QFile::remove(sessionFile)) {
      qInfo() << "Successfully removed session file" << sessionFile;
      qInfo() << "CanvasDesk has been uninstalled from your login manager.";
      return 0;
    } else {
      qWarning() << "Failed to remove" << sessionFile;
      qWarning() << "You may need to run this with sudo:";
      qWarning() << "  sudo" << QCoreApplication::applicationFilePath() << "--uninstallsession";
      return 1;
    }
  }

  bool runtimeMode = parser.isSet(runtimeOption);
  bool previewMode = parser.isSet(previewOption);

  QQmlApplicationEngine engine;
  engine.addImageProvider("theme", new ThemeImageProvider);

  // Add import paths for CanvasDesk modules
  engine.addImportPath("qrc:/");
  engine.addImportPath(QCoreApplication::applicationDirPath() + "/../core");
  engine.addImportPath(QCoreApplication::applicationDirPath() + "/../qml");

  // Load appropriate QML based on mode
  QString qmlFile = runtimeMode ? "DesktopMode.qml" : "EditorMain.qml";
  const QUrl url(QUrl::fromLocalFile(QCoreApplication::applicationDirPath() + "/../src/editor/qml/" + qmlFile));

  // Check if we're running as a full desktop session (not in a dev environment)
  bool isSessionMode = qEnvironmentVariableIsSet("CANVASDESK_SESSION_MODE");
  engine.rootContext()->setContextProperty("isSessionMode", isSessionMode);

  // Set preview mode for editor
  if (!runtimeMode && previewMode) {
    engine.rootContext()->setContextProperty("startInPreview", true);
  }
  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreated, &app,
      [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
          QCoreApplication::exit(-1);
      },
      Qt::QueuedConnection);

  engine.load(url);

  return app.exec();
}
