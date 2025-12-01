
add_executable(canvasdesk-runtime
    main.cpp
)

target_link_libraries(canvasdesk-runtime PRIVATE
    Qt6::Quick
    Qt6::Gui
    Qt6::Qml
    CanvasDeskCore
    CanvasDeskQmlplugin
)
