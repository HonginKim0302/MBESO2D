# Algorithm Overview

`MBESO2D` implements a two-dimensional stress-based multi-material BESO loop on a structured quadrilateral finite-element mesh. The repository contains compact MATLAB solvers and separate folders for visualization, examples, validation, and documentation.

## Main Workflow

1. Read user inputs and options.
2. Resolve physical dimensions and filter radii.
3. Build thickness-scaled element stiffness matrices, constitutive matrices, loads, fixed degrees of freedom, and sparse filter matrices.
4. Initialize the density field `x`, material map `mi_map`, utilization field `eta`, and iteration histories.
5. Analyze the initial layout once, then run each design update:
   - use the cached FE response of the input layout to obtain the unfiltered principal-stress sum and utilization selection score,
   - spatially filter the stress sum with `H1` and the selection score with `H2`,
   - average the current and preceding spatial score outputs (use the current output alone on the first update),
   - reduce the scheduled volume and retain the highest history-averaged scores,
   - assign M1 to solids with nonnegative filtered stress sum and M2 to the remaining solids,
   - reassemble stiffness and, when enabled, self-weight for the updated layout, then solve and recover its response,
   - check the updated response and actual solid fraction, record that same state, and optionally update the live plot,
   - cache the updated FE solution for the next update.
6. Assemble the final response from the cached final-layout FE analysis.
7. Return the `result` structure and optionally write reports and result files.

## Solver Roles

| Solver | Role |
| --- | --- |
| `src/mbeso.m` | Compact reference 2D implementation for the cantilever case. |
| `src/mbeso_fixed_solid.m` | Extended monolithic solver for retained-solid and forced-void non-design masks. |

The monolithic solver files keep the numerical workflow in a single source file for each solver, consistent with the compact MATLAB style used in topology optimization.

## Core Numerical Blocks

| Block | Representative local routines | Numerical role |
| --- | --- | --- |
| Entry/options | solver entry point, `get_option` | Parse options and resolved settings. |
| FE preparation | `lk`, `B0`, `compute_D_matrix`, `prepare_fem`, `get_boundary_conditions` | Element stiffness, strain-displacement matrix, constitutive matrix, DOF map, loads, and supports. |
| Physical loads | `make_deck_node_load`, `current_load_vector` | Line-load discretization and material-dependent self-weight from density, element area, thickness, and gravity. |
| Filtering | `prepare_filter`, `apply_filter` | Sparse spatial filters for stress-state and utilization fields. |
| FE analysis | `FE_vectorized`, `FE_displacement` | Assemble global stiffness, solve displacements, recover stress fields. |
| Energy/response | `element_compliance`, `compute_load_case_compliance` | Strain-energy response and stopping metric; it is not the element-selection score. |
| Selection score | `update_material_utilization` | Compute stress-state-based utilization and the capped `n_k` correction. |
| Topology update | `select_keep_mask` | Select solid elements from history-averaged utilization ranking and target volume. |
| Material update | inline `mi_map` assignment | Assign material IDs from filtered principal-stress sum sign. |
| Output | `build_design_response_from_analysis`, `mbeso_write_run_report`, visualization functions | Assemble the cached final response, reports, figures, and saved MAT results. `evaluate_design_response` is the fixed-layout analysis entry in the extended solver. |

The response reported as compliance in this software is
`0.5 * U' * K * U = 0.5 * F' * U`, in N*mm. It is strain energy, while the
unhalved external work is twice this value. The manuscript examples use one
combined load vector (deck load plus current self-weight for the bridges).
When the extended solver receives several load-case columns, its reported
compliance sums their strain energies; `load_case_compliance` contains the
individual values. `response.U` selects the largest-energy case for output,
whereas `response.U_all` retains all cases. The selected displacement column
does not change the summed compliance definition.

## Reading the update rules

- `x = 1` denotes solid and `x = xmin` denotes ersatz void. Material IDs
  `mi_map = 1, 2, 0` denote M1, M2 and void, respectively.
- Stress recovery uses the Q4 center-point matrix `B0`. `sigma_e = sig1 + sig2`
  is computed before filtering. It selects the denominator of the internal
  score `eta`; the assigned material ID does not select that denominator.
- `n_k` starts at one, increases geometrically during updates, and is capped
  by `sigma_m1/sigma_m2`. Final response assembly passes iteration zero, so it
  does not advance this coefficient again.
- The two spatial filters include both solid and void elements. Row-sum
  normalization preserves a constant field at mesh boundaries.
- `eta_filtered_history` averages two consecutive spatial outputs, not a
  recursively averaged history. Only the score has this temporal averaging;
  the stress sum receives spatial filtering alone.
- `select_keep_mask` floors the whole-domain scheduled count. Ties follow
  the ascending MATLAB element index. The optional even-count adjustment
  changes the count by one and does not impose mirror symmetry.
- Baseline material assignment has no deadband: a filtered stress sum of
  exactly zero assigns M1. Deadband experiments in `validation/experiments/`
  are explicit variants of this baseline rule.
- Reported material utilization is a separate postprocessing quantity:
  `100*sigvm/sigma_m1` on assigned M1 elements and `100*sigvm/sigma_m2` on
  assigned M2 elements. Material-wise maxima are nonnegative. Display signs
  distinguish assigned materials; they do not modify the selection score.

## Manuscript equation-to-code map

[equation_code_map.md](equation_code_map.md) reproduces the current Table 3
mapping with stable function/variable anchors and current line ranges.
[equation_code_map.csv](equation_code_map.csv) supplies the same rows in
machine-readable form. Line numbers refer to the annotated `src/mbeso.m`
snapshot identified in that map; adding comments later requires updating
the line ranges, even when executable statements remain unchanged.

## Design Masks

`designMask` defines elements that can participate in the topology update. In `mbeso_fixed_solid`, `fixed_solid_mask` forces retained solid elements and `non_design_mask` forces void elements outside the active design domain. Retained elements count toward the volume target and can still change between M1 and M2. The resolved mask is stored in `result.settings.non_design_mask`.

`make_deck_node_load` preserves the resultant `q*L` in both supported modes:
`equal_nodes` divides it equally among all deck nodes; `consistent` sums
element-edge contributions, giving half-sized endpoint forces. The bridge
baseline examples explicitly select `equal_nodes`. `current_load_vector`
recalculates each solid element's weight from its assigned density, area and
thickness, and contributes one quarter to each of its four nodes. Void mass
is zero. This update occurs in both initial and updated-layout FE analyses.

## Convergence and Stops

Both solvers use `max_iterations` as a safety stop (`iteration_limit` is an
accepted alias). After the first ten updates, response stopping uses
`abs(C_k-C_previous)/max(abs(C_k),1e-12) <= tau`, together with the actual
solid fraction being at most `volfrac + 1/N`. The output fields
`result.converged` and `result.termination_reason` summarize this test.
They do not assert that the layout or material assignments stopped changing.
The standard solver also supports `force_iteration_limit` for a fixed
iteration budget, such as the mesh-consistency comparison.

## Output Management

The solvers return the full `result` structure. Text reports are written by `visualization/mbeso_write_run_report.m` when enabled. `mbeso_fixed_solid` also saves the `result` structure to `results/mbeso_fixed_solid_result_*.mat` by default, unless `options.save_result = false`.

## Implementation Provenance

The multi-material utilization and reassignment scheme follows Li and Xie
(2021), and the soft-kill BESO framework follows Huang and Xie (2010). Compact
finite-element implementation patterns were adapted from the MIT-licensed
NewBESO code. See `THIRD_PARTY_NOTICE.md` for the exact source mapping,
upstream revision, and preserved license notice.
