# Godot Demo

Purpose: design-validation prototype for the v2.2 demo development plan.

Implemented slice:

- A-01 to A-15 Phase A skeleton
- B-01 to B-16 minimum acceptance path: map state, routes, movement, node rumor events, plan delay report
- C-01 to C-24 P0 minimum acceptance path: true spirit and character state, sect entry, MethodCarrierItem to MethodState, active cultivation, qingling_pill ActionResourceInputBinding, ActiveResourceEffect persistence
- D-01 to D-18 P0 minimum acceptance path: SectState, Yunlu storage, request_sect_resource, unique SectContinuousActionState AI, ResourceSlotState, gather_resource, sect logs and rumors
- E-01 to E-14 minimum acceptance path: demo bottleneck, breakthrough preparation, key breakthrough item instances, attempt_breakthrough, breakthrough_chain_basic, fail tags, ledger stub, sect summary, demo summary
- X-DATA-01 to X-DATA-03 stable IDs, content directory, schema/content versions
- X-QA-01 to X-QA-03 via `tests/phase_a_self_test.gd`
- X-QA-04 via `tests/phase_b_self_test.gd`
- X-QA-05 via `tests/phase_c_self_test.gd`
- X-QA-06 via `tests/phase_d_self_test.gd`
- X-QA-07 and X-QA-08 Phase E coverage via `tests/phase_e_self_test.gd`

The demo keeps client intent, settlement, writeback, save, replay, and debug surfaces separate enough to preserve the v2.2 contract:

- UI creates/edits pending player intent.
- `SettlementService` produces `ResultPackage` data.
- `ResultPackageMerger` is the only writeback path for settlement deltas.
- `SaveManager` writes JSON saves and replay files to `runtime/`.

Useful commands:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path demo/godot
/Applications/Godot.app/Contents/MacOS/Godot --headless --path demo/godot --script res://tests/phase_a_self_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path demo/godot --script res://tests/phase_b_self_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path demo/godot --script res://tests/phase_c_self_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path demo/godot --script res://tests/phase_d_self_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path demo/godot --script res://tests/phase_e_self_test.gd
```
