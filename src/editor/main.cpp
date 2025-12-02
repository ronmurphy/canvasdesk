#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QUrl>
#include <QQuickImageProvider>
#include <QIcon>
#include <QPixmap>
#include <QDebug>
#include <cstdio>

class ThemeImageProvider : public QQuickImageProvider {
public:
    ThemeImageProvider() : QQuickImageProvider(QQuickImageProvider::Pixmap) {}

    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) override {
        QIcon icon = QIcon::fromTheme(id);
        // Fallback if theme icon not found
        if (icon.isNull()) {
             icon = QIcon::fromTheme("application-x-executable");
        }

        QSize actualSize = requestedSize;
        if (!actualSize.isValid()) {
            actualSize = QSize(64, 64); // Default size
        }
        
        if (size) *size = actualSize;
        
        return icon.pixmap(actualSize);
    }
};

int main(int argc, char *argv[]) {
  QGuiApplication app(argc, argv);

  QQmlApplicationEngine engine;
  engine.addImageProvider("theme", new ThemeImageProvider);

  // Add import paths for CanvasDesk modules
  engine.addImportPath("qrc:/");
  engine.addImportPath(QCoreApplication::applicationDirPath() + "/../core");
  engine.addImportPath(QCoreApplication::applicationDirPath() + "/../qml");

  const QUrl url(u"qrc:/CanvasDeskEditor/qml/EditorMain.qml"_qs);
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
