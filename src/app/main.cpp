#include <QDir>
#include <QGuiApplication>
#include <QIODevice>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[]) {
  QGuiApplication app(argc, argv);

  QQmlApplicationEngine engine;

  // Add import paths for CanvasDesk modules
  engine.addImportPath("qrc:/");
  engine.addImportPath(
      QDir(QCoreApplication::applicationDirPath() + "/../qml").absolutePath());
  engine.addImportPath(
      QDir(QCoreApplication::applicationDirPath() + "/../core").absolutePath());

  const QUrl url(u"qrc:/CanvasDeskRuntime/Main.qml"_qs);
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
