import QtQuick

// Live counterpart to CapturePreview.qml: the same Preview host, no grab or
// quit, run on the wayland platform. ONE window, ONE unit, opened in its
// default scene -- switching between the unit's other scenario keys happens
// inside the window, through the "scene" control group Preview builds from
// `scenes`, never by relaunching. Args land after "--" in
// Qt.application.arguments: initialKey, then a JSON array of every sibling
// scenario in scenarios.json order (`{key, component, variant, viewport,
// unit}`).
//
// A `Window`, not an `Item`: the compositor tiles the window to whatever
// size it likes and the root has to FOLLOW it, or the Preview keeps the
// scene's own size, the pane clips it, and the Flickable inside believes
// everything fits (measured: no scroll on a half-height tile). The viewport
// is the window's opening size only.
Window {
    id: root
    visible: true
    title: `qsm-shell · ${root.initial.unit || root.initial.component}`
    color: "#1c0e27"

    readonly property var args: {
        const all = Qt.application.arguments;
        const separator = all.indexOf("--");
        return separator < 0 ? [] : all.slice(separator + 1);
    }
    readonly property string initialKey: root.args[0] ?? ""
    readonly property var scenes: root.args[1] ? JSON.parse(root.args[1]) : [{ key: "capsule", component: "capsule", variant: "resting", viewport: [1600, 900], unit: "" }]
    readonly property var initial: root.scenes.find(scene => scene.key === root.initialKey) ?? root.scenes[0]

    width: root.initial.viewport[0]
    height: root.initial.viewport[1]

    Preview {
        anchors.fill: parent
        component: root.initial.component
        unit: root.initial.unit
        variant: root.initial.variant
        scenes: root.scenes
        viewportWidth: root.initial.viewport[0]
        viewportHeight: root.initial.viewport[1]
        interactive: true
    }
}
