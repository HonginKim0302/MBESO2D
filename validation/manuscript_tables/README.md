# Submitted Tables 8 and 9 and historical table records

Submitted Table 9 includes the baseline plus **16 one-factor variants (17 rows)**.
The three added classification deadbands are **0.05, 0.5 and 5 MPa**.
Their archived first response stops are updates **153, 216 and 133**,
respectively. These are not the common-update-214 states used in Figure 7.
The 0.5 MPa run terminates at update 216, beyond that figure's common window;
the other added cases terminate earlier and retain their histories when
continued to update 214 for the figure.

From the repository root:

```matlab
addpath(fullfile(pwd,'validation','manuscript_tables'))
[table8,table9] = RUN_SUBMISSION_TABLES;
```

Outputs default to `results/submission_tables/`: `Table08_Abaqus_comparison.csv`,
`Table09_one_factor_sensitivity.csv`, `Table08.md`, `Table09.md`, a MAT bundle
and a JSON status record. Historical outputs are placed in the
`legacy_reporting/` subfolder. No FE solves are run by this function. Submitted Table 8 uses `../abaqus_crosscheck.csv`, the documentary
MBESO2D/Abaqus final-layout comparison. Its reported difference of <0.01%
is transcribed from the manuscript, not recalculated from rounded values.
Abaqus jobs are not bundled.

The original `RUN_MANUSCRIPT_TABLES` function remains available. Its two
outputs and the reference files in `published/` retain 23 October numbering:
`Table8` is the historical C/2C reporting comparison and `Table10` is the
sensitivity study now numbered Table 9. These old filenames do not identify
the current submitted table numbers; the submitted paper has no Table 10.

For newly computed runs, compute the three baselines and the full sensitivity
set in the same output folder, then generate the tables:

```matlab
repoRoot = pwd;
freshRoot = fullfile(repoRoot,'results','fresh_review');
addpath(fullfile(repoRoot,'validation','review'), ...
        fullfile(repoRoot,'validation','manuscript_tables'));
run_review_experiments('baselines',freshRoot);
run_review_experiments('sensitivity',freshRoot);
[table8,table9] = RUN_SUBMISSION_TABLES( ...
    fullfile(freshRoot,'manuscript_tables'),freshRoot);
```

The second argument may be the fresh review root or its `runs` directory.
The sensitivity reconstruction requires the 17 cantilever conditions.
The retained table engine also uses two bridge baselines for its historical
C/2C audit, so the complete fresh workflow above supplies 19 endpoint records.
Fresh optimization results do not replace the documentary Abaqus comparison.
The function never substitutes archived endpoint fields for missing fresh results.

For the three added deadbands only, if `runs/<run_id>/result.mat` is absent,
the function also accepts `zero_history/<run_id>/full_history.mat` from the
**same fresh root**. It extracts `phase(:,first_stop+1)`,
`state_vm(:,first_stop+1)` and `C(first_stop+1)` because column 1 is state 0.
This supports previously completed history runs. A continuation endpoint is
not accepted in place of the recorded first stop. The detailed JSON status under `legacy_reporting/` lists the actual file,
hash, source kind and state used for every fresh sensitivity row.

To rerun only the baseline and three additional cases, open
`validation/review/RUN_ADDITIONAL_DEADBANDS.m` or call
`run_review_experiments('deadband_extension')`. That four-run subset produces
its own summary; it does not by itself supply all sensitivity inputs for
submitted Table 9 or the complete historical table audit.

## Inputs and definitions

- `data/tables_input.mat`: compact endpoint element fields from 17 cantilever
  conditions (baseline + 16 variants) and two bridge baselines. Includes material
  assignments, solid indicator, centroidal VM, strengths, C, and termination.
- `data/source_manifest.csv`: original result/history-file identifiers and
  SHA-256 hashes. Added rows originate from recorded first-stop states, not
  values typed from the manuscript.
- `data/sensitivity_archived.csv`: independently stored sensitivity summary used
  to check the compact-field reconstruction, including recorded endpoint-cycle metadata.
- `data/reference_compliance.csv`: literature numbers and explicit unconfirmed
  convention caveat. This is reference transcription, not a fresh FE result.

The historical C/2C table (23 October Table 8) retains N·mm for I(b) and converts to MN·m for the bridges, then
compares C and 2C conditionally. In particular, the bridge values 2.55215 and
1.67516 are in MN·m. It does not fit a calibration multiplier.

Submitted Table 9 (23 October Table 10) recomputes maximum VM over all solids and maximum `VM/strength` inside
actual M1 and M2 elements separately. Strengths are 250 MPa and 50 MPa. Both
utilization maxima are nonnegative magnitudes. The manuscript uses a negative
sign to display the compressive-material maximum; that signed presentation
is the negative of the M2 magnitude, not a minimum selected over all solids.
Neither magnitude is obtained by taking the absolute value of an old
stress-sign contour. No 40 mm exclusion is used.

Each variant is evaluated at its own endpoint. Three rows reach 1,000 updates
without meeting the response criterion. Endpoint-only fresh files cannot prove
a final two-cycle, so their `final_period2` metadata are NaN; consult the full
history before making a cycle claim. The archived metadata remain traceable.
