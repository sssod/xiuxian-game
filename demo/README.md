# Xiuxian Demo Prototype

This directory contains isolated demo work for validating and refining the v2.2 design plan. It is not a signal that the full project has entered production implementation.

Current scope:

- Godot 4 local single-player prototype under `godot/`
- Phase A runnable skeleton: local room, turn state, lock/settle, result packages, JSON save/load, TurnReplay, and Debug panel
- Phase B-C demo loop: map/action/event path, sect entry, MethodState, active cultivation, resource input, residual effects
- Phase D demo loop: SectState, sect storage, resource request, unique sect AI continuous action, ResourceSlotState gathering, sect/world rumors

Run the current Godot demo:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path demo/godot
```

Run the headless self-tests:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path demo/godot --script res://tests/phase_a_self_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path demo/godot --script res://tests/phase_b_self_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path demo/godot --script res://tests/phase_c_self_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path demo/godot --script res://tests/phase_d_self_test.gd
```

Runtime saves and replays are written under `demo/godot/runtime/` and are ignored by git.
