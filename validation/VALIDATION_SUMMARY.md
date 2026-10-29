# MBESO2D validation and revised-manuscript evidence

This guide follows the submitted revision checked on 29 October 2026. These manuscript-review
changes do not constitute a new tagged public software version.
See [the reproduction guide](../docs/manuscript_reproduction.md) for complete commands.

The public-main candidate passed small-model solver smoke tests, material-palette
and assigned-material utilization checks, 81 native figure checks, and the
Table 8/9 reconstruction in MATLAB R2024b. These tests include small FE and
optimization cases; they do not rerun the full study or Abaqus analyses.
No native R2023a execution is claimed. The numerical checks and their scope are
recorded in [the validation record](submission_alignment_checks_20261029.json).

## Evidence and executable entry points

| Manuscript item | Evidence / entry point |
| --- | --- |
| Table 3: equations and code | [Equation-code map](../docs/equation_code_map.md), current commented `src/mbeso.m` |
| Sections 3.1/3.3: baseline results | `run_regression_checks.m`, `assigned_material_baselines.csv` |
| Section 3.2, Table 6: three meshes | `run_mesh_independence.m`, `mesh_independence_reference.csv` |
| Figure 6: baseline history and first ten updates | `../reproduction/RUN_MANUSCRIPT_FIGURES.m`; fresh `review/run_review_experiments('initial10',outputRoot)` |
| Figure 7: baseline fractions/transitions and deadband comparison through 214 | Figure replay; fresh `review/run_review_experiments('histories',outputRoot)` |
| Table 9: baseline + 16 variants (17 rows) | `manuscript_tables/RUN_SUBMISSION_TABLES.m`; fresh `review/run_review_experiments('sensitivity',outputRoot)` |
| Figure 5 / Table 8: Abaqus cross-check | `abaqus_crosscheck.csv`; current table wrapper; supplied manuscript images; Abaqus jobs are not bundled |
| Historical bridge equilibrium/energy and C/2C table | `../reproduction/RUN_LEGACY_20261024_FIGURES.m`; `manuscript_tables/RUN_MANUSCRIPT_TABLES.m`; fresh `bridge_energy` mode |

Saved-data replay does not rerun optimization. The isolated research engine under
`review/` performs new optimizations and records the full fields required to build
new figures. Its baseline behavior is compared against the public solvers; it is
not represented as an identical copy of the public source. See its README for
runtime, memory, verification, and licensing information.

## Reported quantities

The reported `C = 0.5 F^T U = 0.5 U^T K U` is strain energy for a fixed linear
elastic model with the stated boundary conditions. It is not the element-ranking
score. The stopping rule uses its relative change.

Reported utilization is calculated inside the **actually assigned** material:
`100 * VM / 250 MPa` for M1 and `100 * VM / 50 MPa` for M2 in these benchmarks.
Each material's maximum is nonnegative. A signed contour uses + for M1 and - for
M2 only for display. It is distinct from the stress-sign-based score used during
optimization. Centroidal VM over all solid elements is used for final comparisons.

| Case | Updates | C (N·mm) | M1 / M2 elements | Maximum VM (MPa) | M1 maximum (%) | M2 maximum (%) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| I(b) | 214 | 574.783606044 | 549 / 1851 | 128.907505 | 51.563002 | 59.785048 |
| III(a) | 95 | 2552153826.2 | 1884 / 8356 | 136.992486 | 21.596183 | 273.984973 |
| III(b) | 93 | 1675156216.16 | 2318 / 7922 | 137.414343 | 54.965737 | 33.674359 |

`assigned_material_baselines.csv` preserves unrounded values and provenance.
`reference_results.csv` deliberately retains the original solver-output regression
contract, including the stress-sign-based utilization extrema (-66.667% and
-70.894% for two cases). Those columns are not the current assigned-material
reporting metric. `tests/test_assigned_material_utilization.m` checks that metric
separately. Older summary CSVs are preserved under `legacy_20260826/`.

## What the comparisons establish

- Public regression checks compare convergence, iterations, material counts and
  response values with the frozen release baseline. Relative scalar tolerance is
  `1e-8`; discrete counts must agree exactly. Sparse-solver/platform differences
  must be reported rather than silently replacing reference data.
- The historical C/2C table compares current values with literature numbers conditionally. The
  reference compliance definition is unconfirmed. Neither a reporting multiplier
  nor a unit conversion establishes that the reference model has been reproduced.
- Table 9 compares each run at its own stopping point. Gauss-mean, Gauss-maximum,
  and r2 = 20 mm reach the 1,000-update cap. They must not be labelled converged.
- Figure 7 compares deadband histories through iteration 214. Transition
  totals use updates 1–214, including the initial-to-first-update comparison. Layout differences
  use state 214, with all 6,000 elements as the occupancy denominator and
  common solids as the material-assignment denominator. The effect on
  switching is nonmonotonic. Runs terminating earlier retain their histories
  when continued to this common endpoint; Table 9 uses each run's own
  termination or iteration cap. The former 50-update continuation figure is
  outside the final manuscript scope.
- Small-model checks and final-state audits do not establish accuracy at every
  intermediate state. The previously observed 11 of 20 intermediate bridge
  criteria exceedances remain part of the research record. This compact package
  does not claim to resolve them or the large bridge-to-reference C discrepancies.

## Mesh consistency and external FE evidence

The fixed `40 x 40 mm` evaluation regions are used **only in Section 3.2**. They
change the extrema evaluation set, not the FE mesh, loads, or optimization. They
are not evidence that all singularity effects have been removed. For meshes
50 x 30, 100 x 60 and 200 x 120 they cover 2 x 2, 4 x 4 and 8 x 8 elements at
each designated corner. Actual represented sizes are recorded by the code.

The Abaqus CSV is documentary evidence for matched final layouts, not a runnable
Abaqus workflow. Abaqus jobs/databases are not bundled. Rounded agreement alone
cannot prove a numerical error bound below the rounding resolution. The FE
comparison also does not validate the material-update algorithm by itself.

## Figures, source data and archive policy

The current submitted graph package is under
`reproduction/submission_20261029/`. Eight numerical graphs cover Figures
6(a,c,d) and 7(a–e); Figure 6(b) combines assignment and location artwork.
The per-update and cumulative transition plots include update 1. For the
baseline this changes the cumulative scope from the historical 3,286 TC /
5,140 SV over 2–214 to 5,725 TC / 5,200 SV over 1–214. The initial state
remains a source record for this calculation.

The 20 and 23 October galleries under `docs/assets/` preserve earlier
artwork, previews and numbering. Historical PNGs under `validation/figures/`
may also use an earlier utilization definition. They remain provenance
records rather than current figure-number specifications. The explicit
legacy replay preserves the former bridge force/energy graphs and the
earlier Figure 8/9 numerical panels.

Compact replay MATs are intentionally tracked using narrow `.gitignore`
exceptions. Fresh full histories, exported figures and large FE arrays belong in
ignored `results/` folders. Reference numbers retain their sources; the original
Li-Xie code and complete original element maps are not available here.

Reference environment: MATLAB R2024b, Windows 64-bit, base MATLAB, sparse
double-precision FE solves. No additional toolbox is required for the public
reproduction entry points.
