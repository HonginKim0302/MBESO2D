# Validation evidence

This directory contains benchmark references, numerical verification experiments
and the sources for Tables 8 and 9. Figure construction and numerical replay
are described in [the reproduction guide](../docs/manuscript_reproduction.md).

| Manuscript item | Entry point or evidence |
| --- | --- |
| Table 3: equations and implementation | [Equation-code map](../docs/equation_code_map.md) and `src/mbeso.m` |
| Sections 3.1 and 3.3: benchmark responses | `run_regression_checks.m`, `assigned_material_baselines.csv` |
| Section 3.2 and Table 6: three meshes | `run_mesh_independence.m`, `mesh_independence_reference.csv` |
| Figure 5 and Table 8: external FE comparison | `abaqus_crosscheck.csv` and `manuscript_tables/RUN_MANUSCRIPT_TABLES.m` |
| Figure 6: baseline history and first ten updates | `reproduction/RUN_MANUSCRIPT_FIGURES.m`; experiment modes `initial10` and `histories` |
| Figure 7: fractions, transitions and deadbands through 214 | Figure replay and experiment mode `histories` |
| Table 9: baseline and 16 one-factor variants | `manuscript_tables/RUN_MANUSCRIPT_TABLES.m`; experiment mode `sensitivity` |

Experiment modes are invoked through
`experiments/run_verification_experiments.m`. Saved-data replay does not rerun
optimization. The instrumented engine performs fresh calculations and records
the fields needed for figures and tables. Regression checks compare it with
the production solvers on declared cases; it is not represented as identical
production source.

## Reported responses

The reported `C = 0.5 F^T U = 0.5 U^T K U` is strain energy for the stated
linear elastic model. It is not the element-ranking score. Its relative
change enters the stopping criterion.

Utilization is evaluated inside the actually assigned material:
`100*VM/250 MPa` for M1 and `100*VM/50 MPa` for M2. Each maximum magnitude is
nonnegative; a signed display uses positive M1 and negative M2. This quantity
is distinct from the stress-state-based selection score. Final stress
comparisons use centroidal VM over all solid elements.

| Case | Updates | C (N·mm) | M1 / M2 elements | Maximum VM (MPa) | M1 maximum (%) | M2 maximum (%) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| I(b) | 214 | 574.783606044 | 549 / 1851 | 128.907505 | 51.563002 | 59.785048 |
| III(a) | 95 | 2552153826.2 | 1884 / 8356 | 136.992486 | 21.596183 | 273.984973 |
| III(b) | 93 | 1675156216.16 | 2318 / 7922 | 137.414343 | 54.965737 | 33.674359 |

`assigned_material_baselines.csv` contains unrounded data and provenance.
`reference_results.csv` supplies the solver regression contract, including
stress-sign-based utilization extrema. Those fields are not the
assigned-material reporting metric; the latter is checked separately by
`tests/test_assigned_material_utilization.m`.

## Interpretation and limits

- Regression comparisons require exact discrete counts and a relative scalar
  tolerance of `1e-8`. Differences due to sparse solves or platform changes
  must be reported rather than replaced with reference values.
- Table 9 uses each condition's own endpoint. Three variants reach the
  1,000-update cap and are not classified as converged.
- Figure 7 transition totals use updates 1–214, including the initial-to-first
  comparison. Material transitions require a solid element in both states;
  occupancy changes are counted separately. The baseline totals are 5,725
  material and 5,200 solid–void events. Layout differences use state 214, with
  all 6,000 elements as the occupancy denominator and common solids as the
  material-assignment denominator. Deadband effects are nonmonotonic.
- Update replay shares the FE input and therefore checks the update rules,
  not FE accuracy independently. Small-model and frozen-layout checks do not
  establish accuracy at every intermediate state. The recorded intermediate
  bridge criterion exceedances and bridge-to-reference compliance differences
  are not claimed to be resolved by these checks.

## Mesh and external FE comparisons

The 40 × 40 mm evaluation regions are used only for Section 3.2. They modify
the extrema evaluation set, not the mesh, loads or optimization, and do not
establish removal of all singularity effects. On the 50 × 30, 100 × 60 and
200 × 120 meshes, each designated region covers 2 × 2, 4 × 4 and 8 × 8
elements, respectively. The code records the represented physical size.

The Abaqus CSV documents matched final layouts. Abaqus jobs are not included.
Rounded agreement cannot establish an error bound below the rounding
resolution, and a fixed-layout FE comparison does not verify the optimization
update algorithm by itself.

The supplied MATLAB checks use R2024b on Windows and base MATLAB. No native
execution in R2023a is claimed. Compact figure and endpoint MAT records are
tracked; fresh full histories and FE arrays belong under ignored `results/`
directories. Reference-author source code and complete original element maps
are not available in this repository.
