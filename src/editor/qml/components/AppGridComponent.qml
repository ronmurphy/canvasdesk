import QtQuick
import QtQuick.Controls
import CanvasDesk

Rectangle {
    id: root
    
    // Component can be configured via these properties
    property color backgroundColor: "#1a1a1a"
    property color borderColor: "#444"
    property int cellWidth: 80
    property int cellHeight: 80
    
    // Editor support
    property bool editorOpen: false
    
    color: backgroundColor
    border.color: borderColor
    border.width: 1
    radius: 4
    
    GridView {
        anchors.fill: parent
        anchors.margins: 8
        cellWidth: root.cellWidth
        cellHeight: root.cellHeight
        clip: true
        model: AppManager.apps
        
        delegate: Item {
            width: root.cellWidth
            height: root.cellHeight
            
            Column {
                anchors.centerIn: parent
                spacing: 5
                
                Rectangle {
                    width: 48
                    height: 48
                    color: "transparent"
                    
                    Image {
                        anchors.fill: parent
                        source: "image://theme/" + (modelData.icon || "application-x-executable")
                        sourceSize.width: 48
                        sourceSize.height: 48
                        fillMode: Image.PreserveAspectFit
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.editorOpen
                        onClicked: AppManager.launch(modelData.exec)
                    }
                }
                
                Text {
                    text: modelData.name
                    width: 70
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 10
                    color: "white"
                }
            }
        }
    }
}
