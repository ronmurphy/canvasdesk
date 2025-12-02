
qt_add_executable(canvasdesk-editor
    main.cpp
)

qt_add_qml_module(canvasdesk-editor
    URI "CanvasDeskEditor"
    VERSION 1.0
    QML_FILES
        qml/EditorMain.qml
)

target_link_libraries(canvasdesk-editor PRIVATE
    Qt6::Quick
    Qt6::Gui
    Qt6::Qml
    CanvasDeskCore
    CanvasDeskQml
)
