
qt_add_library(CanvasDeskCore SHARED)

qt_add_qml_module(CanvasDeskCore
    URI "CanvasDesk"
    VERSION 1.0
    SOURCES
        CanvasDeskCore.cpp
        CanvasDeskCore.h
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
    Qt6::Core
    Qt6::Qml
    PkgConfig::KWAYLAND
)

target_include_directories(CanvasDeskCore PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)
