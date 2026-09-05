import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// THE row. One line in a list of things a person picks from.
//
// It replaced three types that were one type: `MenuRowItem` (a menu's row),
// `PopoutRow` (a device list's row), `ResultRow` (a launcher's row). Put side
// by side they had the same anatomy — a mark, one leading visual, a name, a
// supporting line, some trailing content — and they differed in a handful of
// numbers and in which of the three had remembered which rule. Two of them
// were named after the SURFACE they were written for, which is the tell: a
// library that grows a type per call site has stopped being a library.
//
// ── the leading box ──────────────────────────────────────────────────────
// Whatever sits at the leading edge — a glyph, an application icon, a
// wallpaper thumbnail — occupies a box of ONE size. Without it the name's
// left edge moves between rows, and scrolling a mixed list makes the whole
// text column wobble. The visual keeps its own size INSIDE that box: a
// command's glyph should not be as loud as an application's icon, it just has
// to start the text in the same place.
//
// ── receding ─────────────────────────────────────────────────────────────
// A list where you want ONE thing (a launcher) recedes everything else hard,
// so the row that Enter will fire is the only thing at full strength. A list
// you are READING (a device list, a settings list) must not — dimming every
// name to 45% to mark one of them costs the person the other nine. That is
// `recede`, and it is the one real difference the three old types had.
Item {
    id: root

    // ── content ─────────────────────────────────────────────────────────
    // Anything at the leading edge. Empty falls back to `icon`.
    property alias leading: leadingSlot.data
    // The convenience glyph, for the common case.
    property string icon: ""
    property string primary: ""
    property string supporting: ""
    // Trailing content: a reading, a badge, a secondary action.
    default property alias trailing: trailingSlot.data

    // ── consumer-owned state ────────────────────────────────────────────
    property bool selected: false
    // UNAVAILABLE: the action exists but cannot be taken right now. Dims, and
    // stops answering.
    property bool disabled: false
    // A row that only REPORTS. It is not unavailable — an unmanaged interface
    // or a wired profile someone else owns is showing you the truth at full
    // strength — it simply is not a target, so it must not offer a pointer
    // cursor and a press bounce for a click that does nothing.
    //
    // The two are different states and were being conflated: dimming a row to
    // 35% to say "you cannot click this" also says "this reading is stale",
    // which is the opposite of what a live readout means.
    property bool interactive: true
    property bool danger: false
    // Structural rows. They are rows so a keyboard cursor can step past them
    // without the model and the view disagreeing about how many rows there are.
    property bool header: false
    property bool separator: false
    // Keyboard focus. Defaults to this item's own; a list that owns focus for
    // its rows binds it.
    property bool focused: root.activeFocus

    // ── shape ───────────────────────────────────────────────────────────
    // sm | md | lg — the row's height, its type step and its leading box, off
    // one scale. Not a proportional zoom: a denser row gets disproportionately
    // tighter, because scaling everything by one factor reads as a zoom rather
    // than as a different row.
    property string size: "md"
    // Dim the rows that are not the current one. True for a list you PICK from,
    // false for a list you READ.
    property bool recede: true
    property color markColor: root.danger ? Style.danger : Style.accent

    readonly property bool _sm: size === "sm"
    readonly property bool _lg: size === "lg"
    readonly property bool _normal: !header && !separator
    readonly property bool selectable: _normal && !disabled && interactive
    readonly property bool hovered: layer.hovered
    // The leading box every visual sits in.
    readonly property int leadingSize: _sm ? Style.iconMd : Style.iconLg
    readonly property color proseColor: !selectable ? Style.textMuted : danger ? Style.danger : Style.text

    signal activated
    // A hover-enter the POINTER caused. A list binds its cursor to this rather
    // than to `hovered`, so a cursor that never moved cannot take the selection
    // from the keyboard while results reshuffle underneath it.
    signal hoveredEntered

    // Punch the mark. A list calls this when the selection MOVES, which the
    // mark itself has no way to know about — without it, stepping between two
    // rows changes only which row is lit, and on a long list that is easy to
    // miss.
    function pulse(): void {
        if (root.selected)
            pulseAnimation.restart();
    }

    implicitWidth: body.implicitWidth
    implicitHeight: {
        if (root.separator)
            return Style.space3;
        if (root.header)
            return Style.space4 + Style.space2;
        return (_sm ? Style.controlHeightSm : _lg ? Style.controlHeightLg : Style.controlHeight) + Style.space1;
    }

    property real _pulse: 0

    SequentialAnimation {
        id: pulseAnimation
        NumberAnimation {
            target: root; property: "_pulse"; to: 1
            duration: Motion.press / 2; easing.type: Motion.emphasizedEasing
        }
        NumberAnimation {
            target: root; property: "_pulse"; to: 0
            duration: Motion.press / 2; easing.type: Motion.standardEasing
        }
    }

    // ── the mark ────────────────────────────────────────────────────────
    SelectionMark {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        shown: root._normal && root.selected
        markColor: root.markColor

        transform: Scale {
            origin.x: Style.markThickness / 2
            origin.y: Style.markHeight / 2
            xScale: 1 + root._pulse * 0.25
            yScale: 1 + root._pulse * 0.25
        }
    }

    // ── interaction ─────────────────────────────────────────────────────
    // Declared BEFORE the content so the content sits above it: a trailing
    // action's click must not be swallowed by the row's own tap.
    StateLayer {
        id: layer
        anchors.fill: parent
        visible: root.selectable
        // The LEADING BOX grows, never the row. A 570px row scaled inside a
        // clipped list just has its ends shaved off.
        target: leadingBox
        interactive: root.selectable
        focused: root.focused
        focusRadius: Style.radiusSm
        hoverScale: 1.12
        pressScale: 0.92
        onClicked: root.activated()
        onHoveredEntered: root.hoveredEntered()
    }

    // ── header ──────────────────────────────────────────────────────────
    // A label between two rules. It divides a dense list without being a row
    // you can land on.
    RowLayout {
        visible: root.header
        anchors.fill: parent
        anchors.leftMargin: Style.space3
        anchors.rightMargin: Style.space3
        spacing: Style.space2

        Divider { Layout.fillWidth: true; strength: 0.5 }
        Prose { role: "section"; text: root.primary }
        Divider { Layout.fillWidth: true; strength: 0.5 }
    }

    // ── separator ───────────────────────────────────────────────────────
    Divider {
        visible: root.separator
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        inset: Style.space3
        strength: 0.5
    }

    // ── the row itself ──────────────────────────────────────────────────
    RowLayout {
        id: body

        visible: root._normal
        anchors.fill: parent
        anchors.leftMargin: Style.space3
        anchors.rightMargin: Style.space3
        spacing: Style.space2
        // Row-level, so the leading visual and the text fall back together and
        // the mark stays lit. A second fade inside would compound to
        // near-invisible.
        opacity: root.disabled ? Style.opacityDisabled
            : (root.recede && !root.selected) ? Style.opacityRecede
            : 1

        Behavior on opacity {
            NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
        }

        Item {
            id: leadingBox

            Layout.alignment: Qt.AlignVCenter
            visible: leadingSlot.children.length > 0 || root.icon.length > 0
            implicitWidth: root.leadingSize
            implicitHeight: root.leadingSize

            Item {
                id: leadingSlot
                anchors.fill: parent
            }
            SvgIcon {
                anchors.centerIn: parent
                visible: leadingSlot.children.length === 0
                name: root.icon
                // Smaller than its box on purpose — see the leading-box note.
                size: root._sm ? Style.iconSm : Style.iconMd
                color: root.proseColor
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Prose {
                Layout.fillWidth: true
                role: "label"
                font.pixelSize: root._lg ? Style.textMd : Style.textSm
                color: root.proseColor
                text: root.primary

                Behavior on color {
                    ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
                }
            }
            Prose {
                Layout.fillWidth: true
                // Hidden when it only repeats the name. Desktop entries often
                // set the comment to the application's own name ("Volume
                // Control / Volume Control"), and a line restating the line
                // above costs a row's worth of attention for nothing.
                visible: root.supporting.length > 0
                    && root.supporting.toLowerCase() !== root.primary.toLowerCase()
                role: "metadata"
                font.pixelSize: root._lg ? Style.textSm : Style.textXs
                text: root.supporting
            }
        }

        RowLayout {
            id: trailingSlot
            Layout.alignment: Qt.AlignVCenter
            spacing: Style.space2
        }
    }
}
