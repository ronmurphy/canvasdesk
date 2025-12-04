import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CanvasDesk

Rectangle {
    id: root
    
    // Configurable properties
    property color backgroundColor: Theme.secondaryColor
    property color activeColor: Theme.primaryColor
    property color inactiveColor: Theme.tertiaryColor
    
    // Editor support
    property bool editorOpen: false
    
    color: backgroundColor
    border.color: Theme.neutralColor
    border.width: 1
    radius: 4
    
    ListView {
        anchors.fill: parent
        anchors.margins: 2
        orientation: ListView.Horizontal
        spacing: 4
        model: WindowManager.windows
        
        delegate: Button {
            width: 120
            height: parent.height
            
            background: Rectangle {
                color: modelData.active ? root.activeColor : root.inactiveColor
                border.color: parent.down ? Theme.accentColor : Theme.neutralColor
                radius: 2
            }
            
            contentItem: Text {
                text: modelData.title
                color: Theme.brightestColor
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            enabled: !root.editorOpen
            onClicked: WindowManager.activate(modelData.id)
        }

        // Empty state
        Text {
            visible: parent.count === 0
            anchors.centerIn: parent
            text: "(no windows)"
            color: Theme.neutralColor
            font.pixelSize: 12
        }
    }
}
