

qt_add_qml_module(CanvasDeskQml
    URI "CanvasDeskRuntime"
    VERSION 1.0
    QML_FILES
        Main.qml
    SOURCES
        # Link to Core library for C++ types
    DEPENDENCIES
        QtQuick
        QtQuick.Controls
)

# Link the Core library so QML types are registered
target_link_libraries(CanvasDeskQml PRIVATE CanvasDeskCore Qt6::Quick Qt6::Qml)
