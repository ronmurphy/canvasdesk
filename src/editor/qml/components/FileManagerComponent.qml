import QtQuick
import QtQuick.Controls
import Qt.labs.folderlistmodel
import CanvasDesk

Rectangle {
    id: root
    
    // Configurable properties
    property string currentPath: AppManager.homeDir()
    property color backgroundColor: "#1a1a1a"
    property color itemColor: "#2a2a2a"
    
    // Editor support
    property bool editorOpen: false
    
    color: backgroundColor
    border.color: "#444"
    border.width: 1
    radius: 4
    
    Column {
        anchors.fill: parent
        spacing: 0
        
        // Path bar
        Rectangle {
            width: parent.width
            height: 30
            color: "#2a2a2a"
            border.color: "#555"
            
            Row {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4
                
                Button {
                    text: "↑"
                    width: 30
                    height: 22
                    enabled: !root.editorOpen
                    onClicked: {
                        var parts = root.currentPath.split('/')
                        parts.pop()
                        root.currentPath = parts.join('/') || '/'
                    }
                }
                
                Text {
                    text: root.currentPath
                    color: "white"
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideMiddle
                    width: parent.width - 40
                }
            }
        }
        
        // File list
        ListView {
            width: parent.width
            height: parent.height - 30
            clip: true
            
            model: FolderListModel {
                folder: "file://" + root.currentPath
                showDirsFirst: true
                nameFilters: ["*"]
            }
            
            delegate: Rectangle {
                width: parent.width
                height: 28
                color: mouseArea.containsMouse ? "#3a3a3a" : "transparent"
                
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    spacing: 8
                    
                    Image {
                        source: "image://theme/" + (fileIsDir ? "folder" : "text-x-generic")
                        width: 20
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Text {
                        text: fileName
                        color: "white"
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        width: parent.width - 40
                    }
                }
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !root.editorOpen
                    
                    onDoubleClicked: {
                        if (fileIsDir) {
                            root.currentPath = filePath
                        } else {
                            // Open file with default app
                            AppManager.launch("xdg-open \"" + filePath + "\"")
                        }
                    }
                }
            }
        }
    }
}
