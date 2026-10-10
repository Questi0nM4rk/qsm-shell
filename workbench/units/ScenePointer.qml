import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Item {
    id: root

    property string variant: ""
    property bool injectedMode: false

    QtObject {
        id: injectedSource
        property bool inside: true
        property point position: Qt.point(root.width / 2, root.height / 2)
    }

    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth

    ScenePointer {
        id: pointer
        source: root.injectedMode ? injectedSource : null
    }

    Card {
        anchors.centerIn: parent
        width: Style.controlWidth / 2
        height: body.implicitHeight + Style.space4 * 2

        Prose {
            id: body
            anchors.fill: parent
            anchors.margins: Style.space4
            role: "body"
            text: "Pointer inside the scene"
        }

        StateLayer {
            anchors.fill: parent
        }
    }

    readonly property var controls: [
        { label: "source", options: [
            { label: "native", set: { injectedMode: false } },
            { label: "injected", set: { injectedMode: true } }
        ] }
    ]

    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            "injected-source": () => pointer.source === injectedSource,
            inside: () => pointer.inside,
            position: () => pointer.position,
            rectangle: () => pointer.contains(Qt.rect(0, 0, root.width, root.height))
        }
    })
}
