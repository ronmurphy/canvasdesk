
add_executable(canvasdesk-editor
    main.cpp
)

target_link_libraries(canvasdesk-editor PRIVATE
    Qt6::Quick
    Qt6::Gui
    Qt6::Qml
    CanvasDeskCore
    CanvasDeskQml
)
