import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// Generic row primitive for menus and lists.
//
// Leading, primary, supporting, and trailing content are injectable; the
// selected / disabled / danger / header / separator state is consumer-owned.
// The row emits generic `activated` and `hovered` interaction without
// interpreting their meaning, and nonselectable
// (header/separator) rows never route normal activation. Interactive trailing
// content (e.g. a secondary-action button) sits above the activation layer so
// its clicks are never stolen by the row.
Item {
    id: root

    // ── content injection ───────────────────────────────────────────────
    // Custom leading content slot (consumer places an Item here).
    property alias leading: leadingSlot.data
    // Convenience leading icon name (bundled library asset).
    property string icon: ""
    // Primary label text.
    property string primary: ""
    // Supporting/secondary text rendered below the primary text.
    property string supporting: ""
    // Trailing / overflow content slot (e.g. badge, value, secondary action).
    default property alias content: trailingArea.data

    // ── consumer-owned state ────────────────────────────────────────────
    property bool selected: false
    property bool disabled: false
    property bool danger: false
    property bool header: false
    property bool separator: false
    readonly property bool _normal: !header && !separator
    readonly property bool selectable: _normal && !disabled

    // ── generic interaction ─────────────────────────────────────────────
    readonly property bool hovered: interaction.hovered
    // Keyboard focus. Defaults to this item's own, so a control that takes
    // focus rings without wiring; a list that owns focus for its rows binds it.
    property bool focused: root.activeFocus
    signal activated

    // ── derived presentation ────────────────────────────────────────────
    readonly property color accent: danger ? Style.danger : Style.accent
    readonly property color proseColor: !selectable ? Style.textMuted : danger ? Style.danger : Style.text

    implicitWidth: normalBody.implicitWidth
    implicitHeight: root._normal
        ? Style.controlHeightSm + Style.space1
        : root.header ? Style.space4 + Style.space2 : Style.space3

    // Left selection accent (only on selectable rows).
    SelectionMark {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        shown: root._normal && root.selected
        markColor: root.accent
    }

    // Activation / hover layer. Nonselectable rows are never interactive, so a
    // header/separator/disabled row cannot activate. Declared before (below)
    // the content so interactive trailing content stays clickable.
    StateLayer {
        id: interaction
        anchors.fill: parent
        visible: root.selectable
        target: glyph
        interactive: root.selectable
        focused: root.focused
        focusRadius: Style.radiusSm
        hoverScale: 1.12
        pressScale: 0.92
        onClicked: root.activated()
    }

    // Header presentation: centered label flanked by divider lines.
    RowLayout {
        visible: root.header
        anchors.fill: parent
        anchors.leftMargin: Style.space3
        anchors.rightMargin: Style.space3
        spacing: Style.space2
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Style.textMuted; opacity: .5 }
        Prose {
            role: "section"
            font.capitalization: Font.MixedCase
            font.letterSpacing: 0
            text: root.primary
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Style.textMuted; opacity: .5 }
    }

    // Separator presentation: a single thin divider line.
    Rectangle {
        visible: root.separator
        anchors.verticalCenter: parent.verticalCenter
        height: 1
        color: Style.outline
        opacity: .5
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Style.space3
        anchors.rightMargin: Style.space3
    }

    // Normal selectable row layout.
    RowLayout {
        id: normalBody
        visible: root._normal
        anchors.fill: parent
        anchors.leftMargin: Style.space3
        anchors.rightMargin: Style.space3
        spacing: Style.space2
        opacity: root.selected ? 1 : (root.disabled ? Style.opacityDisabled : 0.45)
        Behavior on opacity { NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing } }

        // Leading content: custom slot wins; otherwise convenience icon.
        Item { id: leadingSlot; visible: children.length > 0 }
        SvgIcon {
            id: glyph
            visible: leadingSlot.children.length === 0
            name: root.icon
            size: Style.iconSm
            color: root.proseColor
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Prose {
                Layout.fillWidth: true
                role: "label"
                color: root.proseColor
                text: root.primary
                Behavior on color { ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing } }
            }
            Prose {
                Layout.fillWidth: true
                visible: root.supporting.length > 0
                role: "metadata"
                text: root.supporting
            }
        }
        RowLayout {
            id: trailingArea
            Layout.alignment: Qt.AlignVCenter
            spacing: Style.space2
        }
    }
}
