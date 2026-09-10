pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// One of N, with all N visible at once.
//
// It used to be called `TabStrip`, which named ONE of its jobs. Switching
// panels and picking a value are the same control: the same mechanic, the same
// keyboard, the same mark for "this one" — and the moment a surface needed the
// second job, the library would have grown a `SegmentedControl` sitting beside
// this one, differing in nothing that mattered. Whether the emitted index
// changes a panel or sets a value is the consumer's business, which is exactly
// where it belongs.
//
// Use it while N is small enough to show — past about five options the person
// is scanning rather than choosing, and a menu is the right pattern.
//
// `options` takes strings or objects. An object may carry `label`, `icon`,
// `badge` and `disabled`; a bare string is just its label. Accepting both is
// deliberate: a three-tab strip should not have to write objects to say three
// words.
RowLayout {
    id: root

    required property var options
    property int currentIndex: 0
    property bool compact: false
    // Keyboard focus. The strip owns focus for the whole set, which is what
    // makes it ONE tab stop rather than N.
    property bool focused: root.activeFocus

    signal selected(int index)

    spacing: Style.space2

    function _at(index: int): var {
        const option = root.options[index];
        return option === undefined ? null : option;
    }
    function _labelOf(option: var): string {
        return typeof option === "string" ? option : String(option?.label ?? "");
    }
    function _enabled(index: int): bool {
        const option = root._at(index);
        return option !== null && (typeof option === "string" || option.disabled !== true);
    }

    // Arrows move the choice, skipping anything unavailable and wrapping —
    // wrapping because with every option visible there is no "end of the
    // list" to run off, so stopping at one just feels stuck.
    function step(delta: int): void {
        const count = root.options.length;
        if (count === 0)
            return;
        let index = root.currentIndex;
        for (let tried = 0; tried < count; tried++) {
            index = (index + delta + count) % count;
            if (root._enabled(index)) {
                root.selected(index);
                return;
            }
        }
    }

    Keys.onLeftPressed: root.step(-1)
    Keys.onRightPressed: root.step(1)
    // Home and End have no named handler on `Keys` — only the arrows, Return,
    // Escape, Space, Tab and the digits do. They are worth the explicit check:
    // past three options, jumping to an end beats stepping to it.
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Home && root._enabled(0)) {
            root.selected(0);
            event.accepted = true;
        } else if (event.key === Qt.Key_End && root._enabled(root.options.length - 1)) {
            root.selected(root.options.length - 1);
            event.accepted = true;
        }
    }

    Repeater {
        model: root.options

        delegate: Item {
            id: segment

            required property var modelData
            required property int index

            readonly property bool current: root.currentIndex === segment.index
            readonly property bool available: typeof segment.modelData === "string"
                || segment.modelData?.disabled !== true

            Layout.fillWidth: true
            implicitHeight: root.compact ? Style.controlHeightSm : Style.controlHeightLg
            opacity: segment.available ? 1 : Style.opacityDisabled

            // A segment sits on the bar's own body, so its base is nothing and
            // selection is the translucent accent over whatever is beneath.
            Surface {
                anchors.fill: parent
                radius: Style.radiusSm
                base: "transparent"
                selected: segment.current
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: Style.space2

                SvgIcon {
                    visible: name.length > 0
                    name: typeof segment.modelData === "string" ? "" : String(segment.modelData?.icon ?? "")
                    size: root.compact ? Style.iconXs : Style.iconSm
                    color: segment.current ? Style.text : Style.textMuted
                }
                Prose {
                    role: "label"
                    text: root._labelOf(segment.modelData)
                    color: segment.current ? Style.text : Style.textMuted
                    font.pixelSize: root.compact ? Style.textXs : Style.textSm
                    font.weight: segment.current ? Style.weightBold : Style.weightMedium
                }
                Badge {
                    visible: text.length > 0
                    tone: segment.current ? "accent" : "neutral"
                    text: typeof segment.modelData === "string" ? "" : String(segment.modelData?.badge ?? "")
                }
            }

            StateLayer {
                anchors.fill: parent
                // A segment fills its share of the row, so growing it would
                // shove its neighbours. The tint and the label weight are the
                // response here.
                target: null
                interactive: segment.available
                focused: segment.current && root.focused
                focusRadius: Style.radiusSm
                hoverScale: 1
                pressScale: 0.98
                onClicked: root.selected(segment.index)
            }
        }
    }
}
