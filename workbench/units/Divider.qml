import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""

    implicitWidth: Style.controlWidth
    implicitHeight: column.implicitHeight
    color: Style.background

    Column {
        id: column
        anchors.centerIn: parent
        width: Style.controlWidth
        spacing: Style.space3

        Prose {
            width: parent.width
            text: "Displays"
        }
        Divider {
            id: rule
            width: parent.width
            inset: Style.space3
        }
        Prose {
            width: parent.width
            text: "Inputs"
        }
    }

    readonly property var controls: []
    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            // The record says the implicit height IS the thickness, so the
            // observable reads that rather than the property it came from.
            "rule-height": () => rule.implicitHeight,
            "line-inset": () => rule.inset,
            "line-span": () => rule.width - rule.inset * 2
        }
    })
}
