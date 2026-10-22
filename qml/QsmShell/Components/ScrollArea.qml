import QtQuick
import QtQuick.Templates as T

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
// is what sizes the content. An indicator inside would have its height feed
// the content height feed its own height — a binding loop, invisible to
// `qmllint`.
Item {
    id: root

    // The scrolled content. `contentData` is not aliasable, and a named host
    // is where the content size comes from anyway.
    default property alias content: host.data

    property int orientation: Qt.Vertical
    // The chrome is `ScrollCue`'s: its properties, and its defaults, are
    // read through.
    property alias fade: cue.fade
    property alias fadeColor: cue.fadeColor
    property alias indicator: cue.indicator
    property alias fadeDepth: cue.fadeDepth

    // The viewport, for a consumer that needs to drive the position itself
    // (scroll a selection into view, jump to the top on a new query).
    readonly property alias viewport: scroller
    readonly property alias overflows: cue.overflows
    // How deep the fade paints at each end, in px.
    readonly property alias startFade: cue.startFade
    readonly property alias endFade: cue.endFade
    // Keyboard focus on the region itself, which is what its ring shows.
    readonly property bool focused: focusHost.visualFocus

    readonly property bool vertical: orientation === Qt.Vertical

    // A natural size that is a constant: a few rows. Content longer than it
    // scrolls, it never grows the area.
    implicitWidth: Style.controlWidth
    implicitHeight: root._line * 3

    // What one arrow key or one wheel notch moves: a row.
    readonly property real _line: Style.size("Control", "md")

    // Far edge of the content, not its size: content whose first child starts
    // inset from the origin ends at `origin + size`, and scrolling to the size
    // alone would leave that inset's worth of the last row out of reach.
    readonly property real _extentX: host.childrenRect.x + host.childrenRect.width
    readonly property real _extentY: host.childrenRect.y + host.childrenRect.height

    // Every route moves the view through these three, clamped to the content,
    // so content that fits stays put. Writing contentY directly with
    // `contentHeight - height` goes negative for it.
    function scrollBy(delta: real): void {
        if (vertical)
            scroller.contentY = Math.max(0, Math.min(scroller.contentHeight - scroller.height, scroller.contentY + delta));
        else
            scroller.contentX = Math.max(0, Math.min(scroller.contentWidth - scroller.width, scroller.contentX + delta));
    }

    function scrollToStart(): void {
        scrollBy(-Infinity);
    }

    function scrollToEnd(): void {
        scrollBy(Infinity);
    }

    // Puts the keyboard on the region itself, ring and all.
    function focusRegion(): void {
        focusHost.forceActiveFocus(Qt.TabFocusReason);
    }

    readonly property list<T.Action> actions: [
        T.Action { objectName: "to-start"; text: "Scroll to start"; onTriggered: root.scrollToStart() },
        T.Action { objectName: "to-end"; text: "Scroll to end"; onTriggered: root.scrollToEnd() }
    ]

    // ONE dispatcher. A descendant that handles a key keeps it; the rest reach
    // here from the focused child or from the region itself.
    Keys.onPressed: event => {
        const back = root.vertical ? Qt.Key_Up : Qt.Key_Left;
        const forward = root.vertical ? Qt.Key_Down : Qt.Key_Right;
        const page = (root.vertical ? scroller.height : scroller.width) - root._line;
        event.accepted = true;
        switch (event.key) {
        case back: root.scrollBy(-root._line); break;
        case forward: root.scrollBy(root._line); break;
        case Qt.Key_PageUp: root.scrollBy(-page); break;
        case Qt.Key_PageDown: root.scrollBy(page); break;
        case Qt.Key_Home: root.scrollToStart(); break;
        case Qt.Key_End: root.scrollToEnd(); break;
        default: event.accepted = false;
        }
    }

    // The region is a tab stop only while there is something to scroll to,
    // and only for the keyboard: a click on content is not a request to focus
    // a scroller.
    T.Control {
        id: focusHost
        anchors.fill: parent
        focusPolicy: root.overflows ? Qt.TabFocus : Qt.NoFocus
        Accessible.role: Accessible.Pane
        Accessible.focusable: root.overflows

        StateLayer {
            anchors.fill: parent
            host: focusHost
            focusRadius: Style.radiusSm
        }
    }

    Flickable {
        id: scroller

        anchors.fill: parent
        clip: true
        flickableDirection: root.vertical ? Flickable.VerticalFlick : Flickable.HorizontalFlick
        contentWidth: root.vertical ? width : root._extentX
        contentHeight: root.vertical ? root._extentY : height
        boundsBehavior: Flickable.StopAtBounds

        Item {
            id: host
            // The free axis matches the viewport, so content that fills the
            // width does not have to be told how wide the viewport is.
            width: root.vertical ? scroller.width : root._extentX
            height: root.vertical ? root._extentY : scroller.height
        }
    }

    // A Flickable ignores a vertical wheel when it only scrolls sideways, and
    // that is the only wheel most mice have. A MouseArea takes the wheel where
    // a WheelHandler never sees it; an event it does not map goes on to the
    // Flickable.
    MouseArea {
        anchors.fill: parent
        enabled: !root.vertical
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            if (wheel.angleDelta.x === 0 && wheel.angleDelta.y !== 0)
                root.scrollBy(-wheel.angleDelta.y / 120 * root._line);
            else
                wheel.accepted = false;
        }
    }

    ScrollCue {
        id: cue
        view: scroller
        orientation: root.orientation
    }
}
