# Figure 7 inputs

`figure_data.mat` contains structure `F7`. Deadband cases are ordered
0, 0.005, 0.05, 0.5 and 5 MPa. `phase` has dimensions 6000 × 215 × 5;
its second coordinate represents states 0–214. `C_Nmm` and the independent
state-history reference arrays retain the recorded responses and counts.
`baseline_volume_percent` contains solid, tensile and compressive fractions.
`compliance_difference_percent` uses the baseline response at the same state.

Every transition is recounted from consecutive material states. The total
window is updates 1–214 and the enlarged window is updates 195–214. Layout
differences use state 214: occupancy changes are divided by 6000 elements,
and material changes are divided by the common solid set. First termination
states are retained separately from this common comparison window.
