# Manuscript figures

Run `RUN_MANUSCRIPT_FIGURES.m` to open the numerical panels of Figures 6 and 7.
Each panel is an editable MATLAB figure. No finite-element analysis or
optimization is performed by these plotting commands.

| Folder | Panels | Content |
| --- | --- | --- |
| `figure_06/` | (a), (b), (c), (d) | Global response, material assignments, stress-state indicators and selection scores |
| `figure_07/` | (a)–(e), with two separate zooms | Volume fractions, iteration-wise transitions and deadband comparisons |
| `common/` | Shared plotting functions | Data checks, material colors, rendering and export |
| `preparation/` | Input preparation | Extraction from newly computed verification histories |

Individual scripts, such as `figure_06/Fig06_c.m`, open one panel without
closing other figures. `RUN_FIGURE_06.m` and `RUN_FIGURE_07.m` open their
respective groups. The main entry point includes eight numerical panels and
two zooms. Figure 6(b) is an optional native reconstruction of the recorded
assignment table and material map; run `figure_06/Fig06_b.m` to include it.

From the repository root, noninteractive export and verification are:

```matlab
addpath('reproduction')
reproduce_manuscript_figures(false)
verify_manuscript_data
verify_manuscript_figures
```

Files are written to `outputs/` as FIG, 600-dpi PNG, vector PDF and Windows
EMF. The CSV tables and MAT structure in `outputs/data/` contain the actual
plotted values. `outputs/figure_manifest.csv` lists the generated artifacts.
The scripts use Times New Roman, a 560 × 400-pixel main canvas and a 560 ×
300-pixel zoom canvas, with physical export size defined at 96 pixels/inch.
PowerPoint arrows and manually arranged captions are separate composition
elements; the scripts reproduce the numerical graphs.

`figure_06/data/figure_data.mat` stores the baseline responses and the input
values used for updates 1–10. `figure_07/data/figure_data.mat` contains all
material states 0–214 for the five deadband conditions and their responses.
The data reader recomputes transition counts and layout differences from
those states. Response curves end at state 214 even where the axes extend
to 250. A transition at update k compares states k−1 and k, including update
1. Tensile–compressive changes require both states to be solid; solid–void
changes count occupancy differences. The data manifest records input hashes.

To use newly computed records, call
`prepare_manuscript_figures(freshRoot, newBundleFolder)`. It requires the
baseline `initial10/cantilever/full_history.mat` and each of the five
`zero_history/cantilever_eps_*/full_history.mat` and `state_history.csv`
pairs. The deadbands are 0, 0.005, 0.05, 0.5 and 5 MPa. Bridge results are
not required for these figures. The function creates a separate standalone
bundle and never substitutes the publication inputs for missing histories.
Run that bundle's `RUN_MANUSCRIPT_FIGURES.m` to plot its newly prepared data.

See [the manuscript reproduction guide](../docs/manuscript_reproduction.md)
for the experiment and table entry points.
