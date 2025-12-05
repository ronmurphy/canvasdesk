import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CanvasDesk

Window {
    id: controlCenter
    width: 900
    height: 650
    minimumWidth: 800
    minimumHeight: 600
    title: "CanvasDesk Control Center"
    color: Theme.uiBackgroundColor

    flags: Qt.Window | Qt.WindowCloseButtonHint | Qt.WindowMinimizeButtonHint

    // Tab bar
    Rectangle {
        id: tabBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 50
        color: Theme.uiSecondaryColor

        Row {
            anchors.fill: parent
            anchors.margins: 5
            spacing: 5

            Repeater {
                model: ["Monitors", "Appearance", "System"]

                Button {
                    width: 120
                    height: 40
                    text: modelData

                    background: Rectangle {
                        color: tabView.currentIndex === index ? Theme.uiPrimaryColor : Theme.uiTertiaryColor
                        border.color: Theme.uiHighlightColor
                        border.width: tabView.currentIndex === index ? 2 : 0
                        radius: 4
                    }

                    contentItem: Text {
                        text: parent.text
                        color: Theme.uiTextColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 14
                        font.bold: tabView.currentIndex === index
                    }

                    onClicked: tabView.currentIndex = index
                }
            }
        }
    }

    // Content area
    StackLayout {
        id: tabView
        anchors.top: tabBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10

        currentIndex: 0

        // Monitors Tab
        Rectangle {
            color: Theme.uiBackgroundColor

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                Text {
                    text: "Monitor Configuration"
                    font.pixelSize: 20
                    font.bold: true
                    color: Theme.uiTextColor
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.uiSecondaryColor
                    border.color: Theme.uiHighlightColor
                    border.width: 1
                    radius: 4

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 10

                        ColumnLayout {
                            width: parent.width
                            spacing: 15

                            Repeater {
                                model: WindowManager.monitorManager ? WindowManager.monitorManager.monitors() : []

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 200
                                    color: Theme.uiTertiaryColor
                                    border.color: modelData.primary ? Theme.uiHighlightColor : Theme.uiPrimaryColor
                                    border.width: modelData.primary ? 3 : 1
                                    radius: 6

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 15
                                        spacing: 10

                                        RowLayout {
                                            Layout.fillWidth: true

                                            Text {
                                                text: modelData.name
                                                font.pixelSize: 18
                                                font.bold: true
                                                color: Theme.uiTextColor
                                                Layout.fillWidth: true
                                            }

                                            Rectangle {
                                                visible: modelData.primary
                                                width: 80
                                                height: 25
                                                color: Theme.uiHighlightColor
                                                radius: 3

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "PRIMARY"
                                                    color: Theme.uiTextColor
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                }
                                            }
                                        }

                                        Grid {
                                            columns: 2
                                            rowSpacing: 8
                                            columnSpacing: 20

                                            Text {
                                                text: "Resolution:"
                                                color: Theme.uiTextColor
                                                font.pixelSize: 13
                                            }
                                            Text {
                                                text: modelData.width + " × " + modelData.height
                                                color: Theme.uiTextColor
                                                font.pixelSize: 13
                                                font.bold: true
                                            }

                                            Text {
                                                text: "Position:"
                                                color: Theme.uiTextColor
                                                font.pixelSize: 13
                                            }
                                            Text {
                                                text: "X: " + modelData.x + ", Y: " + modelData.y
                                                color: Theme.uiTextColor
                                                font.pixelSize: 13
                                                font.bold: true
                                            }

                                            Text {
                                                text: "Rotation:"
                                                color: Theme.uiTextColor
                                                font.pixelSize: 13
                                            }
                                            Text {
                                                text: modelData.rotation + "°"
                                                color: Theme.uiTextColor
                                                font.pixelSize: 13
                                                font.bold: true
                                            }

                                            Text {
                                                text: "Status:"
                                                color: Theme.uiTextColor
                                                font.pixelSize: 13
                                            }
                                            Text {
                                                text: modelData.enabled ? "Enabled" : "Disabled"
                                                color: modelData.enabled ? "#4CAF50" : "#F44336"
                                                font.pixelSize: 13
                                                font.bold: true
                                            }
                                        }

                                        Item { Layout.fillHeight: true }

                                        Text {
                                            text: "Visual monitor layout editor coming soon..."
                                            color: Theme.uiTextColor
                                            font.pixelSize: 12
                                            font.italic: true
                                            opacity: 0.7
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                            }
                        }
                    }
                }

                // Bottom buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Item { Layout.fillWidth: true }

                    Button {
                        text: "Refresh"
                        onClicked: {
                            if (WindowManager.monitorManager) {
                                WindowManager.monitorManager.updateMonitors()
                            }
                        }

                        background: Rectangle {
                            color: parent.down ? Theme.uiHighlightColor : Theme.uiPrimaryColor
                            border.color: Theme.uiHighlightColor
                            border.width: 1
                            radius: 4
                        }

                        contentItem: Text {
                            text: parent.text
                            color: Theme.uiTextColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Button {
                        text: "Close"
                        onClicked: controlCenter.close()

                        background: Rectangle {
                            color: parent.down ? Theme.uiHighlightColor : Theme.uiPrimaryColor
                            border.color: Theme.uiHighlightColor
                            border.width: 1
                            radius: 4
                        }

                        contentItem: Text {
                            text: parent.text
                            color: Theme.uiTextColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }

        // Appearance Tab (placeholder)
        Rectangle {
            color: Theme.uiBackgroundColor

            Text {
                anchors.centerIn: parent
                text: "Appearance settings will be moved here\nfrom the Editor Settings tab"
                color: Theme.uiTextColor
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // System Tab (placeholder)
        Rectangle {
            color: Theme.uiBackgroundColor

            Text {
                anchors.centerIn: parent
                text: "System settings\n(Keyboard, Mouse, Icons, Cursors, etc.)\nComing soon..."
                color: Theme.uiTextColor
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
