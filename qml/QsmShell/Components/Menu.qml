import QtQuick
import QtQuick.Templates as T

import qs.QsmShell.Style

// Generic menu / list composition host.
//
// The consumer owns the model (or static content) and the delegate, the current
// selection, orientation, and spacing. `Menu` SHALL NOT define action
// categories, nested command routes, confirmation policy, service calls, or
// desktop shortcuts — those remain with the consumer. It provides only generic,
// deterministic keyboard stepping that skips nonselectable (header/separator/
// disabled) rows and a generic `activated(index)` hook. Rows are ListRow
// instances supplied by the consumer via `content` or a `delegate`.
Item {
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

    // ── generic activation hook (no product meaning) ─────────────────────
    signal activated(int index)

    readonly property bool _horizontal: orientation === Qt.Horizontal
    readonly property bool _vertical: !_horizontal
    readonly property int rowCount: _rows.length
    implicitWidth: _rows.reduce((span, row) => Math.max(span, row.implicitWidth), 0)
    implicitHeight: body.implicitHeight

    readonly property list<T.Action> actions: [
        T.Action { objectName: "step-previous"; text: "Previous item"; enabled: root.enabled; onTriggered: root.step(-1) },
        T.Action { objectName: "step-next"; text: "Next item"; enabled: root.enabled; onTriggered: root.step(1) },
        T.Action { objectName: "activate-current"; text: "Activate item"; enabled: root.enabled && root._isSelectable(root.currentIndex); onTriggered: root.activateCurrent() }
    ]

    focus: true
    clip: true

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
            onItemRemoved: root._resync()
        }
    }

    // ── row registry / stepping ──────────────────────────────────────────
    property var _rows: []
    property var _handlers: []

    function _isRow(o) {
        return !!o && o !== root && typeof o.selectable === 'boolean'
    }

    function _collectRows() {
        const out = []
        for (const child of body.children) {
            if (root._isRow(child))
                out.push(child)
        }
        return out
    }

    // Rebuild the row registry, re-wire activation routing, and re-apply
    // selection. Deterministic: rows appear in document order.
    function _resync() {
        for (let i = 0; i < _handlers.length; i++) {
            const row = _rows[i], h = _handlers[i]
            if (row && h) { try { row.activated.disconnect(h) } catch (e) { /* not connected */ } }
        }
        const collected = _collectRows()
        const handlers = []
        for (let i = 0; i < collected.length; i++) {
            const idx = i
            const h = function () { root.currentIndex = idx; root.activated(idx) }
            collected[i].activated.connect(h)
            handlers.push(h)
        }
        _rows = collected
        _handlers = handlers
        _applySelection()
        _sizeRows()
    }

    function _applySelection() {
        for (let i = 0; i < _rows.length; i++) {
            _rows[i].selected = (i === currentIndex)
        }
    }

    function _sizeRows() {
        for (const row of _rows) {
            if (_vertical)
                row.width = body.width
            else
                row.height = body.height
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

    // Emit the generic activation hook for the current row when it is selectable.
    function activateCurrent() {
        if (!_isSelectable(currentIndex)) return false
        const row = root._rows[root.currentIndex]
        row.activate()
        return true
    }

    Keys.onUpPressed: root._vertical ? root.step(-1) : undefined
    Keys.onDownPressed: root._vertical ? root.step(1) : undefined
    Keys.onLeftPressed: root._horizontal ? root.step(-1) : undefined
    Keys.onRightPressed: root._horizontal ? root.step(1) : undefined
    Keys.onReturnPressed: event => { if (!event.isAutoRepeat) root.activateCurrent() }
    Keys.onEnterPressed: event => { if (!event.isAutoRepeat) root.activateCurrent() }

    onModelChanged: _resync()
    onDelegateChanged: _resync()
    onCurrentIndexChanged: _applySelection()
    onOrientationChanged: _sizeRows()
    onWidthChanged: _sizeRows()
    onHeightChanged: _sizeRows()
    Component.onCompleted: _resync()
}
