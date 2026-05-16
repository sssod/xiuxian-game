# Numeric Tuning Tools

This directory contains numeric modeling and tuning aids for the xiuxian MVP. These files are development and validation assets, not formal design authority.

The formal numeric design source of truth remains `../xiuxian_design_docs/03_数值设计/`, especially:

- `01_修为境界与期望游玩时间建模.md`
- `02_修炼公式与数值设计.md`
- `08_数值验算.md`
- `10_时间速度与局部时间域数值设计.md`

Use the HTML tuner to test parameter sensitivity, derive reference values, export JSON snapshots, and identify conflicts. If a tuning result becomes an accepted gameplay or numeric decision, restate it in the relevant formal design document before implementation depends on it.

## Files

- `02_数学模型与HTML调参器关联_v1_5.md`: field mapping, formulas, constraints, and the relationship between the tuner and formal numeric docs.
- `修为时间数学模型_html调参器_v_0_1.html`: local browser-based tuning tool for the v1.5 cultivation-time model.

## Current Limits

- Default real-time reference baseline: 32 hours.
- Debug real-time upper bound: 50 hours.
- Accepted current outer-world baseline: about 47.55 years.
- Normal outer-world acceptance upper bound: 50 years.
- Debug outer-world hard limit: 100 years.
- F1 visible speed tuning range: 1 to 2 seconds per outer-world day, with 1.5 seconds as the default baseline.
