# Input Parameters

This document summarizes the public inputs and options for `MBESO2D` version `1.0.0`.

## Function Syntax

```matlab
result = mbeso(nelx, nely, volfrac, er, options)
result = mbeso_fixed_solid(nelx, nely, volfrac, er, options)
```

`options` is optional. If omitted or empty, each solver uses its defaults.

## Required Arguments

| Argument | Type | Description |
| --- | --- | --- |
| `nelx` | positive integer | Number of elements along x. |
| `nely` | positive integer | Number of elements along y. |
| `volfrac` | scalar | Target final solid volume fraction. |
| `er` | scalar | Evolution rate used in the BESO volume update. |
| `options` | struct | Optional settings. |

## Common Options

| Option | Default | Description |
| --- | --- | --- |
| `materials` | default material struct | Material constants. |
| `bc_case` | `'cantilever'` | Boundary/load case. |
| `bc_load` | `1000` | Load magnitude. |
| `tension_eta_mode` | `'with_nk'` | Tension utilization rule; also accepts `'without_nk'`. |
| `penal` | `3.0` | Density penalization exponent. |
| `tau` | solver-specific | Relative objective-function change tolerance. |
| `xmin` | `1e-3` | Minimum density for void elements. |
| `r1_mm` | solver-specific | Filter radius for stress-state field. |
| `r2_mm` | solver-specific | Filter radius for utilization field. |
| `structure_width` | `1000` | Physical width. |
| `structure_height` | `600` | Physical height. |
| `structure_dimension_unit` | `'mm'` | Unit for physical dimensions: `'mm'`, `'cm'`, or `'m'`. |
| `out_of_plane_thickness_m` | `1e-3` (both solvers) | Plane-stress thickness in meters. The default is 1 mm; it scales element stiffness and, for self-weight analysis, element mass. |
| `verbose` | `true` | Print iteration log to the command window. |
| `designMask` | all true | Logical active design-domain mask. Alias: `design_mask`. |
| `even_keep_count` | solver-specific | Adjust an odd keep count to an even count without enforcing mirror pairs. |

The physical element size is resolved from `structure_width / nelx` and `structure_height / nely`; square elements are required.

## Iteration Options

| Solver | Option | Default | Notes |
| --- | --- | --- | --- |
| Both solvers | `max_iterations` | `1000` | Safety stop. Alias: `iteration_limit`. |
| `mbeso` | `force_iteration_limit` | `false` | If true, continue to `max_iterations` even after the normal convergence condition is met. |

For both solvers, `result.converged` is true only when the target volume has been reached and `change <= tau`. Reaching `max_iterations` records `termination_reason = 'max_iterations'`.

## Output Options

| Option | Default | Solver | Description |
| --- | --- | --- | --- |
| `write_run_report` | `false` | `mbeso` | Write a text run report when enabled. Example scripts enable it. |
| `write_run_report` | `true` | `mbeso_fixed_solid` | Write a text run report by default. |
| `run_report_file` | `''` | all | Optional explicit report path. |
| `save_result` | `true` | `mbeso_fixed_solid` | Save the returned `result` struct to a MAT file. |
| `result_file` | `''` | `mbeso_fixed_solid` | Optional explicit MAT-file path. |
| `plotting` | `true` | all | Update the solver's live material-layout figure. |

Default output paths:

```text
results/mbeso_run_report_YYYYMMDD_HHMMSS.txt
results/mbeso_fixed_solid_run_report_YYYYMMDD_HHMMSS.txt
results/mbeso_fixed_solid_result_YYYYMMDD_HHMMSS.mat
```

## Fixed-Solid and Non-Design Options

`mbeso_fixed_solid` adds:

| Option | Default | Description |
| --- | --- | --- |
| `fixed_solid_mask` | all false | Logical mask for elements that remain solid. Alias: `fixedSolidMask`. |
| `non_design_mask` | all false, plus elements outside `designMask` | Logical forced-void mask. Aliases: `nonDesignMask`, `non_design_domain_mask`. |

`non_design_mask` must not overlap `fixed_solid_mask`. The resolved non-design mask is stored in `result.settings.non_design_mask`.

## Material Properties and Units

