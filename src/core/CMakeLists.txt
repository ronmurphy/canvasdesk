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
        X11WindowManager.cpp
        X11WindowManager.h
)

target_link_libraries(CanvasDeskCore
    PRIVATE
        Qt6::Core
        Qt6::Qml
        PkgConfig::X11
        PkgConfig::XCB
        PkgConfig::XComposite
        PkgConfig::XRender
        PkgConfig::XDamage
)

target_include_directories(CanvasDeskCore 
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    PRIVATE
        ${CMAKE_CURRENT_BINARY_DIR}
)
