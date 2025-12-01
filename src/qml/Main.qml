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
        // Simple rendering for prototype
        var qml = 'import QtQuick; Rectangle { color: "#ddeeff"; border.color: "blue"; width: 100; height: 50; x: ' + data.x + '; y: ' + data.y + '; Text { anchors.centerIn: parent; text: "' + data.type + '" } }'
        Qt.createQmlObject(qml, container, "dynamicComponent")
    }
}
