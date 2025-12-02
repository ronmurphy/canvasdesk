
# Generate wlr foreign toplevel protocol
set(WLR_PROTO_XML "/usr/share/wlr-protocols/unstable/wlr-foreign-toplevel-management-unstable-v1.xml")
set(WLR_PROTO_C ${CMAKE_CURRENT_BINARY_DIR}/wlr-foreign-toplevel-management-unstable-v1-protocol.c)
set(WLR_PROTO_H ${CMAKE_CURRENT_BINARY_DIR}/wlr-foreign-toplevel-management-unstable-v1-client-protocol.h)

add_custom_command(
    OUTPUT ${WLR_PROTO_H}
    COMMAND ${WAYLAND_SCANNER} client-header ${WLR_PROTO_XML} ${WLR_PROTO_H}
    DEPENDS ${WLR_PROTO_XML}
    COMMENT "Generating wlr foreign toplevel header"
)

add_custom_command(
    OUTPUT ${WLR_PROTO_C}
    COMMAND ${WAYLAND_SCANNER} private-code ${WLR_PROTO_XML} ${WLR_PROTO_C}
    DEPENDS ${WLR_PROTO_XML}
    COMMENT "Generating wlr foreign toplevel code"
)

# Create a library for the protocol
add_library(wlr_protocol STATIC ${WLR_PROTO_C})
set_target_properties(wlr_protocol PROPERTIES 
    AUTOMOC OFF
    AUTORCC OFF
    AUTOUIC OFF
    LINKER_LANGUAGE C
)
target_include_directories(wlr_protocol PUBLIC ${CMAKE_CURRENT_BINARY_DIR})
target_link_libraries(wlr_protocol PUBLIC Wayland::Client)

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
        WlrWindowManager.cpp
        WlrWindowManager.h
        ${WLR_PROTO_H}
)

# Add dependency on protocol generation
add_dependencies(CanvasDeskCore wlr_protocol)

target_link_libraries(CanvasDeskCore 
    PRIVATE
        Qt6::Core
        Qt6::Qml
        Qt6::WaylandClient
        PkgConfig::KWAYLAND
    PUBLIC
        Wayland::Client
        wlr_protocol
)

target_include_directories(CanvasDeskCore 
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    PRIVATE
        ${CMAKE_CURRENT_BINARY_DIR}
)
