# Numerical verification experiments

The programs in this directory compute the update histories and endpoint
sensitivity results used in Figures 6 and 7 and Table 9. The instrumented engine
is separate from the production solvers in `src/`, which Table 3 describes.
The regression mode compares its baseline responses with those of the production
implementation. Installing the experiments does not replace the production
solvers.

## Execution

From the repository root in MATLAB:

```matlab
addpath(fullfile(pwd,'validation','experiments'));
report = run_verification_experiments('smoke');
```

`RUN_VERIFICATION.m` provides the same small verification suite. To specify an
output location, pass a second argument:

```matlab
freshRoot = fullfile(pwd,'results','sensitivity');
report = run_verification_experiments('sensitivity',freshRoot);
```

The default output location is a timestamped directory under `results/`.
Paths are resolved relative to the source files. The entry point restores the
MATLAB path and working directory when execution finishes or an error occurs.
Do not add the engine with `genpath`; the entry point selects its solvers explicitly.

| Mode | Calculation | Purpose |
| --- | --- | --- |
| `smoke` | 39 update checks, 7 Q4 patch checks, and small-model FE, energy and stress checks | Interface and component verification |
| `regression` | Production and instrumented solvers on the same first 20 updates, with diagnostics enabled and disabled | Scalar histories and final-field agreement on three specified cases |
| `baselines` | Cantilever I(b) and bridges III(a,b), each at its own termination | Benchmark responses |
| `sensitivity` | Cantilever baseline and 16 one-factor variants, 17 endpoints | Table 9 |
| `deadband_sweep` | Baseline and deadbands of 0.05, 0.5 and 5 MPa, each at its own termination | Four-case endpoint subset |
| `initial10` | All-element inputs, responses and independent update replay for the first ten updates of three cases | Figure 6 and update verification |
| `histories` | Five deadbands through common state 214 and their first termination, plus the initial-ten records | Figures 6 and 7 |
| `bridge_energy` | Three baselines and independent fixed-layout Q4, equilibrium, energy and stress audits | Optional FE diagnostic |
| `all` | 19 endpoints, fixed-layout FE audits, five deadband histories and initial-ten records | Complete numerical verification suite |

`RUN_DEADBAND_SWEEP.m` starts the four-case subset. It is not sufficient by
itself to reconstruct all 17 rows of Table 9.

## Comparison definitions

The five history calculations use deadband half-widths of 0, 0.005, 0.05, 0.5
and 5 MPa.
Figure 7 compares responses and layouts at common iteration 214. Conditions
that terminate earlier retain the complete update state during continuation
to this common point. Table 9 instead uses each condition's first analysis
termination or its iteration cap. The recorded first terminations for 0.05,
0.5 and 5 MPa are 153, 216 and 133; these are comparison values, not imposed
stopping iterations.

A material transition is a change between M1 and M2 in an element that is solid
in both consecutive states. A solid–void transition is a change in occupancy.
The Figure 7 totals include updates 1–214; state 0 supplies the input for update
1. The baseline totals are 5,725 material transitions and 5,200 solid–void
transitions. The 195–214 inset contains 47 and 102 events, respectively.
At state 214, the actual solid, M1 and M2 fractions are 40.00%, 9.15% and 30.85%
of all 6,000 elements. These observations do not establish behavior after the
reported comparison interval.

Stress comparisons use centroidal von Mises stress over the entire solid
domain. Reported utilization is `100*VM/strength` for elements assigned to each
material: 250 MPa for M1 and 50 MPa for M2. The signed display uses positive M1
and negative M2. This reporting quantity is distinct from the element selection
score. The 40 × 40 mm exclusion belongs only to the mesh-consistency study.

## Outputs and verification scope

Endpoint calculations produce `runs/<run_id>/result.mat`, scalar histories,
element fields, and configuration and source hashes. History calculations produce
`zero_history/<run_id>/full_history.mat`, `initial10/<case>/full_history.mat`,
update replay checks and CSV summaries. The initial state, each update input,
and each resulting layout are distinguished explicitly.

To generate figures from new calculations, use
`reproduction/prepare_manuscript_figures.m`. To generate Table 9 from new
calculations, use `validation/manuscript_tables/RUN_MANUSCRIPT_TABLES.m`.
Both functions report an error if the required new inputs are missing; neither
substitutes bundled numerical records.
Table 8 contains the supplied rounded Abaqus comparison. Abaqus jobs are not
included or rerun by this engine.

Independent update replay shares the FE input with the instrumented solver.
It verifies the update calculation but does not independently assess FE accuracy.
Small-model and frozen-layout checks do not establish accuracy for every
intermediate design or reproduction of the reference authors' code. The reported
bridge compliance discrepancies remain unresolved; they must not be described as
eliminated by an equilibrium or energy identity.

The cantilever has 6,000 elements and each bridge has 25,600. Some variants
reach 1,000 updates. Full histories can require several GB of memory and disk
space. The smoke-test runtime does not estimate the runtime of the full study.
The execution environment used for package checks is MATLAB R2024b on Windows;
no additional toolbox is required. Floating-point identity across MATLAB
releases or operating systems is not assumed.

The engine and experiment code are provided under GPL-3.0-or-later. The
upstream attribution and permission notice are retained in
`engine/THIRD_PARTY_NOTICE.md`.
