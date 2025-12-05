import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CanvasDesk

Rectangle {
    id: root
    
    // Configurable properties
    property color backgroundColor: Theme.uiSecondaryColor
    property color activeColor: Theme.uiPrimaryColor
    property color inactiveColor: Theme.uiTertiaryColor
    
    // Editor support
    property bool editorOpen: false
    
    color: backgroundColor
    border.color: Theme.uiTitleBarLeftColor
    border.width: 1
    radius: 4
    
    ListView {
        anchors.fill: parent
        anchors.margins: 2
        orientation: ListView.Horizontal
        spacing: 4
        model: WindowManager.windows
        
        delegate: Item {
            width: 120
            height: parent.height

            Rectangle {
                id: buttonBackground
                anchors.fill: parent
                color: modelData.active ? root.activeColor : root.inactiveColor
                border.color: mouseArea.pressed ? Theme.uiHighlightColor : Theme.uiTitleBarRightColor
                radius: 2
                opacity: modelData.state === "minimized" ? 0.5 : 1.0
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4
                
                Image {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    source: "image://theme/" + (modelData.appId || "application-x-executable")
                    sourceSize.width: 16
                    sourceSize.height: 16
                    fillMode: Image.PreserveAspectFit
                    visible: modelData.state !== "minimized" // Hide icon if minimized to save space? Or keep it? Let's keep it.
                }

                Text {
                    Layout.fillWidth: true
                    text: {
                        let prefix = "";
                        if (modelData.state === "minimized") prefix = "_ ";
                        else if (modelData.state === "maximized") prefix = "□ ";
                        return prefix + modelData.title;
                    }
                    color: Theme.uiTextColor
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    font.italic: modelData.state === "minimized"
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                enabled: !root.editorOpen
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                onClicked: (mouse) => {
                    if (mouse.button === Qt.MiddleButton) {
                        // Middle click: close window
                        WindowManager.close(modelData.id);
                    } else if (mouse.button === Qt.LeftButton) {
                        // Left click: toggle minimize/restore
                        if (modelData.state === "minimized") {
                            WindowManager.activate(modelData.id);
                        } else {
                            WindowManager.minimize(modelData.id);
                        }
                    }
                }
            }
        }

        // Empty state
        Text {
            visible: parent.count === 0
            anchors.centerIn: parent
            text: "(no windows)"
            color: Theme.uiTextColor
            font.pixelSize: 12
        }
    }
}
