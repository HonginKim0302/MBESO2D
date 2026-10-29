# Reproduce the submitted manuscript figures

Open `RUN_MANUSCRIPT_FIGURES.m` in MATLAB and press Run. It routes to
`submission_20261029/RUN_SUBMITTED_FIGURES.m` for the submitted revision
checked on 29 October 2026. The package redraws eight numerical graphs in
Figures 6 and 7, plus separate inset exports, from supplied numerical records.
It performs no optimization or FE solve. For fresh experiments, use
[`../validation/review`](../validation/review).

For export without popup windows, from the repository root:

```matlab
addpath(fullfile(pwd,'reproduction','submission_20261029'))
reproduce_submitted_figures(false)
```

MATLAB R2024b is the reference environment. No third-party runtime, Python,
or additional MATLAB toolbox is required for reproduction. Install Times
New Roman to retain the manuscript typography. Numerical curves, bars,
legends and labels are native editable MATLAB objects.

## Submitted numbering and outputs

The final manuscript has Figures 1–7. The eight numerical graph exports
covered by this package are mapped below. Figure 6(b) is a composition of
the assignment history and locations in the update-10 layout; it is not
counted as an additional numerical graph.

| Submitted panel | Content | Earlier 23 October panel |
| --- | --- | --- |
| Fig. 6(a) | Baseline compliance C and normalization coefficient nk through update 214 | Fig. 8(a) |
| Fig. 6(b) | First-ten-update material/void histories and locations after update 10 | Fig. 8(d,e), combined artwork |
| Fig. 6(c) | Unfiltered and filtered stress-state indicators for element 974, updates 1–10 | Fig. 8(b) |
| Fig. 6(d) | History-averaged scores of elements 974/5829 and retention threshold, updates 1–10 | Fig. 8(c) |
| Fig. 7(a) | Actual solid, M1 and M2 fractions, updates 1–214 | Fig. 9(e) |
| Fig. 7(b) | Per-update transitions over 1–214 and a final-20-update inset | Fig. 9(f), now including update 1 |
| Fig. 7(c) | Deadband compliance differences at equal iterations through 214 | Fig. 9(b) |
| Fig. 7(d) | Cumulative transition counts over updates 1–214 | Fig. 9(c), now including update 1 |
| Fig. 7(e) | Layout differences at iteration 214 | Fig. 9(d) |

Outputs are under `submission_20261029/outputs/` and indexed by
`submission_20261029/generated_artifacts.csv`. FIG files retain editable
graphics; PNG, PDF and Windows EMF provide raster and vector exports.
Submitted plot files are preserved under `submission_20261029/original_plot/`.
Their older filenames do not always identify final panel letters:
submitted `Fig_6b.m` supplies final Fig. 6(c), and `Fig_6c.m` supplies Fig. 6(d).
Use the mapping above when assembling the manuscript.

For an optional editable reconstruction of Figure 6(b), using the actual
assignment histories and update-10 material map, run:

```matlab
run('reproduction/submission_20261029/RUN_SUBMITTED_ASSIGNMENT.m')
```

It writes a separate `assignment_artifacts.csv` and the assignment/map
source tables under `generated_inputs/`. This composition is separate from
the eight numerical graphs in the main entry point.

## Meaning and indexing of the data

- **Figure 6:** panel (a) reports compliance and the normalization coefficient;
  nk is not an actual volume fraction. Panels (c,d) retain FE input states
  0–9 and plot them at the updates 1–10 that consume those inputs. Panel (b)
  records the assignments after the same updates and the layout after update
  10. Update k consumes state k−1 and produces state k. The initial input is
  retained rather than replaced with an artificial zero.
- **Figure 7(a,b):** the EPS = 0 baseline uses post-update states 1–214.
  Fractions are relative to all 6,000 elements, with solid = M1 + M2.
  At update 214 these are 40.00%, 9.15% and 30.85%. A tensile–compressive
  transition (TC) changes material ID between 1 and 2 among elements solid
  in both consecutive states; a solid–void transition (SV) changes occupancy.
  State 0 supplies the preceding state for update 1. The first update has
  2,439 TC and 60 SV events; totals over 1–214 are 5,725 TC and 5,200 SV.
  The update-214 counts are one TC and four SV. The inset enlarges updates
  195–214 from the same history (47 TC and 102 SV); it adds no experiment.
