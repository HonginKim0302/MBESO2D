# Manuscript figure sources

[figure_sources.pptx](figure_sources.pptx) contains the editable composition
of Figures 1-7: panel labels, connectors, callouts, schematics and assembled
numerical graphs. Its eighteen slides correspond to the manuscript panels.
[source_manifest.json](source_manifest.json) identifies the presentation
and numerical input records.

The MATLAB scripts reproduce numerical curves, bars, axes and legends from
the recorded data. They export FIG, PNG, PDF and Windows EMF to
`reproduction/outputs/`. Manual annotations and slide composition remain
editable in the PowerPoint source.

| Panel | Content | Preview |
| --- | --- | --- |
| 6(a) | Compliance and normalization coefficient | [PNG](reproduced/Fig06_a.png) |
| 6(b), optional native reconstruction | Assignments and locations at update 10 | [PNG](reproduced/Fig06_b.png) |
| 6(c) | Stress-state indicators for element 974 | [PNG](reproduced/Fig06_c.png) |
| 6(d) | History-averaged scores and retention threshold | [PNG](reproduced/Fig06_d.png) |
| 7(a) | Actual solid and material fractions | [PNG](reproduced/Fig07_a.png) |
| 7(b) | Per-update transitions, 1-214 | [PNG](reproduced/Fig07_b.png) |
| 7(b), zoom | Per-update transitions, 195-214 | [PNG](reproduced/Fig07_b_zoom.png) |
| 7(c) | Compliance differences at equal iterations | [PNG](reproduced/Fig07_c.png) |
| 7(c), zoom | Compliance differences, 195-214 | [PNG](reproduced/Fig07_c_zoom.png) |
| 7(d) | Cumulative transitions, 1-214 | [PNG](reproduced/Fig07_d.png) |
| 7(e) | Layout differences at iteration 214 | [PNG](reproduced/Fig07_e.png) |

The all-figures command exports the ten numerical graphs, including two
zooms. Figure 6(b) also has an individual native script; it reproduces the
material records but does not duplicate the manually assembled composition
pixel for pixel. Full-history axes extend to 250 and zoom axes to 215;
the data end at 214.

See the [manuscript guide](../../manuscript_reproduction.md) for individual
scripts and numerical definitions, and the
[reproduction workflow](../../reproducibility.md) for fresh calculations.
