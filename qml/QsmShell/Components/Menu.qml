import QtQuick
import QtQuick.Templates as T

import qs.QsmShell.Style

// Generic menu / list composition host.
//
// The consumer owns the model (or static content) and the delegate, the current
// selection, orientation, and spacing. `Menu` SHALL NOT define action
// categories, nested command routes, confirmation policy, service calls, or
// keyboard shortcuts — those remain with the consumer. It provides only generic,
// deterministic keyboard stepping that skips nonselectable (header/separator/
// disabled) rows and a generic `activated(index)` hook. Rows are ListRow
// instances supplied by the consumer via `content` or a `delegate`.
//
// The keyboard is one roving stop: Tab lands on the current row (the first
// selectable one with no cursor), the arrows along the orientation, Home and
// End step, Return, Enter and Space activate, and Tab leaves again. The
// current row carries the focus ring.
FocusScope {
    id: root

    // ── consumer-owned composition ───────────────────────────────────────
    // Static rows (ListRow instances) added directly as content.
    default property alias content: body.data
    // Model-backed rows via `delegate`.
    property var model: null
    property Component delegate: null
    // Current selection (index into the full set of rows).
    property int currentIndex: -1
    // Layout orientation and spacing.
    property int orientation: Qt.Vertical
    property real spacing: Style.space1
    // The band's corner. A menu on a rollout keeps the rollout's own curve.
    property real radius: Style.childRadius(root)
    // What a screen reader calls the group of rows.
    property string accessibleName: ""

    // ── generic activation hook (no product meaning) ─────────────────────
    signal activated(int index)

    readonly property bool _horizontal: orientation === Qt.Horizontal
    readonly property bool _vertical: !_horizontal
    readonly property int rowCount: _rows.length
    // A vertical menu's natural width is a constant and long labels elide in
    // their rows; a horizontal one is the sum of its columns.
    implicitWidth: _vertical ? Style.controlWidth
        : _rows.reduce((sum, row) => sum + row.implicitWidth, 0) + Math.max(0, rowCount - 1) * spacing
    implicitHeight: body.implicitHeight

    readonly property list<T.Action> actions: [
        T.Action { objectName: "step-previous"; text: "Previous item"; enabled: root.enabled; onTriggered: root.step(-1) },
        T.Action { objectName: "step-next"; text: "Next item"; enabled: root.enabled; onTriggered: root.step(1) },
        T.Action { objectName: "step-first"; text: "First item"; enabled: root.enabled; onTriggered: root.stepToEdge(true) },
        T.Action { objectName: "step-last"; text: "Last item"; enabled: root.enabled; onTriggered: root.stepToEdge(false) },
        T.Action { objectName: "activate-current"; text: "Activate item"; enabled: root.enabled && root._isSelectable(root.currentIndex); onTriggered: root.activateCurrent() }
    ]

    Accessible.role: Accessible.Grouping
    Accessible.name: root.accessibleName

    // Focus goes to the current row (`_focusCurrent`), so keys reach it and the
    // thumb's ring shows. The ring sits outside the row, so the Menu does not
    // clip it; the owning ScrollArea bounds overflow and leaves the ring room.
    focus: true

    // The band the rows lie on, and the ONE selection thumb that slides
    // between them. Rows report `hovered` and `selected` and paint no
    // selection of their own here, so a cursor moving down the list reads as
    // one marker travelling instead of a highlight snapping from row to row.
    Surface {
        anchors.fill: parent
        base: Style.band
        radius: root.radius
    }

    Surface {
        id: thumb
        objectName: "thumb"

        readonly property var row: root.rowAt(root.currentIndex)
        readonly property bool shown: !!row && row.selectable
        readonly property point origin: root._originOf(row)

        x: origin.x
        y: origin.y
        width: shown ? row.width : 0
        height: shown ? row.selectionHeight : 0
        radius: shown ? Style.childRadius(thumb) : 0
        base: Style.surface
        accent: shown ? row.selectedColor : Style.accent
        hovered: shown && row.hovered
        pressed: shown && row.pressed
        selected: true
        opacity: shown ? 1 : 0

        // The keyboard's mark, the one ring every control wears, travelling
        // with the thumb. A row whose host already paints its own ring
        // (`focused`) keeps the only one.
        StateLayer {
            anchors.fill: parent
            clickable: false
            focused: root.activeFocus && thumb.shown && !thumb.row.focused
            focusRadius: thumb.radius
        }

        // Slides between rows that exist; the first appearance and reduced
        // motion jump (a position animation is removed, not shortened).
        Behavior on x { enabled: !Style.reducedMotion && thumb.opacity > 0; NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing } }
        Behavior on y { enabled: !Style.reducedMotion && thumb.opacity > 0; NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing } }
        Behavior on width { enabled: !Style.reducedMotion && thumb.opacity > 0; NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing } }
        Behavior on height { enabled: !Style.reducedMotion && thumb.opacity > 0; NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing } }
        Behavior on opacity { NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing } }
    }

    // Layout host. Direction follows `orientation`; never applies product policy.
    Grid {
        id: body
        // Constrain only the cross axis: a disclosure must not wrap into a second column.
        width: root._vertical ? root.width : implicitWidth
        height: root._horizontal ? root.height : implicitHeight
        columns: root._vertical ? 1 : Math.max(1, root.rowCount)
        rows: root._horizontal ? 1 : 0
        spacing: root.spacing

        Repeater {
            id: listRepeater
            model: root.model
            delegate: root.delegate
            onItemAdded: root._resync()
            onItemRemoved: Qt.callLater(root._resync)
        }
    }

    // Unavailable as a whole: every painted colour toward the band by the same
    // share `Style.disabled` uses, once, so the layers stay layers.
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        visible: !root.enabled
        color: Qt.alpha(Style.band, 1 - Style.opacityDisabled)
        Accessible.ignored: true
    }

    // ── row registry / stepping ──────────────────────────────────────────
    property var _rows: []
    property var _handlers: []

    function _isRow(o) {
        return !!o && o !== root && typeof o.selectable === 'boolean'
    }

    // A row may sit inside a container the consumer composed (a row plus its
    // inline submenu); the walk descends through anything that is not itself
    // a row, so keyboard stepping follows the document order the eye reads.
    function _collectRows(parentItem, out) {
        for (const child of parentItem.children) {
            if (root._isRow(child))
                out.push(child)
            else
                root._collectRows(child, out)
        }
        return out
    }

    // Where `row` starts inside this menu. Summed through the parent chain
    // rather than mapped, so the binding follows every layout move on the way.
    function _originOf(row) {
        let x = 0, y = 0
        for (let it = row; it && it !== root; it = it.parent) {
            x += it.x
            y += it.y
        }
        return Qt.point(x, y)
    }

    // Rebuild the row registry, re-wire activation routing, and re-apply
    // selection. Deterministic: rows appear in document order.
    function _resync() {
        for (let i = 0; i < _handlers.length; i++) {
            const row = _rows[i], h = _handlers[i]
            if (row && h) { try { row.activated.disconnect(h) } catch (e) { /* not connected */ } }
        }
        const collected = _collectRows(body, [])
        const handlers = []
        for (let i = 0; i < collected.length; i++) {
            const idx = i
            const h = function () { root.currentIndex = idx; root.activated(idx) }
            collected[i].activated.connect(h)
            if (collected[i].paintsSelection)
                collected[i].paintsSelection = false
            handlers.push(h)
        }
        // The cursor follows its row, not its number: an entry removed above
        // it must not move the thumb to the next entry. A row that is gone
        // is found again by its objectName, else the cursor clamps.
        let cursor = currentIndex
        if (_tracking) {
            cursor = _current ? collected.indexOf(_current) : -1
            if (cursor < 0 && _currentKey)
                cursor = collected.findIndex(r => r.objectName === _currentKey)
            if (cursor < 0)
                cursor = Math.min(currentIndex, collected.length - 1)
        }
        _rows = collected
        _handlers = handlers
        if (cursor !== currentIndex)
            currentIndex = cursor
        _applySelection()
        _sizeRows()
    }

    property var _current: null
    property string _currentKey: ""
    property bool _tracking: false

    function _applySelection() {
        for (let i = 0; i < _rows.length; i++) {
            _rows[i].selected = (i === currentIndex)
        }
        _current = rowAt(currentIndex)
        _currentKey = _current?.objectName ?? ""
        _tracking = !!_current
        _focusCurrent()
        _applyTabStop()
    }

    // After the focus has moved: Qt refuses to switch `activeFocusOnTab` off on
    // the item that holds the focus, and warns.
    function _applyTabStop() {
        const stop = _tabStop()
        for (let i = 0; i < _rows.length; i++) {
            if (i === stop || !_rows[i].activeFocus)
                _rows[i].activeFocusOnTab = (i === stop)
        }
    }

    // The one row Tab lands on: the cursor when it can be activated and is on
    // screen, else the first row that can.
    function _tabStop() {
        const reachable = i => _isSelectable(i) && _rows[i].visible
        if (reachable(currentIndex))
            return currentIndex
        for (let i = 0; i < _rows.length; i++) {
            if (reachable(i))
                return i
        }
        return -1
    }

    // The row the keyboard sits in, whatever inside it holds the focus; -1 for none.
    function _indexHolding() {
        for (let it = root.Window.activeFocusItem; it && it !== root; it = it.parent) {
            const i = _rows.indexOf(it)
            if (i >= 0)
                return i
        }
        return -1
    }

    // The ring is the row's own, so focus lives on the current row while the
    // Menu is focused. A row whose child already holds focus (an editor)
    // keeps it; with no selectable current row no row keeps a stale ring.
    function _focusCurrent() {
        if (!root.activeFocus) return
        const row = rowAt(currentIndex)
        if (row && _isSelectable(currentIndex)) {
            if (_indexHolding() !== currentIndex) row.forceActiveFocus()
        } else {
            for (const r of _rows) {
                if (r && r.focus) r.focus = false
            }
        }
    }

    function _sizeRows() {
        for (const child of body.children) {
            if (_vertical)
                child.width = body.width
            else
                child.height = body.height
        }
    }

    // Selectable is the ROW's own state (normal, enabled, interactive). Visibility
    // is not: it is inherited from whatever scene the menu happens to sit in,
    // so a menu inside a scene that is not shown yet — a smoke run, a rollout
    // before it opens — would have no selectable row at all.
    function _isSelectable(i) {
        const r = _rows[i]
        return root.enabled && !!r && r.selectable === true
    }

    function rowAt(index: int): Item {
        return index >= 0 && index < root.rowCount ? root._rows[index] : null
    }

    // Deterministic keyboard stepping: move `delta` rows, skipping every
    // nonselectable (header/separator/disabled) row, wrapping around.
    function step(delta) {
        if (!root.enabled || delta === 0) return
        const n = _rows.length
        if (n === 0) return
        let i = currentIndex >= 0 ? currentIndex : (delta > 0 ? -1 : 0)
        for (let k = 0; k < n; k++) {
            i = (i + delta + n) % n
            // Skip rows that are not selectable (header/separator/disabled).
            if (root._isSelectable(i)) { currentIndex = i; return }
        }
    }

    // Home and End: the first or the last row that can be activated.
    function stepToEdge(first) {
        if (!root.enabled) return
        const n = _rows.length
        for (let k = 0; k < n; k++) {
            const i = first ? k : n - 1 - k
            if (root._isSelectable(i)) { currentIndex = i; return }
        }
    }

    // Emit the generic activation hook for the current row when it is selectable.
    function activateCurrent() {
        if (!_isSelectable(currentIndex)) return false
        const row = root._rows[root.currentIndex]
        row.activate()
        return true
    }

    // The keys the menu owns while it holds the focus. A window shortcut on one
    // of them (an arrow that walks a list elsewhere) outranks a key handler, so
    // the menu says it needs them in `onShortcutOverride`. Home, End and Space
    // are the row's own: from an editor inside it (a slider, a field) they stay
    // the editor's.
    function _owns(key: int): bool {
        const back = root._vertical ? Qt.Key_Up : Qt.Key_Left
        const forward = root._vertical ? Qt.Key_Down : Qt.Key_Right
        if ([back, forward, Qt.Key_Return, Qt.Key_Enter].includes(key))
            return true
        const held = root.Window.activeFocusItem
        return [Qt.Key_Home, Qt.Key_End, Qt.Key_Space].includes(key) && (held === root || _rows.indexOf(held) >= 0)
    }

    Keys.onShortcutOverride: event => { event.accepted = root._owns(event.key) }

    // ONE dispatcher: a key it does not own goes on to the host untouched.
    Keys.onPressed: event => {
        event.accepted = root._owns(event.key)
        if (!event.accepted)
            return
        switch (event.key) {
        case Qt.Key_Home: root.stepToEdge(true); break
        case Qt.Key_End: root.stepToEdge(false); break
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Space:
            if (!event.isAutoRepeat)
                root.activateCurrent()
            break
        default: root.step(event.key === (root._vertical ? Qt.Key_Up : Qt.Key_Left) ? -1 : 1)
        }
    }

    // For a consumer whose rows change below the top level (an inline submenu
    // that opened); a model or delegate change resyncs on its own.
    function resync() { root._resync() }

    // A menu that was not on screen when it was built has no visible row to
    // pick a stop from.
    onVisibleChanged: if (visible) _applyTabStop()

    // Tab lands on a row; the cursor follows it.
    onActiveFocusChanged: {
        if (activeFocus) {
            const held = _indexHolding()
            if (held >= 0 && held !== currentIndex)
                currentIndex = held
        }
        _focusCurrent()
    }
    onModelChanged: _resync()
    onDelegateChanged: _resync()
    onCurrentIndexChanged: _applySelection()
    onOrientationChanged: _sizeRows()
    onWidthChanged: _sizeRows()
    onHeightChanged: _sizeRows()
    Component.onCompleted: _resync()
}
