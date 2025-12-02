#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QUrl>

int main(int argc, char *argv[]) {
  QGuiApplication app(argc, argv);

  QQmlApplicationEngine engine;

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
