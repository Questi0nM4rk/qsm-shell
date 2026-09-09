import QtQuick

// Live counterpart to CapturePreview.qml: the same Preview host, no grab or
// quit, run on the wayland platform. One window shows every scene it is
// given side by side, so a TYPE is judged in one place. Args land after "--"
// in Qt.application.arguments in groups of five: component, variant, width,
// height, unit.
Item {
    id: root

    readonly property var scenes: {
        const args = Qt.application.arguments;
        const separator = args.indexOf("--");
        const list = [];
        if (separator < 0)
            return [{ component: "capsule", variant: "resting", width: 1600, height: 900, unit: "" }];
        for (let i = separator + 1; i + 4 < args.length; i += 5) {
            list.push({
                component: args[i],
                variant: args[i + 1],
                width: parseInt(args[i + 2]),
                height: parseInt(args[i + 3]),
                unit: args[i + 4]
            });
        }
        return list;
    }

    width: root.scenes.reduce((sum, scene) => sum + scene.width, 0)
    height: root.scenes.reduce((max, scene) => Math.max(max, scene.height), 0)

    Rectangle {
        anchors.fill: parent
        color: "#1c0e27"
    }

    Row {
        Repeater {
            model: root.scenes
            Preview {
                required property var modelData
                component: modelData.component
                unit: modelData.unit
                variant: modelData.variant
                viewportWidth: modelData.width
                viewportHeight: modelData.height
                interactive: true
            }
        }
    }
}
