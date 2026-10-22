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
        id: card
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
    }

    readonly property rect cardArea: Qt.rect(card.x, card.y, card.width, card.height)
    // The card's top-left half: a right triangle on its diagonal.
    readonly property var cardCorner: pointer.triangleArea(
        Qt.point(card.x, card.y), Qt.point(card.x + card.width, card.y), Qt.point(card.x, card.y + card.height))

    readonly property var controls: [
        { label: "source", options: [
            { label: "native", set: { injectedMode: false } },
            { label: "injected", set: { injectedMode: true } }
        ] }
    ]

    readonly property var integration: ({
        events: [],
        actions: [],
        targets: ({ scene: () => root, card: () => card }),
        observables: {
            "injected-source": () => pointer.source === injectedSource,
            inside: () => pointer.inside,
            position: () => pointer.position,
            rectangle: () => pointer.contains(Qt.rect(0, 0, root.width, root.height)),
            "over-card": () => pointer.contains(root.cardArea),
            "over-corner": () => pointer.contains(root.cardCorner)
        }
    })
}
