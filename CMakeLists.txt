cmake_minimum_required(VERSION 3.16)

project(CanvasDesk VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Gui Qml Widgets)

if(POLICY QTP0001)
    qt_policy(SET QTP0001 NEW)
endif()

add_subdirectory(src)
