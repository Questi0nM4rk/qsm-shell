## Context

The task is to repeatedly operate a desktop item and adjust its value without
losing one's place. ListRow already separates host-owned selection from activated
intent and has leading/trailing slots. Slider already provides controlled values,
arrows, wheel, actions and commit reporting. Disclosure is a heading/group, not
this row; wrapping a row in a second heading would duplicate the activation target.

## Goals / Non-Goals

**Goals:** one optional inline editor beneath a row, predictable focus round-trip,
repeatable activation, common configurable N/O slider bindings and truthful host
feedback. **Non-goals:** a new menu type, command/backend overhaul, desktop
launcher repair, nested groups, persistence, production restart, capture/audit
sweeps or automated owner acceptance.

## Decisions

1. Add `expanded: bool` and named `expandedContent` slot to ListRow; keep default
   trailing content and existing row API. The root renders the host's expanded
   state; activate reports intent and never toggles expanded or advances selection.
   Its heading remains fixed-height. Only the editor footprint is disclosed.
   Header/separator and empty slots disclose nothing. The expanded slot is not
   another activation surface: pointer input on its controls never clicks the row.
2. ListRow's plain-QML clip viewport animates its height using Motion.fast and
   moveEasing. The full content retains its natural size and fixed local origin;
   the clip reveals it below the heading rather than shrinking the slider. The
   heading's StateLayer, mark and hover target exclude the editor footprint.
   Collapse disables editor input immediately; paint can finish closing while
   the slot stays mounted, then visibility becomes false at zero height. No
   registry, SDF/shader, deformation or unload stage participates in this route.
   Geometry uses Style spacing/insets; reduced motion removes this spatial reveal.
3. Shared input facts belong in Interaction: `sliderDecreaseKey: Qt.Key_N` and
   `sliderIncreaseKey: Qt.Key_O`. Slider's `decreaseKey`/`increaseKey` default to
   those properties and can be rebound per instance; zero disables a custom key.
   Those keys use the existing stepBy route and active thumb. Arrows/Page/Home/End
   remain intact. Ctrl/Alt/Meta combinations are not eaten by custom bindings;
   shortcuts exist only in a focused slider, not globally or in search input.
   A single `keyPressed(event)` hook, like TextField's existing hook, lets the
   host claim Tab or editor exit before the Qt template handles it; unclaimed
   keys continue through the same Slider dispatcher. No per-key flags or fake
   arrow injection are introduced.
   Equal nonzero custom keys are ignored rather than choosing an arbitrary action.
   Auto-repeat nudges while held and commits once at the actual release; focus or
   availability loss clears keyboard gesture bookkeeping so no later stale commit
   occurs. The label's own action focus does not turn typing N/O into level changes.
4. The owner-review item is `workbench/compositions/menu-items.json`, visible in
   the shell provider's Compositions section. Its single `menu-items` fixture node
   hosts `MenuInteractions.qml`, a native QML assembly rather than another component
   story. This is the same provider-local fixture boundary as SoundChannel, with
   one thin CompositionNode registration and descriptor; no external harness
   changes or general-purpose builder expansion. It assembles actual
   Menu, ListRow, Slider, Switch, password TextField/Field and Checkbox rather
   without adding a new library component. ListRow's
   unit retains only its single-row variants. Menu owns stepping, skipping
   invisible/unavailable/structural/report-only rows and activation through the
   actual row function. A Grid constrained to one column or one row replaces Flow,
   whose implicit main span is only its longest wrapped line; the main axis is
   sized naturally, so
   expanded content cannot wrap into another column; natural size follows content.
   Public rowAt/rowCount let the host resolve identity without a second registry.
5. Volume's editor has no duplicate title and sits directly beneath the row's
   text column, with a half-step top clearance and reserved focus-ring space.
   Up/down from any editor call Menu.step and return to the newly selected item;
   left/right/N/O stay Slider input. Enter/Escape closes volume and preserves its
   value and identity. Tab exits volume; text editors retain normal caret/typing
   and Tab routes through their real controls. Item switches and repeated actions
   retain selection. Pointer trailing actions select their owning item but never
   trigger a duplicate row activation. Search keeps its text routes and filters
   the real menu; selected items are scrolled into view.
6. Wi-Fi secure/open networks, radio ON/OFF, paired/pairable BLE entries,
   volume/mute, rescan and read-only/unavailable entries share that menu. States
   are local fixtures only; a cancellable simulated reply demonstrates pending,
   success and failure/retry without touching hardware or storing/logging a
   password. Failure keeps the password draft; reset cancels pending replies.
   Turning off a radio closes its editor and makes dependent operations unavailable.
7. Host owns focus transitions, selected identity, expanded and value, using
   actual signals/functions. The unit reports intent and host results separately
   with real native targets and a named action dictionary. Search input in the
   example must receive N/O as text, not slider commands. Supported disabled,
   boundaries, custom bindings and empty-slot cases remain reachable. Component
   records are revised first; no new size table or color/motion token is needed.
8. Sequential implementation of this one composition, requested
   focused native-QML checks and owner handoff. Project no-TDD/no-source-shape rules
   override generic test-first skills. Only affected checks run; no structural
   baseline exists, so log the permitted gate skip without generating one.

## Risks / Trade-offs

- Collapsed content could retain invisible focus → disable the slot immediately,
  test that it cannot change value while closed and restore focus in its host.
- Row bounds could swallow slider input → put row StateLayer on the heading only
  and exercise pointer/keyboard/API on the real slotted Slider.
- Model replacement can still reset the production launcher index → do not claim
  this shell example fixes desktop behavior; consumer follow-up preserves stable
  item identity rather than restoring a stale index.
- A clip can cut focus/hover overhangs → include tokenized editor insets; review
  live geometry and the complete settled closing tail with the owner.

## References

The blueprint's 4px rhythm, semantic tokens, state completeness and purposeful
motion are retained. Caelestia `controls/StyledSlider.qml` uses a template-backed
slider; `controls/MenuItem.qml` separates an item from its clicked intent. Radix
Slider and APG Slider use arrows/Home/End; APG Disclosure uses explicit expansion
and retained trigger focus. Borrow those mechanics, not a second toggle heading
or consumer service policy. Existing Quiet Luminous typography and surface ladder
remain the design source. N/O are the owner's requested additional bindings.

## Migration Plan

Prepare shell controls and one composition first, verify only that item and wait for
owner acceptance. Desktop will then embed the same Slider and reuse existing
service functions, preserving selection across result updates. No desktop files,
runtime services, existing acceptance, commits or archives are changed here.
