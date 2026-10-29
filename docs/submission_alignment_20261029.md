# Submitted-revision alignment, 29 October 2026

This record identifies the correspondence between the submitted manuscript,
its figure sources and the repository reproduction routes. The submitted
paper has Figures 1–7 and Tables 1–9. Earlier numbered records remain
available as dated evidence.

## Figure correspondence

| Submitted panel | Numerical or graphical content | 23 October counterpart |
| --- | --- | --- |
| 6(a) | Compliance C and normalization coefficient nk | 8(a) |
| 6(b) | Material/void histories over updates 1–10 and locations after update 10 | 8(d,e), combined |
| 6(c) | Unfiltered and filtered stress-state indicators, element 974 | 8(b) |
| 6(d) | History-averaged scores, elements 974/5829, and retention threshold | 8(c) |
| 7(a) | Actual solid, tensile and compressive fractions | 9(e) |
| 7(b) | Per-update transitions and final-20-update inset | 9(f), with update 1 included |
| 7(c) | Deadband compliance differences at equal iterations | 9(b) |
| 7(d) | Cumulative transition counts over updates 1–214 | 9(c), with update 1 included |
| 7(e) | Layout differences at iteration 214 | 9(d) |

Figures 6(a) and 7(c) retain response states 0–214. Figure 6(c,d) uses
FE input states 0–9 at the consuming update coordinates 1–10. Figure 7(a,b)
uses post-update states/updates 1–214. Full-history axes span 0–250; zoom
axes span 195–215. The last numerical datum remains at 214.

State 0 is retained as the preceding state for update 1. The baseline first
update contributes 2,439 tensile–compressive transitions and 60 solid–void
transitions. Totals over 1–214 are 5,725 and 5,200, respectively. The earlier
2–214 totals, 3,286 and 5,140, exclude that first redistribution and apply
only to the historical replay. Transitions are events, so repeated changes
of the same element are counted separately.

## Table scope and retained discrepancy

Submitted Table 8 is the fixed-layout MBESO2D/Abaqus response comparison,
formerly Table 9. Its reported difference of less than 0.01% is transcribed
from the submission; it is not recalculated from the rounded table entries.
Submitted Table 9 is the baseline plus 16 one-factor variants, formerly
Table 10. Each row uses its own termination or iteration cap. Three capped
variants retain their 1,000-update status.

The former C/2C reporting-convention Table 8 and bridge energy graphs remain
historical evidence outside the submitted table/figure set.

Generated [Table 8 and Table 9 previews](../validation/manuscript_tables/published/submission_20261029/README.md)
and their CSV data are provided for inspection without MATLAB.

Submitted Table 7 reports Case III(a) signed compressive utilization as
−273.99%. The retained raw value is −273.98497258879286%, which ordinarily
rounds to −273.98% at two decimal places. This small presentation discrepancy
is recorded without changing the raw result or solver.

## Source and execution scope

Relative to the original public version, `src/mbeso.m` and
`src/mbeso_fixed_solid.m` include educational comments and shared-palette
display changes. Their FE, optimization-update and termination calculations
are unchanged. The material palette is tensile M1 blue, compressive M2 red
and void white. The [Table 3 equation-to-code mapping](equation_code_map.md)
identifies the annotated source ranges and source hash.

Native MATLAB validation for this alignment passed in R2024b. No native
R2023a execution is claimed. Recorded-data replay and table reconstruction
perform no new optimization or Abaqus analysis.
The fresh-history adapter also passed a separate R2024b data-flow check
using previously recorded FE histories and an audit fixture. Its 22 compared
fields agreed within a maximum absolute difference of 5.6843418860808015e−13.
The check succeeded with the submitted TXT inputs unavailable. A controlled
change to one recorded material state changed the derived final transition
count and tensile fraction, and the input was restored after the check.
Exports were exercised in FIG, PNG, PDF and EMF formats.

An extracted source archive also passed execution from a different working
directory with the default MATLAB path restored. All ten numerical panel
scripts, the optional assignment script, 81 output/data checks and both
table generators passed. The [machine-readable validation record](../validation/submission_alignment_checks_20261029.json)
records the scope and protected source hashes.

The public-main candidate additionally passed small-model solver smoke tests,
material-palette checks and assigned-material utilization tests in R2024b.
These checks execute small FE/optimization cases. They do not constitute a
rerun of the full optimization study or Abaqus analyses.

This check verifies that the adapter derives outputs from the supplied
histories. The `fresh_history` source label identifies that data path; the
fixture check did not execute a new FE solve or optimization. It does not
establish fresh full-study reproduction or native R2023a compatibility.
Replay and adapter checks do not resolve the retained bridge-reference
discrepancy or the recorded intermediate-state FE tolerance exceedances.

The submitted reference list identifies DOI `10.5281/zenodo.22109432`.
Its association with this exact source revision remains unverified. This
status makes no determination about the DOI's validity, and this alignment
does not announce a new release or archive deposit.

The [reproduction guide](manuscript_reproduction.md) provides current and
historical commands. The [submitted figure gallery](assets/manuscript_20261029/README.md)
separates the PowerPoint composition from native numerical previews.
