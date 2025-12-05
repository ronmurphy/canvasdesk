import QtQuick
import QtQuick.Controls
import CanvasDesk
import ".."  // For PopupPositionHelper

Rectangle {
    id: root

    // Configurable properties
    property color buttonColor: Theme.uiPrimaryColor
    property color popupColor: Theme.uiSecondaryColor
    property string buttonText: "Apps"

    // Editor support
    property bool editorOpen: false

    // Internal state
    property bool showPopup: false

    // Smart positioning helper
    PopupPositionHelper {
        id: positionHelper
        sourceItem: root
        popupWidth: 400
        popupHeight: 500
        margin: 8
    }

    color: "transparent"
    
    // Launcher button
    Button {
        anchors.fill: parent
        anchors.margins: 4
        text: root.buttonText
        
        background: Rectangle {
            color: parent.down ? Qt.darker(root.buttonColor, 1.2) : root.buttonColor
            border.color: Theme.uiTitleBarLeftColor
            radius: 4
        }
        
        contentItem: Text {
            text: parent.text
            color: Theme.uiTextColor
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        
        enabled: !root.editorOpen
        onClicked: root.showPopup = !root.showPopup
    }
    
    // App grid popup (parented to desktop to escape panel clipping)
    Rectangle {
        id: popup
        visible: showPopup
        parent: positionHelper.getDesktopParent(root)
        width: positionHelper.popupWidth
        height: positionHelper.popupHeight
        color: popupColor
        border.color: Theme.uiHighlightColor
        border.width: 2
        radius: 6
        z: 2000  // Very high z to be above everything

        // Use smart positioning from helper
        x: positionHelper.x
        y: positionHelper.y

        // Recalculate position when shown
        onVisibleChanged: {
            if (visible) {
                positionHelper.calculatePosition()
            }
        }
        
        ScrollView {
            anchors.fill: parent
            anchors.margins: 12
            clip: true
            
            Flow {
                width: parent.width
                spacing: 10
                
                Repeater {
                    model: AppManager.apps
                    
                    delegate: Rectangle {
                        width: 80
                        height: 90
                        color: "transparent"
                        radius: 4
                        
                        // Hover effect
                        property bool hovered: false
                        
                        Rectangle {
                            anchors.fill: parent
                            color: Theme.uiHighlightColor
                            opacity: parent.hovered ? 0.3 : 0.0
                            radius: 4
                        }
                        
                        Column {
                            anchors.centerIn: parent
                            spacing: 5
                            
                            Image {
                                anchors.horizontalCenter: parent.horizontalCenter
                                source: "image://theme/" + (modelData.icon || "application-x-executable")
                                sourceSize.width: 48
                                sourceSize.height: 48
                                width: 48
                                height: 48
                                fillMode: Image.PreserveAspectFit
                            }
                            
                            Text {
                                text: modelData.name
                                width: 76
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: 10
                                color: Theme.uiTextColor
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: parent.hovered = true
                            onExited: parent.hovered = false
                            onClicked: {
                                AppManager.launch(modelData.exec)
                                root.showPopup = false
                            }
                        }
                    }
                }
            }
        }
        
        // Close button
        Button {
            text: "×"
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 4
            width: 30
            height: 30
            onClicked: root.showPopup = false
        }
    }
    
    // Click outside to close - parented to desktop
    MouseArea {
        visible: showPopup
        parent: popup.parent  // Same parent as popup (desktop)
        anchors.fill: parent
        z: 1999  // Just below popup
        onClicked: root.showPopup = false
    }
}