| Field | Default | Unit | Description |
| --- | ---: | --- | --- |
| `E1` | `200000` | MPa | Young's modulus of material 1. |
| `nu1` | `0.3` | - | Poisson's ratio of material 1. |
| `sigma_m1` | `250` | MPa | Allowable stress of material 1. |
| `E2` | `20000` | MPa | Young's modulus of material 2 and reference modulus for ersatz void. |
| `nu2` | `0.3` | - | Poisson's ratio of material 2. |
| `sigma_m2` | `50` | MPa | Allowable stress of material 2. |
| `nu3` | `0.3` | - | Poisson's ratio used for ersatz void. |
| `rho1` | `7.8e3` | kg/m^3 | Density of material 1 in `mbeso_fixed_solid`. |
| `rho2` | `2.4e3` | kg/m^3 | Density of material 2 in `mbeso_fixed_solid`. |
| `rho0` | `0` | kg/m^3 | Density assigned to void; the current implementation gives void no self-weight. |

Elastic moduli and stresses use the internal N-mm-MPa system. Physical area and
thickness are converted to m^2 and m only for the mass calculation. The same
`out_of_plane_thickness_m` is converted to millimeters before multiplying the
plane-stress element stiffness matrix.

## Deck Line Load and Self-Weight

The following options are available in `mbeso_fixed_solid`:

| Option | Default | Description |
| --- | --- | --- |
| `deck_line_load_N_per_m` | `[]` | Nonnegative line-load magnitude `q` in N/m. When empty, the legacy `bc_load` value is applied at every deck node. |
| `deck_load_sign` | `1` | Algebraic sign applied to the deck load. The public examples use the solver's positive vertical direction for downward loading. |
| `deck_load_distribution` | `'consistent'` | `'consistent'` or `'equal_nodes'`; used only when `deck_line_load_N_per_m` is specified. |
| `deck_load_node_row` | case-specific | One-based node-row index on which the deck load is applied. |
| `include_self_weight` | `false` | Add material-dependent gravitational load when true. |
| `gravity` | `9.81` | Gravitational acceleration in m/s^2. |
| `gravity_load_sign` | `deck_load_sign` | Algebraic sign of self-weight. |

For span `L`, both line-load distributions preserve the total force `qL`:

- `'consistent'`: each interior node receives `q * element_length` and each end node receives half that value.
- `'equal_nodes'`: all `nelx + 1` loaded nodes receive `qL / (nelx + 1)`.

For each solid element, self-weight is computed as

```text
element_mass   = density * element_area * out_of_plane_thickness
element_weight = gravity_load_sign * element_mass * gravity
```

One quarter of the element weight is assembled at each of its four vertical
nodal degrees of freedom. Material 1 and material 2 use `rho1` and `rho2`,
respectively; void uses `rho0 = 0` in the public examples.

The public bridge examples specify `out_of_plane_thickness_m = 1`, so the 2D
domain represents a one-meter out-of-plane strip. The cantilever example
explicitly specifies `1e-3` m (1 mm) to reproduce the unit-thickness
convention used for its N-mm-MPa model.

## Fixed-Layout Analysis Options

`mbeso_fixed_solid` can evaluate a supplied layout without topology updates:

| Option | Default | Description |
| --- | --- | --- |
| `analysis_only` | `false` | Evaluate the supplied layout once and return its response. |
| `initial_mi_map` | `[]` | Required in analysis-only mode; `[nely, nelx]` material IDs `0`, `1`, or `2`. |
| `initial_x` | `[]` | Optional density field consistent with `initial_mi_map`; otherwise reconstructed from the material IDs. |
| `layout_source` | `''` | Optional descriptive source string stored in `result.settings`. |

These fields are solver inputs only; the public release does not bundle an
Abaqus importer or a manuscript-layout reconstruction utility.

## Boundary Cases

Supported by `mbeso`:

| Case | Description |
| --- | --- |
| `'cantilever'` | Left edge fixed, load at the lower-right corner node. |

Supported by `mbeso_fixed_solid`:

| Case | Description |
| --- | --- |
| `'cantilever'` | Compact cantilever pattern. |
| `'run_case_3a'` | Case III(a): lower retained deck; load on its upper surface and supports on the lower boundary. |
| `'run_case_3b'` | Case III(b): upper retained deck; load and supports on the upper boundary. |

## Output Structure

| Field | Description |
| --- | --- |
| `result.x` | Final density field. |
| `result.mi_map` | Final material map: `0` void, `1` material 1, `2` material 2. |
| `result.history` | Iteration histories. |
| `result.iterations` | Number of completed iterations. |
| `result.compliance` | Final objective function value. |
| `result.response` | Final displacement, stress, utilization, and objective function fields. |
| `result.materials` | Material properties. |
| `result.settings` | Resolved settings and masks. |
| `result.converged` | Convergence flag. |
| `result.termination_reason` | Termination reason. |
| `result.report_file` | Text report path, if written. |
| `result.result_file` | MAT-file path, if saved. |
