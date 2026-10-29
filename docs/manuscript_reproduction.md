# Revised-manuscript reproduction guide

This guide connects the submitted revision checked on 2026-10-29 to the
code, numerical inputs and exported plots.
Three operations are distinct: redrawing saved data, rerunning the
FE/optimization experiments, and plotting
the newly computed results. The latest formal release remains v1.0.0.
The dated manuscript update is provided on `main`, with no new release or tag;
the original v1.0.0 release archive does not contain these additional files.

## Map from manuscript to code

| Item | What it establishes | Entry point / input |
| --- | --- | --- |
| Fig. 6(a,c,d) | Compliance/nk history and first-ten-update stress and averaged-score inputs | `reproduction/RUN_MANUSCRIPT_FIGURES.m`; `submission_20261029/` |
| Fig. 6(b) | Material/void histories and locations after update 10 | Submitted composition; assignment/location source records |
| Fig. 7(a,b) | Actual baseline fractions and per-update transitions over 1–214, with a final-20-update inset | Same figure entry point; baseline phase history |
| Fig. 7(c–e) | Deadband response through 214, event totals over 1–214 and layout differences at 214 | Same figure entry point; five deadband histories |
| Table 8 | MBESO2D/Abaqus FE response comparison | `validation/manuscript_tables/RUN_SUBMISSION_TABLES.m`; `validation/abaqus_crosscheck.csv` |
| Table 9 | Baseline plus 16 one-factor variants (17 rows), including termination status | Same table entry point; final material maps and centroidal VM fields |
| Table 3 | Equations linked to public baseline functions and line numbers | [equation_code_map.md](equation_code_map.md) |

The final paper has Figures 1–7 and Tables 1–9. Earlier Fig. 8 becomes
Fig. 6, and earlier Fig. 9 becomes Fig. 7 with rearranged panels and
transition counts that now include update 1. Earlier Table 9 (Abaqus)
becomes Table 8; earlier Table 10 (sensitivity) becomes Table 9. The former
C/2C Table 8 and bridge energy plots are outside the final table/figure set.
They remain historical numerical evidence. [The figure guide](../reproduction/README.md)
lists the panel-level mapping and the optional legacy numerical replay route.

## Redraw the supplied records

From the repository root in MATLAB:

```matlab
run('reproduction/RUN_MANUSCRIPT_FIGURES.m')
addpath(fullfile(pwd, 'validation', 'manuscript_tables'))
[table8, table9] = RUN_SUBMISSION_TABLES;
```

The figure script opens editable MATLAB graphs and exports FIG, 600-dpi PNG,
PDF and, on Windows, EMF files. FIG, PNG and PDF remain available on other
platforms. For noninteractive export, use:

```matlab
addpath(fullfile(pwd, 'reproduction', 'submission_20261029'))
reproduce_submitted_figures(false)
```

The eight numerical graphs and separate inset exports are written to
`reproduction/submission_20261029/outputs/` and indexed by its
`generated_artifacts.csv`. Figure 6(b) is assembled from assignment and
location artwork; `submission_20261029/RUN_SUBMITTED_ASSIGNMENT.m` provides
an optional native reconstruction from the recorded states. Submitted plot files are preserved in `original_plot/`;
the older source names `Fig_6b.m` and `Fig_6c.m` correspond to final panels
6(c) and 6(d). Times New Roman retains the manuscript typography.

These commands perform no new FE analysis or optimization. The submitted
table wrapper maps the documentary Abaqus comparison to Table 8 and the
sensitivity reconstruction to Table 9. The original
`RUN_MANUSCRIPT_TABLES` API and `published/Table8` / `published/Table10`
records retain their historical meanings. For the old eleven-panel
figure route, run `reproduction/RUN_LEGACY_20261024_FIGURES.m`.

## Run fresh experiments and use their results

```matlab
addpath(fullfile(pwd, 'validation', 'review'))
run_review_experiments('smoke');
run_review_experiments('regression');
```

`run_review_experiments(mode, outputRoot)` supports `smoke`, `regression`,
`baselines`, `sensitivity`, `deadband_extension`, `initial10`, `histories`,
`bridge_energy` and `all`. The full manuscript mode includes new FE solves,
the 16 variants, five deadband paths and fixed-layout audits. The optional
`continuation` and `legacy_histories` modes retain earlier research analyses
that are not part of the final manuscript.
Detailed settings, files and limits are in
[validation/review/README.md](../validation/review/README.md). Full runs can
take substantial time and several GB of memory/disk space. Do not manually
add the isolated engine with `genpath`; its entry point manages the path.

For only the three added Table 9 deadbands (0.05, 0.5 and 5 MPa), use
`run_review_experiments('deadband_extension')` or
`validation/review/RUN_ADDITIONAL_DEADBANDS.m`. This computes four fresh
first-stop endpoints including the baseline; it does not rerun the older
capped variants. Their archived stopping iterations are 153, 216 and 133,
respectively, while Figure 7 compares all conditions at iteration 214.
The `sensitivity` mode computes 17 cantilever endpoints; `all` computes 19
endpoint runs (three baselines and 16 variants), the five histories and
the fixed-layout audits. Earlier-terminating cases retain their histories
to reach the common figure endpoint; the 0.5 MPa endpoint remains 216 for
Table 9. A four-run extension folder alone lacks the
other Table 9 cases. The table API retains the two bridge baselines needed
for its historical reporting-convention audit; it does not rerun Abaqus.

To connect a complete new run to new figures and tables:

