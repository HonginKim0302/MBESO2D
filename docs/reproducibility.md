# Reproducibility Notes

This document summarizes the recommended reproduction workflow for `MBESO2D` version `1.0.0`.

## Setup

Open MATLAB in the repository root:

```matlab
setup_mbeso_path
```

The repository uses base MATLAB only. It has been tested with MATLAB R2024b
Update 7 on Windows 64-bit. MATLAB R2019b or later is expected to be compatible
with the plotting utilities, but older releases have not been regression-tested.

## Example Runs

Run individual examples:

```matlab
run('examples/run_cantilever.m')
run('examples/run_case_3a.m')
run('examples/run_case_3b.m')
```

The bridge-like fixed-solid examples are large and can take substantial time to run.

## Regenerate the submitted manuscript figures and tables

From the repository root:

```matlab
run('reproduction/RUN_MANUSCRIPT_FIGURES.m')
addpath(fullfile(pwd, 'validation', 'manuscript_tables'))
RUN_SUBMISSION_TABLES;
```

These entry points use supplied records for Figures 6 and 7 and Tables 8
and 9 of the submitted revision checked on 29 October 2026. They regenerate
plots/tables without rerunning optimizations. Table 8 is the documentary
Abaqus comparison and Table 9 is the sensitivity study. The final paper has
Figures 1–7 and Tables 1–9. Saved artwork records the composition; numerical
curves come from the declared arrays and tables.

The figure entry script opens MATLAB windows by default. For batch export:

```matlab
addpath(fullfile(pwd, 'reproduction', 'submission_20261029'))
reproduce_submitted_figures(false)
```

Eight numerical graphs and separate inset exports are written under
`reproduction/submission_20261029/outputs/` as editable FIG, PNG, PDF and
Windows EMF files. Times New Roman retains the manuscript typography.
Figure 6(b) is the combined material-state/location artwork. The optional
`submission_20261029/RUN_SUBMITTED_ASSIGNMENT.m` reconstructs it as native
MATLAB graphics from the recorded states, separately from the eight graphs.

| Submitted panels | Content |
| --- | --- |
| Fig. 6(a) | Compliance C and normalization coefficient nk through update 214 |
| Fig. 6(b) | Assignments over updates 1–10 and locations at update 10 |
| Fig. 6(c,d) | Stress-state inputs and history-averaged scores, updates 1–10 |
| Fig. 7(a,b) | Actual fractions and per-update transitions over 1–214, with a final-20-update inset |
| Fig. 7(c–e) | Common-window deadband compliance differences, counts over 1–214 and layouts at 214 |

In Fig. 6(c,d), x = 1:10 identifies the update using FE input states 0:9.
The first input is retained, while panel (b) shows the assignments after
those updates. Figures 6(a) and 7(c) retain response states 0–214; Figures
7(a,b) use post-update states/updates 1–214. State 0 provides the preceding
state for the first transition and is not shifted to update 1. Full-history
axes span 0–250, with blank space after 214. Zoom axes span 195–215, with
data through 214. These are display margins only.

The explicit historical route is:

```matlab
run('reproduction/RUN_LEGACY_20261024_FIGURES.m')
```

It preserves the eleven 23 October numerical panels and their original
numbering, geometry and 2–214 transition convention.
The former bridge energy graphs and C/2C table are historical evidence,
outside the submitted figure/table set. Earlier continuation experiments
are also outside the submitted scope. See [the panel guide](../reproduction/README.md)
for full numbering and provenance.

## Rerun the review experiments

The separate execution engine records the declared study settings and keeps
experimental variants separate from the two public baseline solver entry
points. It restores the caller's MATLAB path and working directory after a
run. From the repository root:

```matlab
addpath(fullfile(pwd, 'validation', 'review'))
run_review_experiments('smoke')
run_review_experiments('regression')
```

`run_review_experiments(mode, outputRoot)` accepts an optional output folder.
If omitted, results go to `results/review_<mode>_<timestamp>/`.
`validation/review/RUN_REVIEW_VALIDATION.m` is the F5 smoke-test entry point.

