import QtQuick

// Shared preview-owned flow bridge helpers (workbench bead 1q6.2).
// Preview (solo) and CompositionPreview (node-qualified) expose the same
// direct flow* methods; the pure lookups below keep both hosts on one
// naming and result shape. No state machine, no execution, no animation
// checkpoints (bead .4), no capture logic.
QtObject {
    id: bridge

    // Descriptor text bound (composition-types.json text maxLength).
    readonly property int maxTextLength: 200

    // Stable flow names derive from declared control/option labels:
    // lowercase with whitespace folded to dashes, so `readOnly` reads
    // `readonly` without duplicating any control declaration.
    function canonicalName(label: string): string {
        return String(label ?? "").toLowerCase().replace(/\s+/g, "-");
    }

    // Arrays crossing createObject/setSource arrive as QVariantList, for
    // which Array.isArray is false. Normalize before use.
    function asArray(v): var {
        if (v === null || v === undefined)
            return [];
        if (Array.isArray(v))
            return v;
        if (typeof v.length === "number") {
            const out = [];
            for (let i = 0; i < v.length; i++)
                out.push(v[i]);
            return out;
        }
        return [];
    }

    function controlGroupsOf(item: var): var {
        if (!item)
            return [];
        const raw = item.controls;
        return Array.isArray(raw) ? raw : bridge.asArray(raw);
    }

    function findGroupIndex(controls: var, name: string): int {
        const want = bridge.canonicalName(name);
        const list = bridge.asArray(controls);
        for (let i = 0; i < list.length; i++) {
            if (list[i] && bridge.canonicalName(list[i].label) === want)
                return i;
        }
        return -1;
    }

    function findOptionIndex(options: var, name: string): int {
        const want = bridge.canonicalName(name);
        const list = bridge.asArray(options);
        for (let i = 0; i < list.length; i++) {
            if (list[i] && bridge.canonicalName(list[i].label) === want)
                return i;
        }
        return -1;
    }

    // Canonicalized control/option snapshot for capability discovery.
    function canonicalControls(controls: var): var {
        const out = [];
        const list = bridge.asArray(controls);
        for (let i = 0; i < list.length; i++) {
            const group = list[i];
            if (!group)
                continue;
            const options = [];
            const rawOptions = bridge.asArray(group.options);
            for (let o = 0; o < rawOptions.length; o++) {
                if (!rawOptions[o])
                    continue;
                options.push({
                    name: bridge.canonicalName(rawOptions[o].label),
                    label: String(rawOptions[o].label ?? "")
                });
            }
            out.push({
                name: bridge.canonicalName(group.label),
                label: String(group.label ?? ""),
                options: options
            });
        }
        return out;
    }

    function okResult(value: var): var {
        return { ok: true, value: value };
    }

    function failResult(message: string): var {
        return { ok: false, error: String(message) };
    }
}
