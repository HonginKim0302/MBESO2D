# Algorithm Overview

`MBESO2D` implements a two-dimensional stress-based multi-material BESO loop on a structured quadrilateral finite-element mesh. The code is organized as compact MATLAB solvers plus separate visualization, example, validation, and documentation folders.

## Main Workflow

1. Read user inputs and options.
2. Resolve physical dimensions and filter radii.
3. Build thickness-scaled element stiffness matrices, constitutive matrices, loads, fixed degrees of freedom, and sparse filter matrices.
4. Initialize the density field `x`, material map `mi_map`, utilization field `eta`, and iteration histories.
5. Run the MBESO loop:
   - assemble the prescribed load and, when enabled, current-layout self-weight,
   - solve the finite-element equilibrium equation,
   - recover principal and von Mises stresses,
   - compute the objective function and sensitivity-like quantities,
   - compute material utilization and stress-state fields,
   - apply spatial filters,
   - select solid elements from utilization ranking and target volume,
   - update solid/void density and material IDs,
   - record history and optionally update a live plot.
6. Assemble the final response from the cached final-layout FE analysis.
7. Return the `result` structure and optionally write reports/result files.

## Solver Roles

| Solver | Role |
| --- | --- |
| `src/mbeso.m` | Compact reference 2D implementation for the cantilever case. |
| `src/mbeso_fixed_solid.m` | Extended monolithic solver for retained-solid and forced-void non-design masks. |

The repository currently uses monolithic solver files rather than separate package modules. This keeps the implementation easy to inspect and consistent with compact MATLAB topology-optimization code style.

## Core Numerical Blocks

| Block | Representative local routines | Numerical role |
| --- | --- | --- |
| Entry/options | solver entry point, `get_option` | Parse options and resolved settings. |
| FE preparation | `lk`, `B0`, `compute_D_matrix`, `prepare_fem`, `get_boundary_conditions` | Element stiffness, strain-displacement matrix, constitutive matrix, DOF map, loads, and supports. |
| Physical loads | `make_deck_node_load`, `current_load_vector` | Line-load discretization and material-dependent self-weight from density, element area, thickness, and gravity. |
| Filtering | `prepare_filter`, `apply_filter` | Sparse spatial filters for stress-state and utilization fields. |
| FE analysis | `FE_vectorized`, `FE_displacement` | Assemble global stiffness, solve displacements, recover stress fields. |
| Objective/response | `element_compliance`, `compute_load_case_compliance` | Objective function and response evaluation. |
| Utilization | `update_material_utilization` | Compute stress-based utilization and `n_k` correction. |
| Topology update | `select_keep_mask` | Select solid elements from filtered utilization ranking and target volume. |
| Material update | inline `mi_map` assignment | Assign material IDs from filtered principal-stress sum sign. |
| Output | `evaluate_design_response`, `mbeso_write_run_report`, visualization functions | Final response, reports, figures, and saved MAT results. |

The objective reported as compliance by this project is
`0.5 * U' * K * U`, evaluated for the governing load case. This definition is
used consistently in histories, run reports, and validation baselines.

## Design Masks

`designMask` defines elements that can participate in the topology update. In `mbeso_fixed_solid`, `fixed_solid_mask` forces retained solid elements and `non_design_mask` forces void elements outside the active design domain. The resolved mask is stored in `result.settings.non_design_mask`.

## Convergence and Stops

Both solvers use `max_iterations` as a safety stop and record convergence based on target volume and relative compliance-change tolerance. The output fields `result.converged` and `result.termination_reason` summarize the final state.

## Output Management

The solvers return the full `result` structure. Text reports are written by `visualization/mbeso_write_run_report.m` when enabled. `mbeso_fixed_solid` also saves the `result` structure to `results/mbeso_fixed_solid_result_*.mat` by default, unless `options.save_result = false`.

## Implementation Provenance

The multi-material utilization and reassignment scheme follows Li and Xie
(2021), and the soft-kill BESO framework follows Huang and Xie (2010). Compact
finite-element implementation patterns were adapted from the MIT-licensed
NewBESO code. See `THIRD_PARTY_NOTICE.md` for the exact source mapping,
upstream revision, and preserved license notice.
