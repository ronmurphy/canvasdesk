import QtQuick
import QtQuick.Controls
import CanvasDesk

Rectangle {
    id: root
    
    // Configurable properties
    property color textColor: Theme.uiTextColor
    property color barColor: Theme.uiHighlightColor
    property color backgroundColor: Theme.uiSecondaryColor
    
    // Editor support
    property bool editorOpen: false
    
    width: 150
    height: 80
    color: backgroundColor
    radius: 6
    border.color: Theme.uiTitleBarLeftColor
    border.width: 1
    
    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8
        
        // CPU
        Row {
            spacing: 10
            Text { text: "CPU"; color: root.textColor; width: 30; font.pixelSize: 10 }
            Rectangle {
                width: 80; height: 10; color: "#444444"; radius: 2
                Rectangle {
                    width: parent.width * SystemMonitor.cpuUsage
                    height: parent.height
                    color: root.barColor
                    radius: 2
                }
            }
        }
        
        // RAM
        Row {
            spacing: 10
            Text { text: "RAM"; color: root.textColor; width: 30; font.pixelSize: 10 }
            Rectangle {
                width: 80; height: 10; color: "#444444"; radius: 2
                Rectangle {
                    width: parent.width * SystemMonitor.memoryUsage
                    height: parent.height
                    color: root.barColor
                    radius: 2
                }
            }
        }
        
        // Disk
        Row {
            spacing: 10
            Text { text: "DSK"; color: root.textColor; width: 30; font.pixelSize: 10 }
            Rectangle {
                width: 80; height: 10; color: "#444444"; radius: 2
                Rectangle {
                    width: parent.width * SystemMonitor.diskUsage
                    height: parent.height
                    color: root.barColor
                    radius: 2
                }
            }
        }
    }
}