```matlab
repoRoot = pwd;
addpath(fullfile(repoRoot,'validation','review'), ...
        fullfile(repoRoot,'validation','manuscript_tables'), ...
        fullfile(repoRoot,'reproduction'))
freshRoot = fullfile(repoRoot,'results','my_review_rerun');
run_review_experiments('all', freshRoot);
freshBundle = prepare_manuscript_figures(freshRoot);
run(fullfile(freshBundle,'RUN_MANUSCRIPT_FIGURES.m'))
[table8, table9] = RUN_SUBMISSION_TABLES( ...
    fullfile(freshRoot,'manuscript_tables'), freshRoot);
```

The adapter builds a separate bundle from fresh records, preserving the
archived publication inputs. Figure 7(a,b) fractions and transition counts
are derived from the baseline phase history in the newly constructed `S`
records. Missing data cause an error; archived values are not silently
substituted. It checks the declared manuscript mesh, history windows and
response stops. Unexpected fresh results must be
inspected rather than forced into the old plot windows. The table function
accepts a fresh root containing `runs/` or that `runs/` folder itself, and
recomputes quantities from the fresh final fields. For the three extended
deadbands it first uses `runs/<run_id>/result.mat`; when absent, it can use
the first-stop state from that same fresh root's `zero_history/<id>/full_history.mat`.
No archived endpoint is silently substituted. Thus earlier complete fresh
runs with the five histories also supply all 17 Table 9 rows. Endpoint data alone do
not prove a two-cycle; fresh table outputs leave that archived-only claim
unasserted. Simply rerunning the archived figure script after an experiment
would still show archived data, hence the explicit adapter step.

## Definitions needed for the manuscript

- **Iteration alignment:** Fig. 6(c,d) retain FE input states 0:9 and plot
  them at update coordinates 1:10, with x-axis label `Iteration`. Panel (b)
  shows assignments after those updates and the state-10 layout. State 0
  remains the source of the first input and the preceding state for update 1.
  Figures 6(a) and 7(c) retain response states 0–214. Full-history axes span
  0–250; zoom axes span 195–215, with the last data at 214 in both cases.
- **Baseline histories in Fig. 7(a,b):** EPS = 0. Actual post-update states
  1–214 supply fractions relative to all 6,000 elements. At state 214,
  solid = M1 + M2 = 40.00% = 9.15% + 30.85%. Transitions compare each
  update with the preceding state, including update 1: 5,725 TC and 5,200 SV
  events in total. The first update contributes 2,439 TC and 60 SV. TC counts
  material-ID changes 1↔2 among continuing solids; SV counts the XOR of
  consecutive occupancy masks. These are events, so elements can contribute
  more than once. The same history over updates 195–214 contains 47 TC and
  102 SV; the update-214 counts are one TC and four SV. These observations
  do not establish subsequent evolution after termination.
- **Common-window deadband comparison:** Fig. 7(c) uses response states
  0–214; panel (d) counts updates 1–214, and panel (e) compares state 214.
  For half-widths 0 / 0.005 / 0.05 / 0.5 / 5 MPa, TC totals are
  5,725 / 6,607 / 5,770 / 4,734 / 4,033 and SV totals are
  5,200 / 5,392 / 5,360 / 5,000 / 5,138. The earlier 2–214 sums remain
  historical and must not be substituted for submitted panel (d).

- **Compliance:** `C = 0.5*F'*U` is strain energy and a stopping metric.
  Cantilever values use N·mm and bridge values use MN·m (N·mm divided by
  `1e9`). `2C` tests the unhalved-work convention on the same response. The reference
  definition remains unconfirmed; the historical C/2C table is not a calibration or proof
  that a factor of two explains the reference discrepancy.
- **Bridge interaction energy:** the cross term `Fq'*Ug` arises when deck
  load and self-weight act together; it is not an additional applied load.
- **Reported utilization:** take the maximum of `100*VM/250` within assigned
  M1 and `100*VM/50` within assigned M2, in percent. Both reported maxima
  are nonnegative. Signed contours use +M1/−M2; the optimizer's stress-state
  score `eta` remains a separate quantity. The manuscript may display the
  compressive-material magnitude with a negative sign to identify M2.
- **Palette:** all generated material maps, assignment strips and legends use
  M1 tensile blue/M2 compressive red/void white, including Fig. 6(b) and
  mesh-consistency figures. The shared definition is `src/mbeso_material_palette.m`.
  Preserved original EMFs may use older or conflicting colors and are not
  modified automatically. Current plots use material IDs, not image colors;
  stress-magnitude colormaps represent a different quantity.
- **Scope:** 40×40 mm exclusions belong only to the Section 3.2
  mesh-consistency extrema, not these additional review analyses.

## Claims supported and limitations retained

Replayed inputs, actual assignments and rendered curves provide evidence
that the declared operations and recorded results are linked correctly.
Fresh checks address the execution path; a successful plot export alone
does not validate FE calculations or reproduce the reference author's code.

Three Table 9 variants (Gauss mean, Gauss maximum and `r2 = 20 mm`) reached
the 1,000-update cap and must remain marked as such. Endpoints are at each
variant's own stop/cap, which differs from
Fig. 7's common-iteration comparison at update 214. Deadband effects are nonmonotonic:
some widths increase switching or change topology. A small compliance
change does not establish a stationary material layout. The bridge
reference-compliance discrepancy and the separately recorded 11
intermediate-FE criterion exceedances remain unresolved limitations; final
state agreement does not erase them.
