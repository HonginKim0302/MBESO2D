# Material plotting convention

The material colors for this repository are:

| Material ID | Meaning | Display color |
| --- | --- | --- |
| 0 | Void | White |
| 1 (M1) | Tensile material | Blue |
| 2 (M2) | Compressive material | Red |

Use `src/mbeso_material_palette.m` as the shared source for material layouts,
assignment strips, material legends and material-labeled curves. Keep this
mapping consistent in examples, live solver figures, mesh-consistency plots
and manuscript reproduction. Never swap material IDs to change plot colors.

Material colors are defined by material IDs, not by a reference image.
Preserve numerical data and use the shared palette when changing a plot.
Explicit user instructions take precedence over this convention.

Stress-magnitude colormaps represent physical field values, not material IDs.
Do not reverse a von Mises or other magnitude colormap just to enforce the
categorical material colors. Signed utilization is +M1 and -M2 with each
assigned material's own allowable stress; display edits must not alter those
computed values, material assignments or optimization updates.

After changing material plotting, verify the rendered M1/M2 colors and their
legend entries against the material IDs, including mesh and manuscript plots.
