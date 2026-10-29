# Submitted figure reproduction, 29 October 2026

Run `RUN_SUBMITTED_FIGURES.m` to open and export the eight numerical panels
of final Figures 6 and 7 and the two separate Figure 7 zooms. Individual
`Fig06_a.m`, `Fig06_c.m`, `Fig06_d.m`, and `Fig07_*.m` scripts open one panel.
Functions resolve inputs relative to their own location, so the current
working folder does not determine which data are loaded.

```matlab
addpath('reproduction/submission_20261029');
manifest = reproduce_submitted_figures(false);
checks = verify_submitted_figures();
```

The eight original scripts and thirteen text data files are preserved without
changes in `original_plot/`; `original_plot_sha256.csv` records their hashes.
Use the canonical wrappers for portable execution and export. The original
scripts refer to the current folder, clear variables, and sometimes close an
existing figure.

| Final panel | Original Plot script | Content |
| --- | --- | --- |
| 6(a) | `Fig_6a.m` | Compliance and normalization coefficient, states 0–214 |
| 6(b), optional | No Plot script | Material assignments, updates 1–10, and state-10 layout |
| 6(c) | `Fig_6b.m` | Unfiltered and filtered stress-state indicators, decisions 1–10 |
| 6(d) | `Fig_6c.m` | Two history scores and retention threshold, decisions 1–10 |
| 7(a) | `Fig_7a.m` | Material volume fractions, states 1–214 |
| 7(b) | `Fig_7b.m` | Transition events, updates 1–214, plus zoom |
| 7(c) | `Fig_7c.m` | Compliance differences, states 0–214, plus zoom |
| 7(d) | `Fig_7d.m` | Cumulative transition events, updates 1–214 |
| 7(e) | `Fig_7e.m` | Layout differences at state 214 |

`Fig06_b.m` or `RUN_SUBMITTED_ASSIGNMENT.m` separately reconstructs an editable
assignment table and state-10 material map from the actual material states.
Its layout is a native reconstruction of the submitted PowerPoint content.

In recorded mode, curve values come from the submitted text files and are
checked against the archived MAT inputs. Transition totals and layout
differences are recalculated from consecutive archived material maps in
`../figure_09/data/source_states_0_214.mat`. Update 1 compares state 0 with
state 1 and is included. For the zero-deadband case, the first update contains
60 solid–void and 2,439 tensile–compressive events; all 214 updates sum to
5,200 and 5,725, respectively. Layout occupancy differences use all 6,000
elements; material differences use the common solid subset for each case.

When the parent reproduction folder contains `fresh_source.json`, all curve
values are instead read or derived from that bundle's freshly prepared MAT
inputs. Required MAT files must exist; the functions do not fall back to the
submitted text files in fresh mode. The output manifest records `source_mode`.

Main plots use the submitted Times New Roman 18-point axes and 560 × 400-pixel
canvas. Zooms use 24-point axes and 560 × 300 pixels. Physical export size uses
96 pixels per inch. Main horizontal axes retain the submitted empty space
through 250, and zoom axes extend to 215, while data stop at 214. Figure 7(b)'s
zoom explicitly sets its vertical range to 0–10, which the original script
omitted. Figure 7(c) uses the submitted PowerPoint's southeast legend and MPa
units. Colors follow the submitted plots, including red/green transition bars;
these colors are separate from the blue/red material-map palette.
Material maps, assignment keys and tensile/compressive volume curves read
the shared `mbeso_material_palette` through `../mbeso_reproduction_palette.m`.
That adapter resolves the repository source or a fresh bundle's support copy.

`outputs/` receives editable FIG files, 600-dpi PNG files, vector PDF files
with embedded fonts, and EMF files on Windows. `generated_inputs/` contains
the actual plotted numerical arrays, and `generated_artifacts.csv` lists the
exports. `verify_submitted_figures.m` checks saved native plot arrays against
those inputs, transition totals, and PNG dimensions in either source mode.

The numeric plots do not reproduce the manually positioned PowerPoint
annotation overlays or promise identical pixels across MATLAB releases.
The unchanged submitted PowerPoint is the reference for those composition
details. These scripts use native MATLAB graphics and require no plotting
toolbox or external executable.
