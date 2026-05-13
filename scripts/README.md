# Scripts

## Godot Smoke Runner

`scripts/run_godot_smoke.sh` runs the project smoke check with Godot in headless mode.

Run from the project root:

```bash
sh scripts/run_godot_smoke.sh
```

The runner resolves Godot in this order:

- `GODOT_BIN`
- `godot4`
- `godot`
- `/Applications/Godot.app/Contents/MacOS/Godot`
