// Copied from qsm-desktop. It has no visual or desktop dependency.
.pragma library

function score(query, text, maxSpan) {
    const q = String(query ?? "").toLowerCase();
    const t = String(text ?? "").toLowerCase();
    if (q.length === 0)
        return 0;

    let total = 0;
    let ti = 0;
    let streak = 0;
    let first = -1;
    for (let qi = 0; qi < q.length; qi++) {
        const found = t.indexOf(q[qi], ti);
        if (found === -1)
            return -1;
        if (first === -1)
            first = found;
        if (maxSpan > 0 && found - first + 1 > maxSpan)
            return -1;
        streak = found === ti ? streak + 1 : 1;
        total += streak * 2 - found * 0.01;
        ti = found + 1;
    }
    return total;
}
