.pragma library

// UI forensics walker for the ui-audit / ux-audit skills. Ported from the
// consumer's `qsm inspect` so the same fields come out of both hosts.
// Defaults (visible:true, opacity:1, z:0) are omitted to keep a dump small.

function typeName(item) {
    let name = String(item);
    const paren = name.indexOf("(");
    if (paren !== -1)
        name = name.substring(0, paren);
    // _QMLTYPE_n = named components, _QML_n = anonymous ones.
    const generated = name.search(/_QML(TYPE)?_\d/);
    if (generated !== -1)
        name = name.substring(0, generated);
    if (name.startsWith("QQuick"))
        name = name.substring(6);
    return name;
}

function describe(item, visibleOnly) {
    const origin = item.mapToItem(null, 0, 0);
    const entry = {
        "type": typeName(item),
        "x": Math.round(origin.x * 10) / 10,
        "y": Math.round(origin.y * 10) / 10,
        "w": Math.round(item.width * 10) / 10,
        "h": Math.round(item.height * 10) / 10
    };
    if (item.objectName !== "")
        entry.name = item.objectName;
    if (!item.visible)
        entry.visible = false;
    if (item.opacity < 1)
        entry.opacity = Math.round(item.opacity * 100) / 100;
    if (item.z !== 0)
        entry.z = item.z;
    if (item.clip)
        entry.clip = true;
    if (item.scale !== undefined && item.scale !== 1)
        entry.scale = Math.round(item.scale * 1000) / 1000;
    if (item.color !== undefined)
        entry.color = String(item.color);
    if (item.radius !== undefined)
        entry.radius = item.radius;
    if (item.spacing !== undefined)
        entry.spacing = item.spacing;
    // What a StateLayer GROWS and by how much; the layer's own rect is the
    // hit area, not the thing that moves.
    if (item.hoverScale !== undefined && item.target !== undefined && item.target !== null
        && item.target.mapToItem !== undefined) {
        const grown = item.target.mapToItem(null, 0, 0);
        entry.growth = {
            "x": Math.round(grown.x * 10) / 10,
            "y": Math.round(grown.y * 10) / 10,
            "w": Math.round(item.target.width * 10) / 10,
            "h": Math.round(item.target.height * 10) / 10,
            "scale": item.hoverScale
        };
    }
    if (item.text !== undefined) {
        entry.text = String(item.text);
        if (item.font !== undefined)
            entry.fontPx = item.font.pixelSize;
    }
    const children = [];
    for (let i = 0; i < item.children.length; i++) {
        const child = item.children[i];
        if (visibleOnly && !child.visible)
            continue;
        children.push(describe(child, visibleOnly));
    }
    if (children.length > 0)
        entry.children = children;
    return entry;
}
