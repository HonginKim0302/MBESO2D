# Manuscript equation-to-code correspondence

This corresponds to Table 3 of the submitted revision checked on 2026-10-29.
The table retains the equation/function/range mapping recorded on 2026-10-20;
teaching comments and source ranges remain those of the 2026-10-14 annotated
snapshot. Ranges refer to `src/mbeso.m`.
Function and variable names provide anchors when line numbers change.

| Calculation and equation | Function or code variable | Source lines |
| --- | --- | --- |
| FE solution and strain energy, Eq. (1) | `FE_displacement; element_compliance; element_energy` | 286-313 |
| Stress state and utilization, Eqs. (2)-(4) | `sigma_e; update_material_utilization` | 100-101; 421-447 |
| Spatial filtering and history averaging, Eqs. (5)-(6) | `apply_filter; eta_filtered_history; prepare_filter` | 102-110; 374-398 |
| Volume update and solid selection, Eqs. (7)-(8) | `vol_next; select_keep_mask` | 112-117; 314-341 |
| Material assignment, Eq. (8) | `mi_map` | 119-125 |
| Updated-layout analysis and stopping check, Eq. (9) | `history_compliance; reached_vol; change` | 127-138 |

Source SHA-256: `a267e9fa910989556375611d7e7c387bcac5425faf880cd540ff0ecc35a45336`

The source hash identifies the annotated solver snapshot used for this manuscript.
The FE, optimization-update and termination calculations are unchanged from
the original public implementation; comments and material-display code are updated.
The source references are snapshot-specific; update these ranges if the file
is edited again. The correspondence describes the baseline public solver.
Declared review variants and their instrumentation are documented separately.

Two routine names were made explicit here: `element_energy` is already inside
the FE/energy range, and `prepare_filter` is already inside the filter range.
These are clarifications of the original Table 3, not algorithm changes.
