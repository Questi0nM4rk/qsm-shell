pragma Singleton

import QtQuick

// Fuzzy subsequence scoring (fzf-style): every query char must appear in
// order; consecutive runs and early matches score higher. -1 = no match.
// One scorer for every list that filters by typing, so a result list and a
// notification search rank the same query the same way.
//
// `maxSpan` (optional) caps how far apart the first and last matched character
// may sit. Over SHORT haystacks -- app names, keybind descriptions -- plain
// subsequence matching is right and the cap is left off. Over long ones it is
// not: a clipboard entry can be a whole file, and any four letters will be
// findable somewhere in it in order, so no query would ever report "No
// match". Callers with long haystacks pass a span.
QtObject {
    function score(query: string, text: string, maxSpan: real): real {
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
}
