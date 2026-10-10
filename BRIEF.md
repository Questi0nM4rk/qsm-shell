# Personal production readiness

Read `AGENTS.md`, then `GOAL.md` for the 31-component desktop scope, evidence,
ordered roadmap and per-component review queue. `docs/WORKBENCH_PROVIDER.md`
defines the provider boundary; `docs/BACKLOG.md` holds remaining open work.

Prepare one owner-selected item from that roadmap. Production components live
in `qml/QsmShell/`; their real state-hosting examples belong in
`workbench/units/` and provider compositions. The sibling workbench owns the
window, generic inspection, native input driver and flow engine. Desktop
services, persistence and compositor policy remain in `qsm-desktop`.

Trace the component through its actual desktop consumer before changing its
contract. Preserve dirty work and existing acceptance evidence. Report source
review, requested runtime evidence and owner acceptance separately. Wait for
feedback on the selected item; do not advance automatically.

Tests, validation, captures and desktop operation require an explicit request.
Use workspace 10 only when asked to operate. Follow the owner's current model
and delegation choices. No commits, pushes or review-window restarts without
instruction.
