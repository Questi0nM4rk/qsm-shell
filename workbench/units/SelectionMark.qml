import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

// The task: say which of a list's rows is current. The host owns `current`
// and each row positions its own mark, as a notification list does; moving
// `current` is what shows the arrival and the departure.
Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property int current: 1
    property bool strong: false

    readonly property var rows: ["Calendar reminder", "Download finished", "Battery low"]

    color: Style.band
    implicitWidth: Style.controlWidth
    implicitHeight: column.implicitHeight + Style.space4 * 2

    Column {
        id: column
        anchors.centerIn: parent
        spacing: Style.space2

        Repeater {
            id: repeater
            model: root.rows

            Item {
                id: row
                required property string modelData
                required property int index
                property alias mark: mark

                width: Style.controlWidth - Style.space4 * 2
                height: Style.size("Control", "lg")

                SelectionMark {
                    id: mark
                    anchors.left: parent.left
                    anchors.leftMargin: Style.space1
                    anchors.verticalCenter: parent.verticalCenter
                    shown: root.current === row.index
                    strong: root.strong
                }

                Prose {
                    anchors.left: parent.left
                    anchors.leftMargin: Style.space4
                    anchors.verticalCenter: parent.verticalCenter
                    role: "label"
                    text: row.modelData
                }
            }
        }
    }

    function _mark(index: int): var {
        return repeater.itemAt(index)?.mark
    }

    readonly property var controls: [
        { label: "current", options: [
            { label: "none", set: { current: -1 } },
            { label: "first", set: { current: 0 } },
            { label: "second", set: { current: 1 } },
            { label: "third", set: { current: 2 } }
        ] },
        { label: "emphasis", options: [
            { label: "normal", set: { strong: false } },
            { label: "strong", set: { strong: true } }
        ] }
    ]

    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            current: () => root.current,
            strong: () => root.strong,
            // The settled facts a flow can wait for: a mark is its full
            // height once it has arrived and zero once it has left.
            "first-height": () => root._mark(0)?.height ?? -1,
            "second-height": () => root._mark(1)?.height ?? -1,
            "third-height": () => root._mark(2)?.height ?? -1,
            "strong-wider": () => {
                const m = root._mark(Math.max(root.current, 0))
                return !!m && m.width > Style.stroke(Style.markThickness, m)
            }
        }
    })
}
