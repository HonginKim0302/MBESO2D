# Recorded reference results

These files preserve the earlier review experiments and their provenance.
In particular, `zero_history/` includes the former 264-state and additional
50-update protocol. Those records are not the data source for the final
submitted manuscript Figure 7.

The retained numerical source records are under `reproduction/figure_09/data/`;
the folder name follows the earlier numbering. Submitted Figure 7(c) retains
response states 0–214; fractions and transitions in 7(a,b) use updates 1–214.
Panel (d) includes the initial-to-first-state comparison, and panel (e) uses
layouts at state 214. State 0 remains the source for the first transition.
The 23 October replay instead summed transitions over 2–214; that convention
is historical and must not replace the submitted counts.
`run_review_experiments('histories', output_root)` regenerates this common
window and retains each condition's first termination state for submitted Table 9.
The old protocol remains available through the explicit `legacy_histories`
mode; it is excluded from the default `all` mode.
