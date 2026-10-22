# Backlog

Open items only. Finished work lives in git. One line per item; a line that
needs a paragraph is a design question for the owner, not a backlog entry.

## Next

- Full-library UIX audit and redesign: every one of the 52 exported types reviewed against the installed qsm-uix guidance, with per-type records carrying hitbox and pointer-path mathematics, then repairs one item at a time with owner acceptance. Orientation `docs/UIX-AUDIT.md`, plan `openspec/changes/uix-component-audit/`, tracker `qss-9zk`.
- Kbd, Capsule's detail, ColorSwatch's reading and the Slider thumb's reading still set `textXs` (10 px) directly; the token goes when the last of them does.
- Menu and MonthCalendar assign host-owned selection/month directly; these writes can replace host bindings. Source-confirmed ownership mismatch, left for each type's named repair and live review (`qss-bcn`).
- Rollout unregisters only its current host/key; changing either on a living instance can orphan the previous paint/input registration. Production reachability is unverified; settle the lifetime contract before changing the mechanism (`qss-3il`).
- Shell readiness first: close concrete component defects and keyboard/public-action
  parity through hosts; defer host-only improvements and Workbench polish unless
  they block the selected item (`GOAL.md`).
- Generic Rollout variants and live pointer/drag/focus still need the owner's
  named review; passing checks are not acceptance.
- Residual lint: NotificationCard sets layout-managed height and composition
  Loaders expose QObject-typed APIs; repair with each owning item.
- ListRow's additive headingHeight/expansionHeight contract awaits a live consumer sizing review. The owner approved shell Compositions / menu-items for that adoption.
- Rollout: generic sound-settings variants and spec completion remain open under `openspec/changes/rollout-expansion`.
- DataCapsule: a CPU/memory readout needs a composition with persistent or
  event-driven visibility and an explicit open action, without library service policy.
- Reconcile existing component acceptance evidence against the roadmap in `GOAL.md`,
  then prepare one selected item at a time; catalog/flow presence alone is
  not acceptance.
- R0: provider installs no `Style.backend`, so reduced motion defaults to false;
  add a provider-owned review environment, deferred to the first selected
  implementation item.
- NotificationCenter: live notification action targets, spoken output and
  appearance await owner review.
- R2/R3: Slider's unit does not answer label clicks; horizontal ScrollCue and long
  Kbd cases are missing from their review controls. Extend existing units with
  their owning milestone, not a new catalog or flow suite.
- R4: include startup empty/one-point Sparkline data and Divider cases;
  align Surface's focus wording with host composition. Deferred to those view reviews;
  lack of a flow for a static component is not itself a defect.
- Sibling workbench `BRIEF.md` retains mandatory tests/commits inconsistent with current
  rules. Deferred to harness docs; library roadmap and brief use the owner-led contract.
- Native simulated input is wired in a consumer's provider, not this library's
  `workbench/Adapter.qml` (no `inputDriver`/native targets). Live component demos and
  semantic actions are separate capabilities. Defer native target exposure until a
  selected library story needs it; it is not a prerequisite for a manual animation demo.
- Owner review of uncommitted component/provider changes: one item at a time,
  tests only when requested; preserve unrelated worktrees.
- Quiet Luminous review: prepare a coherent task, then owner checks pointer,
  keyboard, focus, sizes, overflow and states; fix the same item until accepted.
- `ActionTile`, `Segmented` and `ColorSwatch` fixtures need owner review of
  purpose, glyph/copy consistency and reachable supported cases before continuing.
- Provider migration and native inspection are available, but component-wide
  owner acceptance is still open; a rollout trace does not establish it.
- Popup family (`Menu`, `Popover`, `Dialog`, `ToolTip`) stays hand-rolled:
  `T.Popup` inside a `PanelWindow` paints only inside the window rect.
- Equal-recency NotificationCenter groups retain feed order;
  an alphabetical preference would need an owner decision. `Segmented`
  may want one gliding indicator instead of a fill per cell (`ui-design` and
  live judgement first); a compact CPU/memory readout is composed from
  `Stat`, `Meter` and `Prose`, never a new type.
- Types with no consumer yet: `Dialog`, `Scrim`, `Skeleton`, and `Popover`
  used as a tooltip or menu. Wait for a surface that needs them.
- Avatar's image/mask route needs a photo fixture and live review; initials
  and glyph fallback stories do not exercise image loading.

## Left standing by the owner

- `volume` glyph sits 0.68px left of its muted sibling; offset 0 chosen.
- `Popover.qml`'s comment says "held", the word rejected on `Rollout`.

## Later

- Public distribution, if requested: obtain clean-checkout evidence for the
  installed Workbench preview setup before promising an independent public package;
  not a gate for personal use.
- Workbench narrow Controls inspector can clip lower action rows; track the
  harness limit in its README;
  resume only if it blocks component work, not as a standalone polish project.
- Vertical `Divider` when a layout needs it. SVG aliases at the first naming
  conflict. A light theme after its palette is designed.

## Workbench provider milestones awaiting the owner

- Shared mock screen and bounded placement: owner judgement open.
- Real capsule composition container nodes and the real Slider sound-channel leaf: owner review open.
- Sound Compose and its migrated flows: live window evidence still missing.
- Exact live base and Compose handoff: native F11 compositor evidence still missing; not accepted.
- Neutral base control grouping: live review open.

## Owner rulings the type audit left open

- **Segmented thumb** — the selected thumb is 1.30:1 on its track
  (`opacity.selected` 0.12); raise it or add a non-colour cue.
- **Label width ceiling** — `Capsule`, `Badge`, `ControlLabel` (so `Slider` and
  `Field`) widen without limit. One width token is needed; pick the number
  against a live popout row (190 = half a control width is the candidate).
- **Hover growth of a small box** — `Checkbox` hardcodes 1.15, `Switch` 1.25,
  the library default is 1.08.
- **Host-owned state written by the component** — `Menu.currentIndex`,
  `Menu` writing row `selected`, `MonthCalendar.shown`: report `moved` /
  `monthShifted` and let the host assign; every host wires it in the same change.
- **Size presets still missing** — `ActionTile`, `StatRing`, `ColorSwatch`,
  `Avatar`, `Spinner`, `Skeleton` line box.
