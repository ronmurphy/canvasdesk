import QtQuick
import QtQuick.Controls
import CanvasDesk

ApplicationWindow {
    visible: true
    width: 800
    height: 600
    title: "CanvasDesk Runtime"

    LayoutManager {
        id: layoutManager
    }

    Item {
        id: container
        anchors.fill: parent
    }

    Component.onCompleted: {
        var json = layoutManager.loadLayout("layout.json")
        if (json) {
            console.log("Loaded layout in runtime")
            try {
                var data = JSON.parse(json)
                if (data.components) {
                    for (var i = 0; i < data.components.length; ++i) {
                        var comp = data.components[i]
                        createObject(comp)
                    }
                }
            } catch (e) {
                console.log("Error parsing layout: " + e)
            }
        } else {
            console.log("No layout found")
        }
    }

    function createObject(data) {
        if (data.type === "Button") {
            var qml = 'import QtQuick; import QtQuick.Controls; import CanvasDesk; Button { text: "' + data.text + '"; icon.name: "' + (data.icon || "") + '"; x: ' + data.x + '; y: ' + data.y + '; onClicked: AppManager.launch("' + data.exec + '") }'
            Qt.createQmlObject(qml, container, "dynamicComponent")
        } else if (data.type === "Taskbar") {
            var qml = 'import QtQuick; import QtQuick.Controls; import QtQuick.Layouts; import CanvasDesk; ListView { orientation: ListView.Horizontal; width: 400; height: 40; x: ' + data.x + '; y: ' + data.y + '; model: WindowManager.windows; delegate: Button { text: modelData.title; icon.name: modelData.icon; highlighted: modelData.active; onClicked: WindowManager.activate(modelData.id) } }'
            Qt.createQmlObject(qml, container, "dynamicComponent")
        } else if (data.type === "AppGrid") {
            var qml = 'import QtQuick; import QtQuick.Controls; import CanvasDesk; GridView { width: 300; height: 400; cellWidth: 80; cellHeight: 80; x: ' + data.x + '; y: ' + data.y + '; model: AppManager.apps; delegate: Item { width: 80; height: 80; Column { anchors.centerIn: parent; spacing: 5; ToolButton { icon.name: modelData.icon || "application-x-executable"; icon.width: 48; icon.height: 48; onClicked: AppManager.launch(modelData.exec) } Text { text: modelData.name; width: 70; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 10 } } } }'
            Qt.createQmlObject(qml, container, "dynamicComponent")
        } else if (data.type === "FileManager") {
            var qml = 'import QtQuick; import QtQuick.Controls; import Qt.labs.folderlistmodel; import CanvasDesk; ListView { width: 200; height: 300; x: ' + data.x + '; y: ' + data.y + '; model: FolderListModel { folder: "file://" + AppManager.homeDir(); showDirsFirst: true; nameFilters: ["*"] }; delegate: ItemDelegate { text: fileName; icon.name: fileIsDir ? "folder" : "text-x-generic"; width: parent.width } }'
            Qt.createQmlObject(qml, container, "dynamicComponent")
        } else {
            // Fallback for other types
            var qml = 'import QtQuick; Rectangle { color: "#ddeeff"; border.color: "blue"; width: 100; height: 50; x: ' + data.x + '; y: ' + data.y + '; Text { anchors.centerIn: parent; text: "' + data.type + '" } }'
            Qt.createQmlObject(qml, container, "dynamicComponent")
        }
    }
}
