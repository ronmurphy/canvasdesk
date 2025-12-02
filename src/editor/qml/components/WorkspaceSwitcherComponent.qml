import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CanvasDesk

Rectangle {
    id: root
    
    // Configurable properties
    property color backgroundColor: "#1a1a1a"
    property color activeColor: "#3a3a3a"
    property color inactiveColor: "#2a2a2a"
    
    // Editor support
    property bool editorOpen: false
    
    color: backgroundColor
    border.color: "#444"
    border.width: 1
    radius: 4
    
    Row {
        anchors.centerIn: parent
        spacing: 5
        
        Repeater {
            model: WindowManager.workspaceCount
            
            delegate: Rectangle {
                width: 40
                height: 30
                color: WindowManager.currentWorkspace === index ? root.activeColor : root.inactiveColor
                border.color: "#555"
                radius: 2
                
                Text {
                    anchors.centerIn: parent
                    text: (index + 1).toString()
                    color: "white"
                }
                
                MouseArea {
                    anchors.fill: parent
                    enabled: !root.editorOpen
                    onClicked: WindowManager.switchToWorkspace(index)
                }
            }
        }
    }
}
