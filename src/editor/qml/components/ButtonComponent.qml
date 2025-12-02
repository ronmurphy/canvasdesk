import QtQuick
import QtQuick.Controls
import CanvasDesk

Rectangle {
    id: root
    
    // Configurable properties
    property string buttonText: "Button"
    property string execCommand: ""
    property string iconName: ""
    
    // Editor support
    property bool editorOpen: false
    
    color: "lightgray"
    border.color: "gray"
    radius: 4
    
    Text {
        anchors.centerIn: parent
        text: root.buttonText
        color: "black"
    }
    
    MouseArea {
        anchors.fill: parent
        enabled: !root.editorOpen
        onClicked: {
            if (root.execCommand) {
                AppManager.launch(root.execCommand)
            }
        }
    }
}
