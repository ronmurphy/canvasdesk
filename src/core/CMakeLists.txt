
add_library(CanvasDeskCore
    CanvasDeskCore.cpp
    Component.cpp
    Component.h
    LayoutManager.cpp
    LayoutManager.h
    AppManager.cpp
    AppManager.h
    WindowManager.cpp
    WindowManager.h
)

target_link_libraries(CanvasDeskCore PRIVATE
    Qt6::Quick
    Qt6::Gui
    Qt6::Qml
)

target_include_directories(CanvasDeskCore PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)
