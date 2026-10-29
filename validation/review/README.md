# Review experiment reruns

This directory supplies the numerical experiments behind the additional
verification in submitted Figures 6 and 7 and Table 9, as checked on
29 October 2026. It also retains the earlier bridge and continuation audits.
It is separate from the compact production solvers in `src/`, which Table 3
describes.
The main solvers are not replaced by a research version when this folder is
installed. See the repository license and `engine/THIRD_PARTY_NOTICE.md`.

There are two complementary ways to reproduce the paper:

1. `reproduction/RUN_MANUSCRIPT_FIGURES.m` redraws the supplied, archived
   numerical data as eight submitted numerical graphs, plus separate insets.
   `RUN_LEGACY_20261024_FIGURES.m` preserves the earlier eleven-panel route.
2. The commands below assemble FE models and run optimizations again. They
   produce new results, which must be compared with the archived values; they
   do not silently substitute archived responses for fresh calculations.

## Run

From the repository root in MATLAB:

```matlab
addpath(fullfile(pwd, 'validation', 'review'));
report = run_review_experiments('smoke');
```

Alternatively, open `RUN_REVIEW_VALIDATION.m` and press Run. The default is a
small interface check. To choose an output directory explicitly:

```matlab
report = run_review_experiments('sensitivity', fullfile(pwd,'results','my_sensitivity'));
```

Without a second argument, a timestamped folder under repository `results/`
is created. Inputs are resolved relative to these files, not the launch
directory. The original MATLAB path and current folder are restored even if
a check fails. Do not add the whole engine using `genpath`: let the entry
point resolve the intended solver and remove its path afterwards.

| Mode | Fresh work | Manuscript connection |
| --- | --- | --- |
| `smoke` | 39 small update checks, 7 Q4 patch checks, and small-model FE/energy/stress export checks | Tests package interfaces; does not reproduce full-size paper results |
| `regression` | Public and instrumented solvers, diagnostic fields on/off, same first 20 updates; full scalar histories and final fields | Checks that the baseline research engine agrees with the public implementation on declared cases |
| `baselines` | Case I(b), III(a), III(b) with their response stopping rules | Baseline responses and historical C/2C source values |
| `sensitivity` | Case I(b) baseline and 16 one-factor variants (17 runs), each at its own endpoint | Table 9 |
| `deadband_extension` | Case I(b) baseline and 0.05, 0.5 and 5 MPa deadbands (4 runs), each at its first response stop | Three additional Table 9 rows, without rerunning the older capped variants |
| `continuation` | Three baseline runs and three runs continuing 50 updates after their first response stop | Optional historical study; excluded from the final manuscript |
| `initial10` | All-element input and output records and independent update replay for the first ten updates of the three cases | Figure 6 and update verification |
| `histories` | Five cantilever deadbands (0, 0.005, 0.05, 0.5, 5 MPa), first-stop pilots, observations through the common update 214 and each required first-stop state, plus `initial10` | Figures 6 and 7, including baseline histories in 7(a,b) |
| `legacy_histories` | Earlier observation windows through at least update 264 and 50 updates after first stop | Optional historical study; excluded from the final manuscript |
| `bridge_energy` | Three baseline runs, independent frozen-layout Q4 assembly, equilibrium and energy checks and full-domain stress recovery | Historical bridge force/energy graphs and reporting-convention audit |
| `all` | Three baselines and 16 variants (19 endpoint runs), frozen-layout FE audits, five current deadband histories and initial-ten records | Current manuscript experiments; potentially lengthy |

To rerun only the added Table 9 cases, open `RUN_ADDITIONAL_DEADBANDS.m`
and press Run, or use:

```matlab
report = run_review_experiments('deadband_extension');
```

The new run IDs are `cantilever_eps_0p05`, `cantilever_eps_0p5` and
`cantilever_eps_5`. These half-widths were already included in the full
history study; the added endpoint declarations make them directly available
in the sensitivity suite. The archived first response stops are 153, 216
and 133, respectively. They are comparison values, not forced stopping
iterations. Table 9 uses each condition's first stop; Figure 7 uses common
iteration 214 and transition totals over updates 1–214, including update 1.
Earlier-terminating conditions retain their histories when continued to 214; the 0.5 MPa
condition terminates at 216. Thus, a figure endpoint is not substituted for
a Table 9 endpoint. The baseline continuation beyond 214 and the old
245–264 window are excluded from the current manuscript route. The quick extension's `suite_summary.csv` covers only four runs;
use `sensitivity` for all 17 Table 9 cases or `all` for the complete figures
and the retained bridge-audit inputs. Submitted Table 8 is the documentary
Abaqus comparison; these commands do not rerun Abaqus.

Figure 7(a,b) uses the zero-deadband baseline (EPS = 0). Panel (a) plots
actual post-update solid, M1 and M2 fractions over states 1–214 relative to
all 6,000 elements. At state 214 these are 40.00%, 9.15% and 30.85%.
Panel (b) counts transitions over updates 1–214, comparing each state with
the preceding state. State 0 is retained for update 1, which contributes
2,439 TC and 60 SV. The totals are 5,725 TC and 5,200 SV, matching the
baseline in Fig. 7(d). The 195–214 inset contains 47 TC and 102 SV from
the same history. Update 214 has one TC and four SV. These counts do not
establish what would happen after termination.

For fresh plots, `reproduction/prepare_manuscript_figures.m` constructs a
separate bundle from fresh histories and audits. It derives the current
inputs, including the Figure 7(a,b) baseline histories, from newly constructed
`S` records. Missing fresh records cause an error; archived histories are
not substituted. See [the reproduction guide](../../reproduction/README.md).