| Mode | Work performed |
| --- | --- |
| `smoke` (default) | Small execution and verification checks |
| `regression` | Compare the public solvers with the isolated review engine over the first 20 updates |
| `baselines` | Rerun the cantilever and both bridge baselines |
| `sensitivity` | Rerun the cantilever baseline and 16 one-factor variants (17 runs) |
| `deadband_extension` | Rerun only the baseline and the 0.05, 0.5 and 5 MPa first-stop endpoints (4 runs) |
| `continuation` | Optional historical study: rerun three cases with 50 updates beyond their first response stop; outside the final manuscript |
| `initial10` | Record all-element inputs and replay the first ten updates of three cases |
| `histories` | Record the five EPS paths through the common 214-update figure window and each required first-termination state, plus the initial-update checks |
| `legacy_histories` | Optional earlier history study through 264 and 50 updates after first termination; outside the final manuscript |
| `bridge_energy` | Rerun three baselines and the independent-Q4 energy/stress checks |
| `all` | Run the three baselines, 16 variants, fixed-layout audits and current manuscript history studies |

To plot a complete fresh run, pass its output root to
`prepare_manuscript_figures` and run the returned bundle's
`RUN_MANUSCRIPT_FIGURES.m`. Figure 7(a,b) is derived from the baseline phase
history in the newly constructed `S` records; missing fresh data cause an
error, without archived fallback. See
[the manuscript guide](manuscript_reproduction.md) for the complete command
sequence.

The 29 October adapter validation used previously recorded FE histories and
an audit fixture in MATLAB R2024b. It checked output derivation with the
submitted TXT inputs unavailable and confirmed that a controlled material-state
change altered the derived counts and fractions. It did not rerun a full
optimization or Abaqus analysis. Native R2023a execution remains untested;
see the [alignment record](submission_alignment_20261029.md) for the exact scope.

Detailed case definitions and outputs are documented beside the execution
entry point. Full histories can require gigabytes of disk space; full-mesh
optimizations take substantially longer than plotting or smoke checks.
The review code targets the tested MATLAB R2024b environment using base
MATLAB. Compatibility expectations for older core-solver versions are not
evidence that the whole review package has been tested on those releases.

## Fixed Physical Conditions

The public examples define their numerical conditions directly in the scripts.
The principal conditions that must not be inferred from solver defaults are:

| Example | Mesh | Dimensions | Thickness | External load | Self-weight |
| --- | --- | --- | --- | --- | --- |
| Cantilever | 100 x 60 | 1000 x 600 mm | 1 mm | 1000 N point load | No |
| Case 3a | 320 x 80 | 160 x 40 m | 1 m | 100 kN/m over 160 m, equal nodes, row 78 above the lower deck | Yes |
| Case 3b | 320 x 80 | 160 x 40 m | 1 m | 100 kN/m over 160 m, equal nodes, upper row 1 | Yes |

Both bridge examples use `rho1 = 7800 kg/m^3`, `rho2 = 2400 kg/m^3`,
`rho0 = 0`, and `g = 9.81 m/s^2`. The total prescribed deck load is 16 MN.
Self-weight is recomputed from the current material layout at every finite-
element analysis.

## Generated Files

Text reports contain MATLAB version, release, computer type, operating system, CPU, CPU core count, physical RAM when available, run settings, run time, response summary, and full iteration log.

Expected generated file patterns:

```text
results/mbeso_run_report_*.txt
results/mbeso_fixed_solid_run_report_*.txt
results/mbeso_fixed_solid_result_*.mat
```

Generated files are ignored by Git. The empty `results/` directory is preserved by `results/.gitkeep`.

Declared numerical reproduction inputs are intentionally stored outside
`results/` and must remain in the distribution. Do not remove supplied
MAT/CSV input records merely because fresh solver results are normally
ignored by Git.

## Numerical Baselines

Compact reference values and comparison rules are stored in:

```text
validation/VALIDATION_SUMMARY.md
validation/reference_results.csv
validation/cantilever_literature_comparison.csv
validation/mesh_independence_reference.csv
validation/bridge_benchmark_reference.csv
validation/abaqus_crosscheck.csv
```

