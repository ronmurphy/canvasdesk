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
    
    width: 120
    height: 40
    color: backgroundColor
    radius: 4
    border.color: Theme.uiTitleBarLeftColor
    border.width: 1
    
    Row {
        anchors.centerIn: parent
        spacing: 10
        
        Text { 
            text: "RAM"
            color: root.textColor
            font.pixelSize: 12
            font.bold: true
        }
        
        Rectangle {
            width: 60
            height: 12
            color: "#444444"
            radius: 2
            
            Rectangle {
                width: parent.width * SystemMonitor.memoryUsage
                height: parent.height
                color: root.barColor
                radius: 2
            }
        }
    }
}
