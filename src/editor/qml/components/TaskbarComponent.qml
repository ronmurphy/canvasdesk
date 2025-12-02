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
    
    ListView {
        anchors.fill: parent
        anchors.margins: 2
        orientation: ListView.Horizontal
        spacing: 4
        model: WindowManager.windows
        
        delegate: Rectangle {
            width: 100
            height: 30
            color: modelData.active ? root.activeColor : root.inactiveColor
            border.color: "#555"
            radius: 2
            
            Text {
                anchors.centerIn: parent
                text: modelData.title
                color: "white"
                elide: Text.ElideRight
                width: parent.width - 10
                horizontalAlignment: Text.AlignHCenter
            }
            
            MouseArea {
                anchors.fill: parent
                enabled: !root.editorOpen
                onClicked: WindowManager.activate(modelData.id)
            }
        }
        
        // Empty state
        Text {
            visible: parent.count === 0
            anchors.centerIn: parent
            text: "(no windows)"
            color: "#888"
            font.pixelSize: 12
        }
    }
}
