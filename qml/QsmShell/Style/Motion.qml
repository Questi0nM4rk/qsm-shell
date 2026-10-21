pragma Singleton

import QtQuick

import qs.QsmShell.Style

// THE motion vocabulary. Two questions only: how long, and along which curve.
//
// Duration is named by the ROLE of the change, never by a number, so a call
// site says what it is doing rather than how many milliseconds it wants.
// Nothing a person is waiting on runs longer than `fast`; anything above that
// is a surface arriving or leaving, which is a different kind of event.
//
// Curves come in three, and the split is not decoration. A thing arriving
// should land — decelerate into place, so the eye catches it at the end. A
// thing leaving should get out of the way — accelerate away, because nobody
// watches an exit. A thing MOVING between two places it already occupies is
// neither, so it eases at both ends.
//
// Reduced motion shortens every duration rather than removing the animation:
// a change with no transition at all reads as a glitch, not as calm. The one
// exception is the hover GROWTH scales below, which are movement rather than
// time: they drop to 1 and the body's colour lift carries the hover alone.
QtObject {
    // press — the acknowledgement under a finger. Anything slower feels late.
    readonly property int press: Style.reducedMotion ? 40 : Tokens.motionPress
    // micro — hover, toggle, a colour or opacity settling.
    readonly property int micro: Style.reducedMotion ? 60 : Tokens.motionMicro
    // microPop — a small surface arriving with a scale settle (a card's
    // entrance). Distinct from `micro`: it carries its own tuned duration
    // rather than reusing the hover/toggle number, so retuning one does not
    // silently retune the other.
    readonly property int microPop: Style.reducedMotion ? 60 : Tokens.motionMicroPop
    // microPopDuration — the same settle, named for a host whose content
    // slot rides it directly (Rollout's detached `settleContent`). One fact, two
    // names during the transition: retuning `microPop` retunes this too.
    readonly property int microPopDuration: microPop
    // microPopScale — the one settle scale every micro-pop entrance shares
    // (0.97: barely a press, just enough to read as arriving rather than
    // appearing). Unlike the duration it does not shorten under reduced
    // motion; reduced motion asks for less TIME, not a smaller shape.
    readonly property real microPopScale: Tokens.motionMicroPopScale
    // Capsules span a label and optional reading, so their hover response is
    // quieter than an icon target's default growth.
    readonly property real capsuleHoverScale: Style.reducedMotion ? 1 : Tokens.motionCapsuleHoverScale
    // The default response of an icon-sized target: it grows under the
    // pointer and pushes in under a press.
    readonly property real hoverScale: Style.reducedMotion ? 1 : Tokens.motionHoverScale
    // `hoverScale`, capped so two neighbours that are both grown (the open
    // one holds its hover while the pointer enters the next) keep `spaceTight`
    // between them. Each body gains extent * (s - 1) / 2 per side, so the gap
    // left is  gap - extent * (s - 1)  and  s <= 1 + (gap - spaceTight) / extent
    // keeps it at or above spaceTight. Growth is a pixel overhang bounded by
    // the gap, not a ratio, so a taller or tighter stack grows by less: the
    // bigger the instance, the calmer.
    function hoverScaleWithin(extent: real, gap: real): real {
        return 1 + Math.min(hoverScale - 1, Math.max(0, gap - Style.spaceTight) / extent);
    }
    readonly property real pressScale: Tokens.motionPressScale
    // A press on a content group inside a wide body (a segment's label)
    // moves barely: the body does not grow, only the content acknowledges.
    readonly property real pressScaleSoft: Tokens.motionPressScaleSoft
    // A row's leading box is larger than an icon target and grows more.
    readonly property real rowHoverScale: Style.reducedMotion ? 1 : Tokens.motionRowHoverScale
    readonly property real rowPressScale: Tokens.motionRowPressScale
    // fast — a control changing shape, a row disclosing. The ceiling for
    // anything the pointer or the keyboard is waiting on.
    readonly property int fast: Style.reducedMotion ? 80 : Tokens.motionFast
    // medium — a popout or a menu arriving.
    readonly property int medium: Style.reducedMotion ? 100 : Tokens.motionMedium
    // large — a whole surface rolling out or retracting.
    readonly property int large: Style.reducedMotion ? 120 : Tokens.motionLarge

    // An exit is shorter than the entry it undoes: nobody watches a thing leave,
    // and a leaving thing that lingers reads as late. Pass the entry duration;
    // it is already shortened under reduced motion, so the exit follows it.
    //
    //     duration: root.open ? Motion.medium : Motion.exit(Motion.medium)
    function exit(entry: int): int {
        return Math.round(entry * Tokens.motionExitRatio);
    }

    // ── the rollout tier ────────────────────────────────────────────────
    // A rollout is not a surface arriving on top of another one: it is the
    // border BULGING, one continuous silhouette deforming. That is a different
    // event from `large`, it is slower on purpose, and it carries its own
    // curves -- which is why it gets its own names rather than reusing the
    // surface tier at a different number.
    //
    // Two tiers, and the split is size: a whole panel unrolling reads wrong at
    // the speed a popout should take, and a popout at panel speed reads as a
    // hesitation.
    readonly property int revealLarge: Style.reducedMotion ? 120 : Tokens.motionRevealLarge
    readonly property int revealSmall: Style.reducedMotion ? 120 : Tokens.motionRevealSmall
    // morphGlide -- one entry MORPHING into the next while both stay on
    // screen. Same number as revealSmall today and deliberately its own token:
    // a glide and a reveal are different events and must be retunable apart.
    readonly property int morphGlide: Style.reducedMotion ? 120 : Tokens.motionMorphGlide

    readonly property real rolloutDeformScale: Tokens.motionRolloutDeformScale
    readonly property real rolloutDeformLimit: Tokens.motionRolloutDeformLimit
    readonly property real rolloutDeformStiffness: Tokens.motionRolloutDeformStiffness
    readonly property real rolloutDeformDamping: Tokens.motionRolloutDeformDamping

    // The reveal curves are bezier control points, not durations, so they are
    // constants rather than theme tokens: a theme changes how long the border
    // takes, never what shape the deformation has.
    //
    // NO overshoot in either: overshoot makes a reveal read as a popup landing
    // on top of the shell rather than as the border itself moving. Attached
    // Rollout changes aperture depth only; a detached presentation can deform
    // without changing this curve.
    //
    // Reveal is a strong decelerate: fast out of the border, soft landing.
    readonly property var revealCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
    // Retract is a gentle accelerate-decelerate. It is NOT an exit curve: the
    // border does not leave, it returns to rest, and an exit curve there reads
    // as the surface being yanked away.
    readonly property var retractCurve: [0.3, 0.0, 0.2, 1.0, 1.0, 1.0]

    // ── loops ───────────────────────────────────────────────────────────
    // Everything above names a ONE-SHOT change: how long a thing takes to
    // arrive or to leave. A loop is a different quantity — it has a period,
    // not a duration — and reduced motion must LENGTHEN it rather than
    // shorten it. Shortening a duration calms a transition; shortening a
    // period makes a spinner whirr, which is the opposite of the request.
    //
    // spin — one full turn of an indeterminate indicator.
    readonly property int spin: Style.reducedMotion ? Tokens.motionSpin * 2 : Tokens.motionSpin
    // pulse — one breath of a placeholder or a waiting surface.
    readonly property int pulse: Style.reducedMotion ? Tokens.motionPulse * 2 : Tokens.motionPulse

    // hoverGrace — how long a rollout stays reported `keepOpen` after the
    // pointer leaves its hover area (Rollout.hoverAreas). Neither a duration
    // nor a period: it is an interaction TIMEOUT, not a visual transition, so
    // it does not shorten under Style.reducedMotion the way a duration does —
    // reduced motion asks for calmer animation, not a different dead-zone.
    readonly property int hoverGrace: Tokens.motionHoverGrace
    // hoverIntent — how long a pointer must rest on a trigger before a hover
    // popover opens, so a pointer passing through opens nothing. A timeout like
    // hoverGrace, and unshortened for the same reason.
    readonly property int hoverIntent: Tokens.motionHoverIntent
    // clockRefresh — how often a relative timestamp ("3 min ago") is redrawn.
    // A timer, not a visual change.
    readonly property int clockRefresh: Tokens.motionClockRefresh

    // Reading text that travels (Marquee): the pace is milliseconds per pixel,
    // so a long title and a short one scroll at the same reading speed, and
    // the dwell is the hold at each end. Neither follows reduced motion,
    // because a marquee does not run under it.
    readonly property int readingPace: Tokens.motionReadingPace
    readonly property int readingDwell: Tokens.motionReadingDwell

    // Enter: decelerate in, so the arrival is where the eye lands.
    readonly property int standardEasing: Easing.OutCubic
    // Enter, with more authority — a surface rather than a control.
    readonly property int emphasizedEasing: Easing.OutQuart
    // Exit: accelerate away. Using an enter curve on an exit is why a
    // disappearing thing can feel like it hesitated.
    readonly property int exitEasing: Easing.InCubic
    // Move or resize between two states that both already exist: eased at
    // both ends, because neither end is an arrival.
    readonly property int moveEasing: Easing.InOutCubic
}
