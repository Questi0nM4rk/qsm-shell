import QtQuick

import qs.QsmShell.Style

// Static content that is taller (or wider) than the room it has.
//
// It is a plain viewport plus `ScrollCue`. Content that comes from a MODEL
// wants a `ListView`, which is itself the Flickable and cannot be put inside
// one — that case attaches `ScrollCue` to the list directly.
//
// WHY the chrome is a sibling of the viewport and the content is in a named
// host: a Flickable's declared children become children of its `contentItem`,
// which means they SCROLL, and worse, they count toward `childrenRect`, which
// is what sizes the content. The first version put the indicator inside, so
// the indicator's height fed the content height fed the indicator's height —
// a binding loop, invisible to `qmllint` and caught the first time anything
// ran it.
Item {
    id: root

    // The scrolled content. `contentData` is not aliasable, and a named host
    // is where the content size comes from anyway.
    default property alias content: host.data

    property int orientation: Qt.Vertical
    property bool fade: true
    property color fadeColor: Style.surface
    property bool indicator: true
    property real fadeDepth: Style.space6 * 2

    // The viewport, for a consumer that needs to drive the position itself
    // (scroll a selection into view, jump to the top on a new query).
    readonly property alias viewport: view
    readonly property alias overflows: cue.overflows

    readonly property bool vertical: orientation === Qt.Vertical

    Flickable {
        id: view

        anchors.fill: parent
        clip: true
        flickableDirection: root.vertical ? Flickable.VerticalFlick : Flickable.HorizontalFlick
        contentWidth: root.vertical ? width : host.childrenRect.width
        contentHeight: root.vertical ? host.childrenRect.height : height
        boundsBehavior: Flickable.StopAtBounds

        Item {
            id: host
            // The free axis matches the viewport, so content that fills the
            // width does not have to be told how wide the viewport is.
            width: root.vertical ? view.width : childrenRect.width
            height: root.vertical ? childrenRect.height : view.height
        }
    }

    ScrollCue {
        id: cue
        view: view
        orientation: root.orientation
        fade: root.fade
        fadeColor: root.fadeColor
        indicator: root.indicator
        fadeDepth: root.fadeDepth
    }
}
