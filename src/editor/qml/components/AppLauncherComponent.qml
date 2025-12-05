import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CanvasDesk
import ".."  // For PopupPositionHelper

Rectangle {
    id: root

    // Configurable properties
    property color buttonColor: Theme.uiPrimaryColor
    property color popupColor: Theme.uiSecondaryColor
    property string buttonText: "Apps"
    property int viewMode: 0

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
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 2
            spacing: 0
            
            // Toolbar
            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: "transparent"
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4
                    
                    Text {
                        text: "Apps"
                        font.bold: true
                        color: Theme.uiTextColor
                        Layout.fillWidth: true
                    }
                    
                    // View Switcher Buttons
                    Repeater {
                        model: [
                            { icon: "view-grid", mode: 0, tooltip: "Large Grid" },
                            { icon: "view-list-icons", mode: 1, tooltip: "Small Grid" },
                            { icon: "view-list-details", mode: 2, tooltip: "List" },
                            { icon: "view-list-text", mode: 3, tooltip: "Flow" }
                        ]
                        
                        delegate: Button {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            checkable: true
                            checked: root.viewMode === modelData.mode
                            onClicked: root.viewMode = modelData.mode
                            
                            background: Rectangle {
                                color: parent.checked ? Theme.uiHighlightColor : "transparent"
                                radius: 4
                                border.color: parent.hovered ? Theme.uiHighlightColor : "transparent"
                            }
                            
                            contentItem: Image {
                                source: "image://theme/" + modelData.icon
                                fillMode: Image.PreserveAspectFit
                                anchors.centerIn: parent
                                width: 20
                                height: 20
                            }
                            
                            ToolTip.visible: hovered
                            ToolTip.text: modelData.tooltip
                            ToolTip.delay: 500
                        }
                    }
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.uiTitleBarLeftColor
            }
            
            // Content Area
            StackLayout {
                currentIndex: root.viewMode
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                // 0: Large Grid
                GridView {
                    clip: true
                    cellWidth: 100
                    cellHeight: 110
                    model: AppManager.apps
                    delegate: Item {
                        width: 100
                        height: 110
                        
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            color: parent.hovered ? Theme.uiHighlightColor : "transparent"
                            radius: 4
                            property bool hovered: false
                            
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
                            
                            Column {
                                anchors.centerIn: parent
                                spacing: 8
                                
                                Image {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    source: "image://theme/" + (modelData.icon || "application-x-executable")
                                    sourceSize.width: 64
                                    sourceSize.height: 64
                                    width: 64
                                    height: 64
                                    fillMode: Image.PreserveAspectFit
                                }
                                
                                Text {
                                    text: modelData.name
                                    width: 90
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: 11
                                    color: Theme.uiTextColor
                                }
                            }
                        }
                    }
                }
                
                // 1: Small Grid
                GridView {
                    clip: true
                    cellWidth: 70
                    cellHeight: 80
                    model: AppManager.apps
                    delegate: Item {
                        width: 70
                        height: 80
                        
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            color: parent.hovered ? Theme.uiHighlightColor : "transparent"
                            radius: 4
                            property bool hovered: false
                            
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
                            
                            Column {
                                anchors.centerIn: parent
                                spacing: 4
                                
                                Image {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    source: "image://theme/" + (modelData.icon || "application-x-executable")
                                    sourceSize.width: 32
                                    sourceSize.height: 32
                                    width: 32
                                    height: 32
                                    fillMode: Image.PreserveAspectFit
                                }
                                
                                Text {
                                    text: modelData.name
                                    width: 66
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: 10
                                    color: Theme.uiTextColor
                                }
                            }
                        }
                    }
                }
                
                // 2: List View
                ListView {
                    clip: true
                    model: AppManager.apps
                    spacing: 2
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 36
                        color: hovered ? Theme.uiHighlightColor : "transparent"
                        radius: 4
                        property bool hovered: false
                        
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
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 10
                            
                            Image {
                                source: "image://theme/" + (modelData.icon || "application-x-executable")
                                sourceSize.width: 24
                                sourceSize.height: 24
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                fillMode: Image.PreserveAspectFit
                            }
                            
                            Text {
                                text: modelData.name
                                color: Theme.uiTextColor
                                font.pixelSize: 12
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
                
                // 3: Flow View (Optimized)
                ScrollView {
                    clip: true
                    
                    Flow {
                        width: parent.width
                        spacing: 8
                        
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
