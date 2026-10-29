# Figure 6 inputs

`figure_data.mat` contains structure `F6`. `response_state`, `C_Nmm` and
`normalization_coefficient` describe physical states 0–214. The indicator,
score and threshold vectors are inputs to updates 1–10, corresponding to
FE states 0–9. The two score columns and assignment rows use elements
974 and 5829, in that order. `material_state10` is the actual 60 × 100
material map after update 10. Material IDs are 0 void, 1 tensile and
2 compressive. These data are checked against the Figure 7 state history.
