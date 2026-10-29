# Manuscript equation-to-code correspondence

Table 3 relates the baseline calculations to `src/mbeso.m`. Function and
variable names provide anchors in addition to the source line ranges.

| Calculation and equation | Function or code variable | Source lines |
| --- | --- | --- |
| FE solution and strain energy, Eq. (1) | `FE_displacement; element_compliance; element_energy` | 286-313 |
| Stress state and utilization, Eqs. (2)-(4) | `sigma_e; update_material_utilization` | 100-101; 421-447 |
| Spatial filtering and history averaging, Eqs. (5)-(6) | `apply_filter; eta_filtered_history; prepare_filter` | 102-110; 374-398 |
| Volume update and solid selection, Eqs. (7)-(8) | `vol_next; select_keep_mask` | 112-117; 314-341 |
| Material assignment, Eq. (8) | `mi_map` | 119-125 |
| Updated-layout analysis and stopping check, Eq. (9) | `history_compliance; reached_vol; change` | 127-138 |

Source SHA-256: `a267e9fa910989556375611d7e7c387bcac5425faf880cd540ff0ecc35a45336`

The hash identifies the source snapshot to which these ranges apply.
The corresponding machine-readable map is [equation_code_map.csv](equation_code_map.csv).
If the source is edited, verify both the ranges and the hash before using
them in a manuscript. Experimental variants and their instrumentation are
documented in `validation/experiments/`.
