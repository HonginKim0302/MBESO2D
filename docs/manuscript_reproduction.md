# Manuscript figures and tables

The manuscript contains Figures 1-7 and Tables 1-9. Figure and table numbers
in this repository follow that arrangement.

## Locations of the manuscript results

| Item | Content | Repository source |
| --- | --- | --- |
| Fig. 1 | Algorithm and execution flow | `docs/assets/figures/figure_sources.pptx`; [equation-to-code map](equation_code_map.md) |
| Fig. 2 | Cantilever definition, layout and response contours | `examples/run_cantilever.m` and `visualization/` |
| Fig. 3 | Three-resolution cantilever comparison | `validation/run_mesh_independence.m` |
| Fig. 4 | Bridge examples and response contours | `examples/run_case_3a.m`, `examples/run_case_3b.m` |
| Fig. 5 | Fixed-layout MBESO2D/Abaqus comparison | `validation/abaqus_crosscheck.csv`, `validation/figures/abaqus_crosscheck.png`; figure composition in `docs/assets/figures/` |
| Figs. 6-7 | Element decisions, fractions and deadband histories | `reproduction/figure_06/`, `reproduction/figure_07/` |
| Tables 1-3 | Software/interface and implementation descriptions | `VERSION`, [input parameters](input_parameters.md), [equation-to-code map](equation_code_map.md) |
| Tables 4-7 | Benchmark definitions and numerical comparisons | [validation summary](../validation/VALIDATION_SUMMARY.md) and reference CSV files in `validation/` |
| Table 8 | MBESO2D/Abaqus final-layout comparison | `validation/manuscript_tables/` |
| Table 9 | Baseline and sixteen one-factor conditions | `validation/manuscript_tables/` |

The PowerPoint source preserves figure composition, including manually placed
labels, connectors and schematics. The numerical scripts regenerate curves,
bars, axes and legends from numerical records. They do not treat a raster
image as numerical input or claim pixel-identical PowerPoint composition.

## Reproduce the numerical panels

Open MATLAB in the repository root and run:

```matlab
run('reproduction/RUN_MANUSCRIPT_FIGURES.m')
```

This opens ten graph windows: eight main panels and two separate zooms.
For batch export without windows:

```matlab
addpath(fullfile(pwd, 'reproduction'))
reproduce_manuscript_figures(false);
verify_manuscript_figures;
```

Outputs are saved in `reproduction/outputs/` as FIG, PNG (600 dpi), PDF and,
on Windows, EMF. Numerical plot tables are in `reproduction/outputs/data/`;
`figure_manifest.csv` lists the exports. Figure sizes and Times New Roman
typography are specified in the plotting code.

Each script in the following table can also be opened and run directly.

| Panel | Script under `reproduction/` | Numerical content |
| --- | --- | --- |
| 6(a) | `figure_06/Fig06_a.m` | Compliance and normalization coefficient, states 0-214 |
| 6(b), optional | `figure_06/Fig06_b.m` | Assignments at updates 1-10 and element locations at state 10 |
| 6(c) | `figure_06/Fig06_c.m` | Raw and filtered stress-state indicators for element 974, inputs to updates 1-10 |
| 6(d) | `figure_06/Fig06_d.m` | History-averaged scores for elements 974 and 5829 and the retention threshold, inputs to updates 1-10 |
| 7(a) | `figure_07/Fig07_a.m` | Actual solid, tensile-material and compressive-material fractions, states 1-214 |
| 7(b) | `figure_07/Fig07_b.m` | Per-update material and solid-void transitions, updates 1-214 |
| 7(b), zoom | `figure_07/Fig07_b_zoom.m` | The same transitions, updates 195-214 |
| 7(c) | `figure_07/Fig07_c.m` | Compliance differences between deadband conditions at equal states 0-214 |
| 7(c), zoom | `figure_07/Fig07_c_zoom.m` | The same response differences, states 195-214 |
| 7(d) | `figure_07/Fig07_d.m` | Transition totals over updates 1-214 |
| 7(e) | `figure_07/Fig07_e.m` | Layout differences relative to the baseline at state 214 |

`figure_06/RUN_FIGURE_06.m` runs the four Figure 6 panels, including the
optional assignment/location panel. `figure_07/RUN_FIGURE_07.m` runs the
Figure 7 panels and their zooms. The root all-figures entry point selects
the ten numerical graphs.

## Reproduce the tables

```matlab
addpath(fullfile(pwd, 'validation', 'manuscript_tables'))
[table8, table9] = RUN_MANUSCRIPT_TABLES;
```

The default destination is `results/manuscript_tables/`; an output folder can
be supplied as the first argument. Published table snapshots are provided in
`validation/manuscript_tables/published/`.

Table 8 reproduces the eight reported fixed-layout FE comparisons. Its Abaqus
results are documentary records; this command does not run Abaqus or derive
unrounded errors from the rounded values. Table 9 contains seventeen rows:
the cantilever baseline and sixteen one-factor conditions. Each row uses its
own analysis termination or iteration cap, including the three conditions
that reach 1,000 updates. It is distinct from the equal-iteration comparison
in Figure 7.

## Iteration and transition definitions

In Figure 6(c,d), x = 1:10 identifies the update consuming FE input states
0:9. Figure 6(b) shows the assignments produced by those updates. Response
histories in Figures 6(a) and 7(c) retain state 0; they are not shifted.
Figure 7(a,b) uses post-update states or transitions 1:214. The full-history
axes extend to 250 and zoom axes to 215 for display space; data end at 214.

- A material transition changes material ID 1 to 2 or 2 to 1 while the
  element is solid in both consecutive states.
- A solid-void transition changes occupancy between consecutive states.
- Counts refer to transition events. An element can contribute repeatedly.
- Figure 7(e) divides solid-void layout differences by all 6,000 elements
  and material differences by the solids common to the two layouts.

Figure 7(b) and the baseline bars in Figure 7(d) both sum to 5,725 material
and 5,200 solid-void transitions. These totals include 2,439 material and
60 solid-void transitions at update 1. The 195-214 zoom contains 47 and
102 events, respectively; update 214 contains one and four. Initial material
classification is therefore visible separately from subsequent switching.

At state 214, the actual solid fraction is 40.00%, comprising 9.15% tensile
material and 30.85% compressive material. All material displays use M1 blue,
M2 red and void white. See [reproducibility.md](reproducibility.md) for fresh
calculations and the limits of the verification evidence.
