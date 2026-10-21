import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property string fullName: "Kai Mercer"
    property string glyph: ""
    property string presence: variant === "online" ? "success" : ""
    property bool ringed: false
    property real fraction: 0.5
    property real box: Style.size("Control", "md")
    property url photo: ""

    // No picture ships with the library, so the sample is drawn from the
    // theme: an off-centre light on a dusk ground, lopsided so the crop and the
    // mask both show.
    readonly property url samplePhoto: "data:image/svg+xml;utf8,"
        + "<svg xmlns='http://www.w3.org/2000/svg' width='128' height='96' viewBox='0 0 128 96'>"
        + "<defs><radialGradient id='g' cx='0.3' cy='0.35' r='0.8'>"
        + "<stop offset='0' stop-color='" + Style.accent + "'/>"
        + "<stop offset='1' stop-color='" + Style.band + "'/></radialGradient></defs>"
        + "<rect width='128' height='96' fill='url(%23g)'/></svg>"

    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth
    color: Style.band

    Avatar {
        id: mark
        anchors.centerIn: parent
        name: root.fullName
        source: root.photo
        icon: root.glyph
        size: root.box
        status: root.presence
        progress: root.ringed ? root.fraction : -1
    }

    readonly property var controls: [
        { label: "identity", options: [
            { label: "initials", set: { fullName: "Kai Mercer", glyph: "", photo: "" } },
            { label: "one-word", set: { fullName: "Mercer", glyph: "", photo: "" } },
            { label: "icon", set: { fullName: "", glyph: "music", photo: "" } },
            { label: "photo", set: { fullName: "Kai Mercer", glyph: "", photo: root.samplePhoto } },
            { label: "blank", set: { fullName: "", glyph: "", photo: "" } }
        ] },
        { label: "presence", options: [
            { label: "none", set: { presence: "" } },
            { label: "online", set: { presence: "success" } },
            { label: "away", set: { presence: "warning" } }
        ] },
        { label: "ring", options: [
            { label: "none", set: { ringed: false } },
            { label: "half", set: { ringed: true, fraction: 0.5 } },
            { label: "full", set: { ringed: true, fraction: 1 } }
        ] },
        { label: "size", options: [
            { label: "md", set: { box: Style.size("Control", "md") } },
            { label: "lg", set: { box: Style.size("Control", "lg") } }
        ] }
    ]
    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            initials: () => mark.initials,
            presence: () => mark.status,
            progress: () => mark.progress
        }
    })
}
