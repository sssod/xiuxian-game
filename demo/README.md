# Xiuxian Demo Prototype

This directory contains isolated demo work for validating and refining the v2.2 design plan. It is not a signal that the full project has entered production implementation.

Current scope:

- Godot 4 local single-player prototype under `godot/`
- Phase A runnable skeleton: local room, turn state, lock/settle, result packages, JSON save/load, TurnReplay, and Debug panel
- JSON content fixtures prepared for later Phase B map/action/event work

Run the current Godot demo:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path demo/godot
```

Run the Phase A self-test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path demo/godot --script res://tests/phase_a_self_test.gd
```

Runtime saves and replays are written under `demo/godot/runtime/` and are ignored by git.
