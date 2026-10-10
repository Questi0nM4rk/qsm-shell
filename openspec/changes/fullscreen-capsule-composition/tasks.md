## 1. Environment and general base

- [x] 1.1 SH-C1: Forward previewEnvironment through the shell adapter/scene without changing unit behavior. Contract: `.codeagent/backlog/task/SH-C1.yaml`.
- [x] 1.2 SH-C2: Add the shared mock screen and bounded placement rule. Contract: `.codeagent/backlog/task/SH-C2.yaml`.
- [x] 1.3 SH-C3: Replace the sound-specific DataCapsule unit with the neutral base and its focused base flow. Contract: `.codeagent/backlog/task/SH-C3.yaml`.

## 2. Actual slot composition

- [x] 2.1 SH-C4: Add descriptor/runtime mock-screen and data-capsule container nodes with registered real slot children. Contract: `.codeagent/backlog/task/SH-C4.yaml`.
- [x] 2.2 SH-C5: Add the provider-owned real Slider sound-channel leaf with truthful local level/mute routes. Contract: `.codeagent/backlog/task/SH-C5.yaml`.
- [x] 2.3 SH-C6: Add the sound Compose starter and migrate sound flows to node-addressed composition checks. Contract: `.codeagent/backlog/task/SH-C6.yaml`.

## 3. Verified preparation

- [x] 3.0 SH-C8: Separate the neutral base's independent control axes and migrate exact base-flow names after WB-E7. Contract: `.codeagent/backlog/task/SH-C8.yaml`.

- [x] 3.1 SH-C7: Open and verify the exact sound Compose in the shell provider on workspace 10, stop input and hand the named item to the owner. Contract: `.codeagent/backlog/task/SH-C7.yaml`.

Every checkbox is one bounded dispatch defined by its YAML contract.
Execution strategy: B, sequential one-task workers with owner-review checkpoints.
The contract CLI is unavailable; structured worker reports are checked against
the task YAML and actual changes. Dependency handoff uses reviewed verification
evidence while YAML `done` is withheld until an authorized commit.

Dependencies
include the sibling workbench's WB-E tasks; the orchestrator checks them in that
repository and does not silently redefine the interface in a shell task. All tasks
are sequential. The main agent owns docs/spec changes and design deviations.

If a fixture discovers a component defect, stop that task and define a separate
owning-component fix; do not work around it or claim acceptance from tests.
Only `file_boundaries.exclusive` permits writes; unlisted implementation files
need a revised contract before editing. Forbidden means no read or write, so no
forbidden parent may overlap readonly/exclusive paths. SH-C3 and WB-E6 prepare the
neutral base; SH-C4 is blocked until the owner accepts that named item. SH-C7 then
hands over sound Compose separately. No automatic progression during owner review.
Without an authorized commit, report implemented/verified evidence rather than
YAML `done`; never fabricate commit hashes. Current scope ends at these prepared
items, not production release.
