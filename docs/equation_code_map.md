# Manuscript equation-to-code correspondence

Table 3 maps the baseline calculations to `src/mbeso.m`. Function and
variable names identify the relevant code in addition to the source line ranges.

| Calculation and equation | Function or code variable | Source lines |
| --- | --- | --- |
| FE solution and strain energy, Eq. (1) | `FE_displacement; element_compliance; element_energy` | [286-313](https://github.com/HonginKim0302/MBESO2D/blob/7027a5a82895f32209b2a1e212bb38d7ed5601e2/src/mbeso.m#L286-L313) |
| Stress state and utilization, Eqs. (2)-(4) | `sigma_e; update_material_utilization` | [100-101](https://github.com/HonginKim0302/MBESO2D/blob/7027a5a82895f32209b2a1e212bb38d7ed5601e2/src/mbeso.m#L100-L101); [421-447](https://github.com/HonginKim0302/MBESO2D/blob/7027a5a82895f32209b2a1e212bb38d7ed5601e2/src/mbeso.m#L421-L447) |
| Spatial filtering and history averaging, Eqs. (5)-(6) | `apply_filter; eta_filtered_history; prepare_filter` | [102-110](https://github.com/HonginKim0302/MBESO2D/blob/7027a5a82895f32209b2a1e212bb38d7ed5601e2/src/mbeso.m#L102-L110); [374-398](https://github.com/HonginKim0302/MBESO2D/blob/7027a5a82895f32209b2a1e212bb38d7ed5601e2/src/mbeso.m#L374-L398) |
| Volume update and solid selection, Eqs. (7)-(8) | `vol_next; select_keep_mask` | [112-117](https://github.com/HonginKim0302/MBESO2D/blob/7027a5a82895f32209b2a1e212bb38d7ed5601e2/src/mbeso.m#L112-L117); [314-341](https://github.com/HonginKim0302/MBESO2D/blob/7027a5a82895f32209b2a1e212bb38d7ed5601e2/src/mbeso.m#L314-L341) |
| Material assignment, Eq. (8) | `mi_map` | [119-125](https://github.com/HonginKim0302/MBESO2D/blob/7027a5a82895f32209b2a1e212bb38d7ed5601e2/src/mbeso.m#L119-L125) |
| Updated-layout analysis and stopping check, Eq. (9) | `history_compliance; reached_vol; change` | [127-138](https://github.com/HonginKim0302/MBESO2D/blob/7027a5a82895f32209b2a1e212bb38d7ed5601e2/src/mbeso.m#L127-L138) |

The links above use the fixed source commit `7027a5a82895f32209b2a1e212bb38d7ed5601e2`,
archived at [DOI 10.5281/zenodo.24244523](https://doi.org/10.5281/zenodo.24244523).
Older commit links embedded in manuscript proofs are not redirected by a tag
change; use these links for the printed Table 3 line ranges.

Source SHA-256: `a267e9fa910989556375611d7e7c387bcac5425faf880cd540ff0ecc35a45336`

The hash identifies the source snapshot to which these ranges apply.
The corresponding machine-readable map is [equation_code_map.csv](equation_code_map.csv).
After editing the source, verify both the line ranges and the hash before
citing them in a manuscript. Experimental variants and their instrumentation are
documented in `validation/experiments/`.
