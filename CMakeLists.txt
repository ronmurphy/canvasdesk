cmake_minimum_required(VERSION 3.16)

project(CanvasDesk VERSION 0.1 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)
find_package(PkgConfig REQUIRED)

# X11 libraries for window management
pkg_check_modules(X11 REQUIRED IMPORTED_TARGET x11)
pkg_check_modules(XCB REQUIRED IMPORTED_TARGET xcb)
pkg_check_modules(XComposite REQUIRED IMPORTED_TARGET xcomposite)
pkg_check_modules(XRender REQUIRED IMPORTED_TARGET xrender)
pkg_check_modules(XDamage REQUIRED IMPORTED_TARGET xdamage)
pkg_check_modules(Xft REQUIRED IMPORTED_TARGET xft)

if(POLICY QTP0001)
    qt_policy(SET QTP0001 NEW)
endif()

add_subdirectory(src)

# Create unified binary
qt_add_executable(canvasdesk
    src/main.cpp
)

target_link_libraries(canvasdesk PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    CanvasDeskCore
    CanvasDeskQml
)

# Make the unified binary depend on the editor so QML module is built
add_dependencies(canvasdesk canvasdesk-editor)

# Add the editor's QML module to the import path
set_target_properties(canvasdesk PROPERTIES
    QT_QML_IMPORT_PATH "${CMAKE_BINARY_DIR}/src/editor"
)

# Ensure the unified binary can find the editor QML
target_include_directories(canvasdesk PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/editor
)

install(TARGETS canvasdesk
    RUNTIME DESTINATION bin
)
