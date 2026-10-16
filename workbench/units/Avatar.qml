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
    property real box: Style.controlHeight

    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth
    color: Style.band

    Avatar {
        id: mark
        anchors.centerIn: parent
        name: root.fullName
        icon: root.glyph
        size: root.box
        status: root.presence
        progress: root.ringed ? root.fraction : -1
    }

    readonly property var controls: [
        { label: "identity", options: [
            { label: "initials", set: { fullName: "Kai Mercer", glyph: "" } },
            { label: "one-word", set: { fullName: "Mercer", glyph: "" } },
            { label: "icon", set: { fullName: "", glyph: "music" } }
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
            { label: "md", set: { box: Style.controlHeight } },
            { label: "lg", set: { box: Style.controlHeightLg } }
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