The executable baseline includes convergence status, iteration count,
compliance, solid ratio, material counts, and full-domain response extrema.
The mesh study uses a fixed 40 x 40 mm exclusion only for extrema evaluation.
The bridge baseline uses a 1 m out-of-plane thickness and full-domain response
values. These data are intended to detect unintended code or example changes;
they are not a claim that all MATLAB releases or sparse linear-algebra
libraries will produce an identical discrete topology.

The source annotations added for the review are mapped in
[equation_code_map.md](equation_code_map.md). The map identifies the exact
annotated `src/mbeso.m` snapshot. Updating comments shifts Table 3's line
numbers even when all executable statements remain unchanged.

## Interpretation of the saved evidence

- Compliance is strain energy `C = 0.5*F'*U`. The historical C/2C reporting
  comparison tests an alternative convention, not a fitted correction factor;
  it is not submitted Table 8.
- Material-wise utilization divides VM by the actual assigned material's
  strength. Positive M1/negative M2 contour signs are display identifiers;
  the optimizer's `eta` follows its stress-state normalization.
- Sixteen one-factor variants belong to six factor groups. Three variants
  reached the 1,000-update cap; their endpoints remain marked as capped.
- Figure 7 compares deadbands at common iteration 214; Table 9 uses each
  run's own termination or cap. Earlier-terminating cases retain histories
  when continued to 214. Transition counts in submitted panels (b,d) cover
  updates 1–214, including comparison with the initial state at update 1.
  The observed effect is nonmonotonic, and response convergence does not
  imply a stationary material layout.
- Figure 7(a,b) uses EPS = 0. Actual solid/M1/M2 fractions are measured over
  all 6,000 elements at states 1–214 and finish at 40.00%/9.15%/30.85%.
  The transition history totals 5,725 TC and 5,200 SV events, including
  2,439 TC and 60 SV at update 1. TC counts changes between material IDs
  1 and 2 among continuing solids; SV counts consecutive occupancy changes.
  An element can contribute more than once. The 195–214 inset contains
  47 TC and 102 SV from the same history; update 214 has one TC and four SV.
  These counts do not establish the evolution after termination.
- The historical 23 October baseline totals 3,286 TC / 5,140 SV exclude
  update 1 and apply only to the dated replay route.

- The bridge reference-compliance discrepancy and the separately recorded
  11 intermediate-FE criterion exceedances remain limitations. Final-state
  agreement and update replay checks do not erase those observations.
- The 40 x 40 mm exclusions belong only to the Section 3.2 mesh-consistency
  comparison. Full solid-domain extrema are used in the added sensitivity
  analysis.

All generated material layouts and assignment strips, including examples,
mesh-consistency outputs and Fig. 6(b), use M1 tensile blue, M2 compressive
red and void white. Use the shared `src/mbeso_material_palette.m` definition;
preserved original EMFs may use older conventions. Material IDs remain
unchanged. Zero-centred signed-contour colorbars retain actual asymmetric
endpoints and use separate linear negative and positive halves; their physical
values remain unchanged. A stress-magnitude colormap does not identify material.

## Release Checklist

Before creating a GitHub release:

1. Run the manuscript example scripts and keep the generated reports outside the Git repository.
2. Confirm all figure/table inputs are fixed in the example scripts.
3. Compare the results with `validation/reference_results.csv`.
4. Confirm that the copyright, GPL, and preserved third-party MIT notices are
   current and complete.
5. Exclude temporary fresh-run MAT/report files and unreferenced assets, while
   retaining declared saved reproduction inputs and their provenance.
6. Update `README.md` and `CITATION.cff` with final public metadata.
7. Create a new immutable release tag for the reviewed snapshot; do not move
   an existing published tag to different source files.
8. Archive that exact tag and add the archival DOI to `CITATION.cff`.

## Reporting Computational Environment

For each manuscript result, report at least:

- MATLAB version and release,
- operating system,
- CPU model and core count,
- RAM,
- mesh size,
- material constants,
- filter radii,
- boundary/load case,
- line-load distribution and loaded node row,
- densities, gravity, and out-of-plane thickness when self-weight is used,
- run time,
- Git release tag and DOI.
