/****************************************************************************
** Meta object code from reading C++ file 'WindowManager.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.10.1)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../../../src/core/WindowManager.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'WindowManager.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.10.1. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {
struct qt_meta_tag_ZN13WindowManagerE_t {};
} // unnamed namespace

template <> constexpr inline auto WindowManager::qt_create_metaobjectdata<qt_meta_tag_ZN13WindowManagerE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "WindowManager",
        "QML.Element",
        "auto",
        "QML.Singleton",
        "true",
        "windowsChanged",
        "",
        "currentWorkspaceChanged",
        "setupPlasmaWindowManagement",
        "name",
        "version",
        "onWindowCreated",
        "KWayland::Client::PlasmaWindow*",
        "window",
        "onWindowUnmapped",
        "activate",
        "id",
        "close",
        "minimize",
        "switchToWorkspace",
        "index",
        "moveWindowToWorkspace",
        "windowId",
        "workspaceIndex",
        "windows",
        "QVariantList",
        "currentWorkspace",
        "workspaceCount"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'windowsChanged'
        QtMocHelpers::SignalData<void()>(5, 6, QMC::AccessPublic, QMetaType::Void),
        // Signal 'currentWorkspaceChanged'
        QtMocHelpers::SignalData<void()>(7, 6, QMC::AccessPublic, QMetaType::Void),
        // Slot 'setupPlasmaWindowManagement'
        QtMocHelpers::SlotData<void(quint32, quint32)>(8, 6, QMC::AccessPrivate, QMetaType::Void, {{
            { QMetaType::UInt, 9 }, { QMetaType::UInt, 10 },
        }}),
        // Slot 'onWindowCreated'
        QtMocHelpers::SlotData<void(KWayland::Client::PlasmaWindow *)>(11, 6, QMC::AccessPrivate, QMetaType::Void, {{
            { 0x80000000 | 12, 13 },
        }}),
        // Slot 'onWindowUnmapped'
        QtMocHelpers::SlotData<void()>(14, 6, QMC::AccessPrivate, QMetaType::Void),
        // Method 'activate'
        QtMocHelpers::MethodData<void(int)>(15, 6, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 16 },
        }}),
        // Method 'close'
        QtMocHelpers::MethodData<void(int)>(17, 6, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 16 },
        }}),
        // Method 'minimize'
        QtMocHelpers::MethodData<void(int)>(18, 6, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 16 },
        }}),
        // Method 'switchToWorkspace'
        QtMocHelpers::MethodData<void(int)>(19, 6, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 20 },
        }}),
        // Method 'moveWindowToWorkspace'
        QtMocHelpers::MethodData<void(int, int)>(21, 6, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 22 }, { QMetaType::Int, 23 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'windows'
        QtMocHelpers::PropertyData<QVariantList>(24, 0x80000000 | 25, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 0),
        // property 'currentWorkspace'
        QtMocHelpers::PropertyData<int>(26, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 1),
        // property 'workspaceCount'
        QtMocHelpers::PropertyData<int>(27, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Constant),
    };
    QtMocHelpers::UintData qt_enums {
    };
    QtMocHelpers::UintData qt_constructors {};
    QtMocHelpers::ClassInfos qt_classinfo({
            {    1,    2 },
            {    3,    4 },
    });
    return QtMocHelpers::metaObjectData<WindowManager, void>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums, qt_constructors, qt_classinfo);
}
Q_CONSTINIT const QMetaObject WindowManager::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN13WindowManagerE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN13WindowManagerE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN13WindowManagerE_t>.metaTypes,
    nullptr
} };

void WindowManager::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<WindowManager *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->windowsChanged(); break;
        case 1: _t->currentWorkspaceChanged(); break;
        case 2: _t->setupPlasmaWindowManagement((*reinterpret_cast<std::add_pointer_t<quint32>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<quint32>>(_a[2]))); break;
        case 3: _t->onWindowCreated((*reinterpret_cast<std::add_pointer_t<KWayland::Client::PlasmaWindow*>>(_a[1]))); break;
        case 4: _t->onWindowUnmapped(); break;
        case 5: _t->activate((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 6: _t->close((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 7: _t->minimize((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 8: _t->switchToWorkspace((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 9: _t->moveWindowToWorkspace((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        default: ;
        }
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        switch (_id) {
        default: *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType(); break;
        case 3:
            switch (*reinterpret_cast<int*>(_a[1])) {
            default: *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType(); break;
            case 0:
                *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType::fromType< KWayland::Client::PlasmaWindow* >(); break;
            }
            break;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (WindowManager::*)()>(_a, &WindowManager::windowsChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (WindowManager::*)()>(_a, &WindowManager::currentWorkspaceChanged, 1))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<QVariantList*>(_v) = _t->windows(); break;
        case 1: *reinterpret_cast<int*>(_v) = _t->currentWorkspace(); break;
        case 2: *reinterpret_cast<int*>(_v) = _t->workspaceCount(); break;
        default: break;
        }
    }
    if (_c == QMetaObject::WriteProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 1: _t->setCurrentWorkspace(*reinterpret_cast<int*>(_v)); break;
        default: break;
        }
    }
}

const QMetaObject *WindowManager::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *WindowManager::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN13WindowManagerE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int WindowManager::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 10)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 10;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 10)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 10;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 3;
    }
    return _id;
}

// SIGNAL 0
void WindowManager::windowsChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void WindowManager::currentWorkspaceChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}
QT_WARNING_POP
