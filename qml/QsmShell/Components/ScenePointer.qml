import QtQuick

// Attach to the surfaces' common ancestor: sibling readers either lose hover
// or shadow descendants. A source replaces facts, never containment.
HoverHandler {
    id: root

    property var source: null
    readonly property bool inside: source ? !!source.inside : hovered
    readonly property point position: source ? source.position : point.position

    function triangleArea(a, b, c): var {
        return ({ type: "triangle", a: a, b: b, c: c })
    }

    function contains(area): bool {
        if (!root.inside || !area)
            return false
        const p = root.position
        if (area.type !== "triangle")
            return p.x >= area.x && p.x <= area.x + area.width
                && p.y >= area.y && p.y <= area.y + area.height
        const a = area.a
        const b = area.b
        const c = area.c
        const cross = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
        if (cross === 0)
            return false
        const d1 = (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x)
        const d2 = (c.x - b.x) * (p.y - b.y) - (c.y - b.y) * (p.x - b.x)
        const d3 = (a.x - c.x) * (p.y - c.y) - (a.y - c.y) * (p.x - c.x)
        return (d1 >= 0 && d2 >= 0 && d3 >= 0) || (d1 <= 0 && d2 <= 0 && d3 <= 0)
    }
}
