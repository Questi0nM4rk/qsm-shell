import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// THE row. One line in a list of things a person picks from.
//
// A menu's row, a device list's row and a search result's row are one anatomy:
// a mark, one leading visual, a name, a supporting line, some trailing
// content. They differ in a handful of numbers, which `size` and `recede`
// carry, so they are one type: a type named after the SURFACE it serves is a
// type you have twice.
//
// ── the leading box ──────────────────────────────────────────────────────
// Whatever sits at the leading edge — a glyph, an application icon, a
// wallpaper thumbnail — occupies a box of ONE size. Without it the name's
// left edge moves between rows, and scrolling a mixed list makes the whole
// text column wobble. The visual keeps its own size INSIDE that box: a
// command's glyph should not be as loud as an application's icon, it just has
// to start the text in the same place. A row with no visual takes no box (an
// empty slot takes no space); a list that mixes rows with and without a visual
// sets `reserveLeading` on all of them to keep the edge put.
//
// ── receding ─────────────────────────────────────────────────────────────
// A list where you want ONE thing (search results) recedes everything else, so
// the row that Enter will fire is the only thing at full strength. A list you
// are READING (a device list, a settings list) must not: dimming every name to
// mark one of them costs the person the other nine. That is `recede`. A row
// recedes its own text and glyph by colour (`Style.recede`) and the content a
// host slots in at `Style.opacityRecede`, since a picture cannot be blended;
// it reports `receded`.
Item {
    id: root

    // ── content ─────────────────────────────────────────────────────────
    // Anything at the leading edge. Empty falls back to `icon`.
    property alias leading: leadingSlot.data
    // The convenience glyph, for the common case.
    property string icon: ""
    // Keep the leading box even when the row has no visual.
    property bool reserveLeading: false
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
    // The two are different states: dimming a row to say "you cannot click
    // this" also says "this reading is stale", which is the opposite of what
    // a live readout means.
    property bool interactive: true
    property bool danger: false
    // Structural rows. They are rows so a keyboard cursor can step past them
    // without the model and the view disagreeing about how many rows there are.
    property bool header: false
    property bool separator: false
    // A header's name wears the accent instead of the muted section colour:
    // the group that is current (a cheat sheet's open section).
    property bool accentHeader: false
    // Keyboard focus. The row takes none; the list that owns focus for its
    // rows binds it.
    property bool focused: false

    // ── shape ───────────────────────────────────────────────────────────
    // A ListRow preset: the row's height (the ListRow table), and through it
    // its glyph, its leading box and its type steps.
    property string size: "md"
    // Dim the rows that are not the current one. True for a list you PICK from,
    // false for a list you READ.
    property bool recede: true
    // What the selected row wears: the fill's tint and the name.
    property color selectedColor: root.danger ? Style.danger : Style.accent
    // Whether this row paints its own selection. A `Menu` owns one thumb that
    // slides between rows and sets this false; a row in a plain ListView keeps
    // the default and paints it.
    property bool paintsSelection: true
    // The highlight sits directly in a rollout, so it takes the body radius
    // (`childRadius` cannot see through a ListView). A `Menu` reads it for its
    // thumb.
    readonly property real selectionRadius: Style.radiusBody

    // The row's height from the ListRow table: the one number its glyph, its
    // leading box and its text steps derive from.
    readonly property real _height: Style.size("ListRow", root.size)
    readonly property real _s: root._height / Style.size("ListRow", "md")
    readonly property bool _normal: !header && !separator
    readonly property bool selectable: _normal && !disabled && interactive
    readonly property bool hovered: layer.hovered
    readonly property bool pressed: layer.pressed
    // The row's own height without its expansion: what a selection covers.
    readonly property real selectionHeight: root._headingHeight
    readonly property real _nativeHeadingHeight: root.separator ? Style.space3
        : root.header ? Style.space4 + Style.space2
        : root._height
    property real headingHeight: root._nativeHeadingHeight
    readonly property real expansionHeight: expandedViewport.height
    readonly property real _headingHeight: root._hasExpandedContent
        ? root.headingHeight : root.height > 0 ? root.height : root.headingHeight
    // A child that measures nothing (an empty Loader) is not content: each
    // child's own size is read, never the layout's.
    readonly property bool _hasTrailing: {
        for (const c of trailingSlot.children) {
            if (c.visible && c.implicitWidth > 0)
                return true
        }
        return false
    }
    // A leading child that is hidden is not content: a host whose entry has no
    // visual hides it and the text starts at the row's inset. A child reads its
    // EFFECTIVE visibility, so neither slot is ever hidden itself: a slot hidden
    // because its content was hidden would never see the content come back.
    readonly property bool _hasLeading: {
        for (const c of leadingSlot.children) {
            if (c.visible)
                return true
        }
        return false
    }
    readonly property bool _hasExpandedContent: root._normal && expandedHost.implicitHeight > 0
    readonly property real _expandedHeight: root.expanded && root._hasExpandedContent ? expandedViewport.implicitHeight : 0
    // The leading box every visual sits in, and the glyph that sits in it:
    // the glyph is the role for a glyph beside a name in a box of the row's
    // height, and the box is one step wider on purpose. A host's own leading
    // glyph takes `glyphSize` so it never differs from the row's.
    readonly property int glyphSize: Style.glyphBeside(root._height)
    readonly property int leadingSize: root.glyphSize + Style.space1
    // Text grows at half the row's rate above md and never shrinks below it:
    // a denser row keeps its reading size, a taller one grows calmly.
    readonly property real _textScale: Math.max(1, (1 + root._s) / 2)
    // Not the current one: later in a list you pick from, not under the
    // pointer, not unavailable and not a report. Disabled and report-only rows
    // show at full strength; disabled dims by colour on its own.
    readonly property bool receded: root.recede && root._normal && root.interactive
        && !root.disabled && !root.selected && !root.hovered && !root.pressed
    readonly property real contentInset: root._inset
        + (leadingBox.shown ? root.leadingSize + Style.space2 : 0)
    // Disabled and receded dim by colour, never by opacity on the row: the
    // glyph and both lines are dimmed here. A host's slotted content falls back
    // with them through `_slotOpacity`; disabled leaves it at full strength.
    readonly property color proseColor: {
        if (root.disabled)
            return Style.disabled(Style.text);
        const ink = root.danger ? Style.danger
            : root._normal && root.selected ? root.selectedColor
            : Style.text;
        return root.receded ? Style.recede(ink) : ink;
    }
    property real _slotOpacity: root.receded ? Style.opacityRecede : 1
    Behavior on _slotOpacity {
        NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
    }
    readonly property color _mutedColor: root.disabled ? Style.disabled(Style.textMuted)
        : root.receded ? Style.recede(Style.textMuted) : Style.textMuted

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

    // ── the body ────────────────────────────────────────────────────────
    // One `Surface` answers hover, press and selection through `Style.tone`:
    // the lift under the pointer, a deeper one while pressed, and the accent
    // at `opacitySelected` over the SURFACE step with the name in the accent,
    // with no side marker. Over the band the tint read
    // as a smudge, so it is laid over the surface it belongs on. Invisible at
    // rest: a list paints no box around a row nobody is touching.
    Surface {
        readonly property bool _selectedHere: root._normal && root.selected && root.paintsSelection
        y: 0
        width: parent.width
        height: root._headingHeight
        radius: root.selectionRadius
        base: Style.surface
        accent: root.selectedColor
        hovered: root.hovered
        pressed: root.pressed
        selected: _selectedHere
        opacity: root.selectable && (root.hovered || root.pressed || _selectedHere)
            && !(root.selected && !root.paintsSelection) ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
        }
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
        // The leading glyph grows, never the row. A 570px row grown inside a
        // clipped list just has its ends shaved off.
        extent: root.leadingSize
        interactive: root.selectable
        focused: root.focused
        focusRadius: root.selectionRadius
        hoverScale: Motion.rowHoverScale
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

        Divider { Layout.fillWidth: true }
        Prose {
            role: "section"
            text: root.primary
            color: root.accentHeader ? Style.accent : Style.textMuted
        }
        Divider { Layout.fillWidth: true }
    }

    // ── separator ───────────────────────────────────────────────────────
    Divider {
        visible: root.separator
        anchors.left: parent.left
        anchors.right: parent.right
        y: Math.round((root._headingHeight - height) / 2)
        inset: Style.space3
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
        spacing: 0

        Item {
            id: leadingBox

            readonly property bool shown: root.reserveLeading || root._hasLeading || root.icon.length > 0

            Layout.alignment: Qt.AlignVCenter
            // The gap after the box belongs to the box, so an empty one leaves
            // none.
            Layout.rightMargin: shown ? Style.space2 : 0
            implicitWidth: shown ? root.leadingSize : 0
            implicitHeight: root.leadingSize

            Item {
                id: leadingSlot
                anchors.fill: parent
                opacity: root._slotOpacity
            }
            SvgIcon {
                anchors.centerIn: parent
                visible: leadingSlot.children.length === 0
                name: root.icon
                size: root.glyphSize + 2 * layer.growth
                color: root.proseColor

                Behavior on color {
                    ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Prose {
                Layout.fillWidth: true
                role: "label"
                font.pixelSize: Style.textNear(Style.textSm * root._textScale)
                color: root.proseColor
                text: root.primary

                Behavior on color {
                    ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
                }
            }
            Prose {
                Layout.fillWidth: true
                // Hidden when it only repeats the name. Application entries
                // often set the comment to the application's own name ("Volume
                // Control / Volume Control"), and a line restating the line
                // above costs a row's worth of attention for nothing.
                visible: root.supporting.length > 0
                    && root.supporting.toLowerCase() !== root.primary.toLowerCase()
                role: "metadata"
                color: root._mutedColor
                font.pixelSize: Style.textNear(Style.textXs * root._textScale)
                text: root.supporting

                Behavior on color {
                    ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
                }
            }
        }

        RowLayout {
            id: trailingSlot
            objectName: "trailingSlot"
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: root._hasTrailing ? Style.space2 : 0
            spacing: Style.space2
            opacity: root._slotOpacity
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
            NumberAnimation {
                duration: root.expanded ? Motion.fast : Motion.exit(Motion.fast)
                easing.type: Motion.moveEasing
            }
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