The paper-scale cantilever has 6,000 elements; each bridge has 25,600.
Some sensitivity variants reach 1,000 updates. Full histories store multiple
element-by-update arrays and can require several GB of disk space and RAM.
Runtime depends on hardware and can be much longer than the smoke check.
The package was checked with MATLAB R2024b; no specialized toolbox is needed.
Exact floating-point identity is asserted only in the explicitly stated
same-session comparisons, not promised across operating systems or releases.

`review_run_one` permits reuse only when configuration and numerical source
hashes agree. The all-element history mode requires a fresh history output
folder. Neither command deletes old results.

## What is stored

For baseline, sensitivity and continuation modes:

- `runs/<run_id>/config.json`: explicit geometry, material, load, filter,
  classification and termination inputs.
- `result.mat`: final design, aligned FE response and scalar history, source
  and environment metadata.
- `diagnostics.mat`: initial-to-final material maps and transition diagnostics.
- `iteration_history.csv`: scalar history, scheduled/actual solid volume,
  material fractions and transition counts.
- `final_elements.csv`: actual material and centroidal VM per element.
- `suite_summary.csv`: endpoints, stop reasons, response changes and
  nonnegative utilization maxima in the actually assigned M1/M2 subsets.

For `histories` and `initial10`, `zero_history/` and `initial10/` contain
`full_history.mat`, replay checks, representative trajectories and exported
tables. Update `k` consumes the FE input of state `k-1` and produces material
state `k`. In a trajectory row named `state`, outgoing values belong to the
next update. Plot those first ten input rows at x=1:10 when comparing their
decisions with post-update material states 1:10. The plot label may remain
`Iteration`; this indexing relation is still required.

Bridge audits add `audits/energy_audit.csv`, `energy_checks.csv`,
`energy_decomposition.csv`, `stress_extrema.csv`, and the corresponding MAT
arrays. They compare a separately coded Q4 assembly with the saved layout and
FE response. The historical bridge energy panel compares the component sum with separately stored
combined-load compliance; the total bar is not computed by adding the plotted
components. This is not a new Abaqus run. The energy cross term is the
interaction of the two load responses, not an extra applied load:

```text
C = 0.5 F' U = external-only energy + Fq' Ug + self-weight-only energy
```

All native energy values use N·mm. Divide by 1,000 for N·m and by 1e9 for
MN·m. Reported utilization is `100*VM/sigma_allowable` within each actual
material subset (M1: 250 MPa; M2: 50 MPa); it is distinct from the
stress-sign-based update score and is not a signed minimum over all solids.
No 40 mm exclusion is used for the added review analyses. The optional
`consistency_exclusion_widths_mm` field in the historical stress helper is
reserved for the separate mesh-consistency exercise.

## Engine and provenance

`engine/src/` is the instrumented Revision 5 numerical engine that generated
the saved research data, including deadband, stress-recovery, rounding,
tie-order, continuation and observation options. Those options are research
controls; their presence does not imply that public `src/` exposes them.
The five distributed engine source files retain their original file contents.
Required numerical helpers accompany them. `source_provenance.csv` records
original and distributed source hashes and names the source revision.

The portable history wrapper removes **only** dependencies on unpublished
development archive files. Its own observer-versus-pilot checks and
independent update replay still run. Development archive-prefix comparisons
are explicitly marked as not run (NaN where relevant); they are not counted
as new passes. The output-format wrapper, public/engine regression adapter,
and optional stress-exclusion switch are documented in `PORTING_CHANGES.txt`.

`reference/` contains small CSV summaries copied from the executed research
archive, plus their hashes and source-relative locations. These files are
comparison evidence, not fresh output or solver inputs. The large historical
MAT histories are omitted; fresh commands regenerate those histories.

## Interpretation limits

- Passing a small check or replaying the same FE inputs does not prove the
  original authors' unpublished implementation or a globally optimal design.
- The response stopping criterion does not require a stationary material map.
  Report capped runs and remaining transitions instead of calling every
  endpoint converged.
  `iteration_cap_runs` counts the `max_iterations` termination reason.
  `endpoint_response_flag_false_runs` also includes completed continuations
  whose final response-change flag is false; those runs did not hit the cap.
- Wider deadbands do not monotonically suppress transitions or preserve the
  baseline layout. In the submitted common window 1–214, material-transition
  totals are 5,725, 6,607, 5,770, 4,734 and 4,033 for half-widths 0, 0.005,
  0.05, 0.5 and 5 MPa. TC counts changes between material IDs 1 and 2 among
  elements solid in consecutive states; SV counts the XOR of their solid
  occupancy masks. These are event counts, not counts of unique elements:
  an element can contribute on several updates. At iteration 214, occupancy
  differences use all 6,000 elements and material differences use solids
  common to both layouts.
- Independent FE checks at the two historical intermediate peak states had
  11 tolerance exceedances. Final-state and smoke passes do not erase those
  findings, and this package does not claim to rerun their precision study.
- The large reference bridge compliance difference remains unresolved.
  A factor-of-two reporting comparison is a diagnostic, not a correction
  factor applied to the solver or a reproduction of the reference layouts.

The earlier 23 October figure replay excluded update 1 from its transition
totals (baseline 3,286 TC / 5,140 SV over 2–214). Those dated records and
the `RUN_MANUSCRIPT_TABLES` reporting-convention outputs are preserved with
their historical numbering; they are not the submitted Figure 7 or Table 8.
