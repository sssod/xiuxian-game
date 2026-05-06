# Godot Demo

Purpose: design-validation prototype for the v2.2 demo development plan.

Implemented slice:

- A-01 to A-15 Phase A skeleton
- X-DATA-01 to X-DATA-03 stable IDs, content directory, schema/content versions
- X-QA-01 to X-QA-03 via `tests/phase_a_self_test.gd`

The demo keeps client intent, settlement, writeback, save, replay, and debug surfaces separate enough to preserve the v2.2 contract:

- UI creates/edits pending player intent.
- `SettlementService` produces `ResultPackage` data.
- `ResultPackageMerger` is the only writeback path for settlement deltas.
- `SaveManager` writes JSON saves and replay files to `runtime/`.

Useful commands:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path demo/godot
/Applications/Godot.app/Contents/MacOS/Godot --headless --path demo/godot --script res://tests/phase_a_self_test.gd
```
