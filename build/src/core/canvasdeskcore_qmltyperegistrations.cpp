/****************************************************************************
** Generated QML type registration code
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include <QtQml/qqml.h>
#include <QtQml/qqmlmoduleregistration.h>

#if __has_include(<AppManager.h>)
#  include <AppManager.h>
#endif
#if __has_include(<Component.h>)
#  include <Component.h>
#endif
#if __has_include(<LayoutManager.h>)
#  include <LayoutManager.h>
#endif
#if __has_include(<WindowManager.h>)
#  include <WindowManager.h>
#endif


#if !defined(QT_STATIC)
#define Q_QMLTYPE_EXPORT Q_DECL_EXPORT
#else
#define Q_QMLTYPE_EXPORT
#endif
Q_QMLTYPE_EXPORT void qml_register_types_CanvasDesk()
{
    QT_WARNING_PUSH QT_WARNING_DISABLE_DEPRECATED
    qmlRegisterTypesAndRevisions<AppManager>("CanvasDesk", 1);
    qmlRegisterTypesAndRevisions<Component>("CanvasDesk", 1);
    qmlRegisterTypesAndRevisions<LayoutManager>("CanvasDesk", 1);
    qmlRegisterTypesAndRevisions<WindowManager>("CanvasDesk", 1);
    QT_WARNING_POP
    qmlRegisterModule("CanvasDesk", 1, 0);
}

static const QQmlModuleRegistration canvasDeskRegistration("CanvasDesk", qml_register_types_CanvasDesk);
