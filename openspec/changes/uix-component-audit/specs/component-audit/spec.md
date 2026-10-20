## ADDED Requirements

### Requirement: Complete per-type audit records

The audit SHALL reconcile exported types, units, alias stories and component records. Every type
SHALL have a linked `docs/components/<Type>.md` record describing purpose and consequence, expected
public controls, valid states, input and accessibility routes, size and overflow, visual roles,
motion, findings and evidence. Proposed behavior SHALL be distinguished from implemented behavior.

#### Scenario: Several stories use one type

- **WHEN** horizontal and vertical slider stories resolve to the same exported type
- **THEN** the index SHALL link both from one Slider record and SHALL NOT count them as two types

#### Scenario: A noninteractive type is reviewed

- **WHEN** a type has no pointer action
- **THEN** its record SHALL explain that pointer acquisition is not applicable and SHALL still
  review its actual visual, content and accessibility role

### Requirement: Reproducible hitbox mathematics

Each interactive target SHALL record its actual input shape separately from painted/layout bounds,
coordinate space, transforms, clipping, relevant scale, representative approach assumptions,
distance, width model and target difficulty. It SHALL record landing tolerance and competing
targets. Hover surfaces SHALL additionally record trigger-panel corridor continuity and timing.
Synthetic trajectory results SHALL NOT be presented as average human behavior or predicted time
without owner-specific empirical calibration.

#### Scenario: A glyph has a larger input target

- **WHEN** a glyph is smaller than its control's hit region
- **THEN** acquisition calculations SHALL use the reachable input region and SHALL separately show
  painted size, clipping and any neighbouring input interference

#### Scenario: A popup can close during travel

- **WHEN** the owner moves from its trigger toward the popup along a modelled diagonal path
- **THEN** the record SHALL state path coordinates, clearance or gap and timing assumptions, and
  SHALL distinguish computed geometry from a runtime-traced keep-open result

#### Scenario: No human movement sample exists

- **WHEN** the audit has synthetic paths and geometry but no real user sample
- **THEN** it SHALL label origins and weights as model assumptions and SHALL NOT claim a human
  average movement time, error rate or probability

### Requirement: Evidence is separate from acceptance

Each record and the coverage index SHALL separately state source-reviewed, runtime-exercised and
owner-accepted. Runtime findings SHALL cite an actual exercised state, route and artefact. Missing
native routes, transparent captures, unsupported accessibility evidence and compositor-only
behavior SHALL remain explicit gaps. Shared methodology SHALL live once in `docs/USAGE.md`.

#### Scenario: A semantic action succeeds without a native target

- **WHEN** a story exposes activate but does not expose a native input target
- **THEN** the audit SHALL NOT mark pointer delivery, hit testing or keyboard focus as exercised

#### Scenario: A general rule conflicts with a local design law

- **WHEN** UIX recommends an overlay shadow and the current project rule forbids it
- **THEN** the record SHALL name the source conflict and proposed decision, without declaring the
  existing visual design owner-accepted or silently editing it during the audit

### Requirement: Audit precedes owner-led repairs

This change SHALL complete the full library audit before component repairs. The owner permits a
full redesign including silhouette changes. Repairs SHALL use separate scoped changes and owner
acceptance per item. Desktop integration SHALL follow the library phase. Workbench changes SHALL
remain separate and limited to evidence blockers. No eval, production restart, service mutation,
user telemetry or OS-pointer input SHALL be implied by audit execution.

#### Scenario: An audit reveals a component defect

- **WHEN** a confirmed defect is recorded before the complete audit is delivered
- **THEN** it SHALL remain a finding for the repair phase rather than becoming an automatic code edit