- **Figure 7(c–e):** half-widths are 0, 0.005, 0.05, 0.5 and 5 MPa.
  Compliance differences use the baseline at the same iteration. Cumulative
  counts in panel (d) include update 1: TC = 5,725 / 6,607 / 5,770 / 4,734 /
  4,033 and SV = 5,200 / 5,392 / 5,360 / 5,000 / 5,138, in that width order.
  Repeated transitions of one element are separate events. At iteration
  214, occupancy differences use all 6,000 elements; material differences
  use solids common to the two layouts. Earlier-terminating runs retain
  their histories when continued to this common endpoint. Table 9 instead
  uses each run's own stop or cap; the 0.5 MPa case stops at update 216.

Figures 6(a) and 7(c) retain the submitted response data at states 0–214.
Figures 7(a,b) use post-update states/updates 1–214; state 0 supplies the
preceding state for the first transition. Full-history axes span 0–250,
leaving blank space after the last datum at 214. Zoom axes span 195–215,
with data through 214. These display margins add no analysis and do not
shift the source state numbering.

The material convention is **M1 tensile = blue, M2 compressive = red,
void = white**. Material maps, assignment strips, material-fraction curves
and legends use `../src/mbeso_material_palette.m`. Older artwork does not
override this convention. Colors never change material IDs, stresses,
utilization or solver results. Stress-magnitude colormaps are separate.

Reported utilization uses VM/250 MPa inside actual M1 and VM/50 MPa inside
actual M2. A negative display sign identifies M2; this is distinct from
the optimizer's stress-state score. No 40 mm exclusion is used here.

## Saved records, fresh calculations and verification

The earlier `figure_08/data/` and `figure_09/data/` folder names are retained
for source traceability; they do not specify current manuscript numbering.
`archived_input_manifest.csv` identifies archived inputs and their hashes.
Numerical replay checks test stored values, update alignment, material
decisions and transition counts. Successful export alone does not validate
the underlying FE model or reproduce the reference authors' implementation.

To connect a complete fresh run to new figures:

```matlab
addpath('validation/review', 'reproduction')
freshRoot = fullfile(pwd,'results','my_review_rerun');
run_review_experiments('all', freshRoot)
freshBundle = prepare_manuscript_figures(freshRoot);
run(fullfile(freshBundle,'RUN_MANUSCRIPT_FIGURES.m'))
```

The adapter constructs a separate bundle using fresh initial-update records,
five deadband histories and fixed-layout bridge audits. It derives submitted
graph inputs from those records and preserves the archived publication data.
Missing fresh records cause an error; archived values are not substituted.
`fresh_source.json` records the origin. The adapter expects the declared
100×60 cantilever, common 214-update window and baseline response stops
214/95/93. Fresh differences require inspection rather than forced matching.

Tables are generated separately by
[`../validation/manuscript_tables`](../validation/manuscript_tables):
`RUN_SUBMISSION_TABLES` produces current Tables 8 (Abaqus comparison) and
9 (sensitivity). The Abaqus evidence remains documentary; jobs are not bundled.

## Historical 23 October figures

```matlab
run('reproduction/RUN_LEGACY_20261024_FIGURES.m')
```

This explicit route retains the eleven numerical panels previously numbered
6(c,d), 8(a–c), and 9(b–f). Its `reproduce_legacy_20261024_figures(false)` function,
`manuscript_panel_geometry.csv`, `outputs/` and `generated_artifacts.csv`
retain the earlier plotting contract. Its baseline transition totals
3,286 TC / 5,140 SV cover updates 2–214 and exclude initial assignment.
They must not be described as the submitted Figure 7 totals.

The old bridge force/energy graphs are outside the final figure set; the
bridge equilibrium and energy evidence remains in the research record.
The old C/2C reporting-convention table is likewise historical. With
`C = 0.5*F'*U`, the bridge cross term `Fq'*Ug` is interaction energy,
not another applied load. Energies use MN·m after division of N·mm by 1e9.
The reference compliance discrepancy remains unresolved.

The optional `continuation` and `legacy_histories` modes retain the earlier
50-update continuation research; they are outside the submitted figure scope.
