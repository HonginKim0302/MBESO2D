# Reproducibility

## Environment and setup

Open MATLAB in the repository root and run `setup_mbeso_path`. The code uses
base MATLAB. Verification has been performed in MATLAB R2024b Update 7 on
Windows 64-bit. The core solvers are expected to support R2019b or later.
The complete figure and experiment workflows have not been tested in every
release in that range. Execution in R2023a has not been verified.

Record the Git commit, MATLAB version, operating system, processor, RAM, and
execution time with computational results. `VERSION` identifies the formal
release; the exact commit identifies the source used for a particular
calculation.

## Supplied records and new calculations

Figures and tables can be generated from supplied records or from new
calculations:

1. **Reproduction from supplied records.** The commands below create editable
   figures and tables without rerunning optimization.
2. **New calculations.** The verification experiments compute FE histories
   and endpoints for use with the same figure and table workflows.

```matlab
run('reproduction/RUN_MANUSCRIPT_FIGURES.m')
addpath(fullfile(pwd, 'validation', 'manuscript_tables'))
[table8, table9] = RUN_MANUSCRIPT_TABLES;
```

See [manuscript_reproduction.md](manuscript_reproduction.md) for panel scripts,
output formats, iteration definitions, and the distinction between numerical
graphs and manually composed figure artwork. The compact input records are
stored beside the figure scripts and in `validation/manuscript_tables/`.
Save generated output in `results/` or `reproduction/outputs/`, not among
the source records.

## Verification experiments

```matlab
addpath(fullfile(pwd, 'validation', 'experiments'))
run_verification_experiments('smoke');
```

`run_verification_experiments(mode, outputRoot)` accepts an explicit output
folder. The script `validation/experiments/RUN_VERIFICATION.m` runs
the smoke checks when opened and executed with F5; `RUN_DEADBAND_SWEEP.m`
runs the endpoint deadband sweep.

| Mode | Work performed |
| --- | --- |
| `smoke` | Small execution and verification checks |
| `regression` | Public-solver and instrumented-solver comparison over the first 20 updates |
| `baselines` | Cantilever and both bridge baselines |
| `sensitivity` | Cantilever baseline and sixteen one-factor conditions |
| `deadband_sweep` | Baseline and the 0.05, 0.5 and 5 MPa deadband endpoints |
| `initial10` | First-ten-update element records and independent update replay |
| `histories` | Five deadband paths through the 214-update figure window and required first-termination states |
| `bridge_energy` | Baselines and independent-Q4 energy/stress checks |
| `all` | Three baselines, sixteen variants, fixed-layout audits and manuscript history studies |

The baseline solver entry points remain in `src/`. Experimental alternatives
and their instrumentation are confined to `validation/experiments/` so that
their settings and numerical scope are explicit. Full-mesh calculations take
substantially longer than plotting or smoke checks; full element histories
can require gigabytes of disk space.

To calculate and plot a complete study from the repository root:

```matlab
repoRoot = pwd;
freshRoot = fullfile(repoRoot, 'results', 'verification');
addpath(fullfile(repoRoot, 'validation', 'experiments'))
run_verification_experiments('all', freshRoot);

addpath(fullfile(repoRoot, 'reproduction'))
bundle = prepare_manuscript_figures(freshRoot);
run(fullfile(bundle, 'RUN_MANUSCRIPT_FIGURES.m'))

addpath(fullfile(repoRoot, 'validation', 'manuscript_tables'))
[table8, table9] = RUN_MANUSCRIPT_TABLES( ...
    fullfile(freshRoot, 'tables'), freshRoot);
```

The figure preparation requires the cantilever initial-ten-update record and
the five complete deadband histories at 0, 0.005, 0.05, 0.5 and 5 MPa. It
derives fractions and transitions from those records and fails if required
newly computed records are missing. Generating Table 9 from new calculations
requires the seventeen cantilever endpoints; the three extended deadband
endpoints may also be read from their first-termination history records.
Bridge inputs are not required to prepare Figures 6-7 or Table 9. Table 8
continues to use the reported Abaqus comparison records.

## Example conditions

```matlab
run('examples/run_cantilever.m')
run('examples/run_case_3a.m')
run('examples/run_case_3b.m')
```

The example scripts specify the following conditions explicitly.

| Example | Mesh | Domain | Thickness | External load | Self-weight |
| --- | --- | --- | --- | --- | --- |
| Cantilever | 100 x 60 | 1000 x 600 mm | 1 mm | 1000 N point load | No |
| III(a) | 320 x 80 | 160 x 40 m | 1 m | 100 kN/m, equal nodes on row 78 above the lower deck | Yes |
| III(b) | 320 x 80 | 160 x 40 m | 1 m | 100 kN/m, equal nodes on the upper row 1 | Yes |

The bridge deck load totals 16 MN. Densities are 7,800, 2,400 and 0 kg/m^3
for M1, M2 and void, with gravity 9.81 m/s^2. Self-weight is assembled from
the current material map at each FE analysis. See [examples.md](examples.md)
for support indices, retained regions and boundary-condition diagrams.

## Quantities and comparison windows

Compliance is reported as strain energy, `C = 0.5*F'*U = 0.5*U'*K*U`, in
N·mm. A change in reporting convention must be distinguished from a change
in physical load, stiffness, or thickness. The optimizer retains elements
using history-averaged selection scores, not a compliance gradient.

Reported utilization is evaluated for the elements assigned to each material:
`100*VM/sigma_m1` for M1 and `100*VM/sigma_m2` for M2. Their contour signs
identify +M1 and -M2; they do not identify the local stress state. This
quantity is distinct from the internal `eta` score. The signed colorbar has
separate linear positive and negative halves, zero at its center and actual
unequal extrema at its endpoints. Physical values are not rescaled.

Table 9 compares each run at its own analysis termination or iteration cap.
Figure 7 compares all five deadbands at common states through 214; runs that terminate earlier
are recorded through that common window. Transition definitions and baseline
sum checks are given in the [figure guide](manuscript_reproduction.md).

The 40 x 40 mm support/load exclusions are restricted to the Section 3.2
mesh-consistency extrema. Those elements remain in FE analysis and design
updates. All sensitivity results use full solid-domain extrema.

## Source and release checks

Before archiving a source snapshot, run the regression and smoke checks,
verify the figure and table inputs and outputs, and record the computational
environment. Keep declared MAT/CSV input records in the distribution while
excluding temporary analysis output. Check the GPL and preserved third-party
MIT notices. Published tags should remain immutable; cite the release DOI
and exact commit associated with the results.
