#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QCommandLineParser>
#include <QUrl>
#include <QQuickImageProvider>
#include <QIcon>
#include <QPixmap>

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
  
  parser.process(app);

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
