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
    property bool expanded: false
    property alias expandedContent: expandedHost.data
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
    // What the selected row wears: the fill's tint and the name.
    property color selectedColor: root.danger ? Style.danger : Style.accent

    readonly property bool _sm: size === "sm"
    readonly property bool _lg: size === "lg"
    readonly property bool _normal: !header && !separator
    readonly property bool selectable: _normal && !disabled && interactive
    readonly property bool hovered: layer.hovered
    readonly property real _nativeHeadingHeight: root.separator ? Style.space3
        : root.header ? Style.space4 + Style.space2
        : (_sm ? Style.controlHeightSm : _lg ? Style.controlHeightLg : Style.controlHeight) + Style.space1
    property real headingHeight: root._nativeHeadingHeight
    readonly property real expansionHeight: expandedViewport.height
    readonly property real _headingHeight: root._hasExpandedContent
        ? root.headingHeight : root.height > 0 ? root.height : root.headingHeight
    readonly property bool _hasExpandedContent: root._normal && expandedHost.implicitHeight > 0
    readonly property real _expandedHeight: root.expanded && root._hasExpandedContent ? expandedViewport.implicitHeight : 0
    // The leading box every visual sits in.
    readonly property int leadingSize: _sm ? Style.iconMd : Style.iconLg
    readonly property real contentInset: root._inset
        + (leadingBox.visible ? root.leadingSize + Style.space2 : 0)
    // Report-only rows (interactive: false) are not targets but render at full
    // strength; disabled rows dim; recede only applies to interactive rows.
    readonly property color proseColor: root.disabled ? Style.textMuted
        : root.danger ? Style.danger
        : root._normal && root.selected ? root.selectedColor
        : Style.text

    signal activated
    // A hover-enter the POINTER caused. A list binds its cursor to this rather
    // than to `hovered`, so a cursor that never moved cannot take the selection
    // from the keyboard while results reshuffle underneath it.
    signal hoveredEntered

    Accessible.role: root.selectable ? Accessible.Button : Accessible.StaticText
    Accessible.name: root.primary
    Accessible.description: root._hasExpandedContent
        ? root.supporting + (root.supporting.length ? ", " : "") + (root.expanded ? "Expanded" : "Collapsed")
        : root.supporting

    Accessible.onPressAction: root.activate()

    function activate(): void {
        if (root.selectable)
            root.activated()
    }

    // The row's own horizontal inset, named once because three things need to
    // agree on it: the header rail, the body, and the width the row asks for.
    readonly property real _inset: Style.space3

    // Body plus the inset the body then loses to its own margins. Asking for
    // the body's width alone made a row sized to its OWN implicit width eat
    // two insets of its content -- invisible for as long as every call site
    // imposed a width, and truncated text the moment one did not.
    implicitWidth: body.implicitWidth + root._inset * 2
    implicitHeight: root.headingHeight + root.expansionHeight

    // ── the selection ───────────────────────────────────────────────────
    // The accent at `opacitySelected` over whatever the row sits on, with the
    // name in the accent (spec 07, owner 2026-10-16): no side marker.
    Rectangle {
        y: 0
        width: parent.width
        height: root._headingHeight
        radius: Style.radiusSm
        visible: root._normal && root.selected
        color: Style.selected(Qt.rgba(0, 0, 0, 0), root.selectedColor)
    }

    // ── interaction ─────────────────────────────────────────────────────
    // Declared BEFORE the content so the content sits above it: a trailing
    // action's click must not be swallowed by the row's own tap.
    StateLayer {
        id: layer
        x: 0
        y: 0
        width: parent.width
        height: root._headingHeight
        visible: root.selectable
        // The LEADING BOX grows, never the row. A 570px row scaled inside a
        // clipped list just has its ends shaved off.
        target: leadingBox
        interactive: root.selectable
        focused: root.focused
        focusRadius: Style.radiusSm
        hoverScale: 1.12
        pressScale: 0.92
        onClicked: root.activate()
        onHoveredEntered: root.hoveredEntered()
    }

    // ── header ──────────────────────────────────────────────────────────
    // A label between two rules. It divides a dense list without being a row
    // you can land on.
    RowLayout {
        visible: root.header
        anchors.left: parent.left
        anchors.right: parent.right
        y: 0
        height: root._headingHeight
        anchors.leftMargin: root._inset
        anchors.rightMargin: root._inset
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
        y: (root._headingHeight - height) / 2
        inset: Style.space3
        strength: 0.5
    }

    // ── the row itself ──────────────────────────────────────────────────
    RowLayout {
        id: body
        objectName: "body"

        visible: root._normal
        anchors.left: parent.left
        anchors.right: parent.right
        y: 0
        height: root._headingHeight
        anchors.leftMargin: root._inset
        anchors.rightMargin: root._inset
        spacing: Style.space2
        // Row-level, so the leading visual and the text fall back together and
        // the mark stays lit. A second fade inside would compound to
        // near-invisible.
        opacity: root.disabled ? Style.opacityDisabled
            : (!root.interactive || root.selected) ? 1
            : root.recede ? Style.opacityRecede
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
            objectName: "trailingSlot"
            Layout.alignment: Qt.AlignVCenter
            spacing: Style.space2
            visible: children.length > 0
        }
    }

    Item {
        id: expandedViewport
        objectName: "expandedViewport"
        x: root.contentInset - Style.spaceTight
        y: root._headingHeight
        width: Math.max(0, root.width - x - root._inset)
        height: root._expandedHeight
        implicitHeight: root._hasExpandedContent ? expandedHost.implicitHeight + Style.spaceTight + Style.space2 : 0
        clip: true
        enabled: root.expanded && root._hasExpandedContent && root.selectable
        visible: height > 0 || (root.expanded && root._hasExpandedContent)

        Behavior on height {
            enabled: !Style.reducedMotion
            NumberAnimation { duration: Motion.fast; easing.type: Motion.moveEasing }
        }

        ColumnLayout {
            id: expandedHost
            x: Style.spaceTight
            y: Style.spaceTight
            width: Math.max(0, expandedViewport.width - Style.spaceTight * 2)
            spacing: Style.space2
            enabled: expandedViewport.enabled
        }
    }
}
