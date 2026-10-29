# Manuscript tables

`RUN_MANUSCRIPT_TABLES.m` reconstructs Tables 8 and 9. It writes CSV, Markdown
and MAT files and a machine-readable generation record. It does not run FE
analysis.

From the repository root:

```matlab
addpath(fullfile(pwd,'validation','manuscript_tables'));
[table8,table9] = RUN_MANUSCRIPT_TABLES();
```

Outputs are written to `results/manuscript_tables/`. The CSV and Markdown
snapshots in `published/` contain the bundled-data results:

- `Table08_Abaqus_comparison.csv` and `Table08.md`: eight reported comparisons.
- `Table09_one_factor_sensitivity.csv` and `Table09.md`: 17 sensitivity cases.

## Table 8: fixed-layout FE comparison

The source is `validation/abaqus_crosscheck.csv`. These are rounded MBESO2D and
Abaqus values supplied for the matched final layouts. The reported relative
difference bound is copied from the comparison record; it is not calculated
from rounded numbers. Abaqus input files and databases are not bundled, so
this table is documentary evidence rather than a new external FE verification.

## Table 9: endpoint sensitivity

`data/tables_input.mat` contains the actual endpoint material maps, density
variables and centroidal von Mises fields. The generator recomputes the
compliance change, maximum stress and assigned-material maxima and checks them
against `data/sensitivity_archived.csv`. The baseline and 16 one-factor variants
are reported at their own analysis termination or iteration cap. Gauss mean,
Gauss maximum and the 20 mm second filter radius reach 1,000 updates and must
not be labeled converged.

M1 and M2 utilization are calculated inside their assigned-material subsets,
using strengths of 250 and 50 MPa. Positive maxima are retained in the data;
`M2_signed_utilization_percent` supplies the negative display value used in the
manuscript. All stress extrema cover the complete solid domain.

## Fresh endpoint calculations

```matlab
repoRoot = pwd;
freshRoot = fullfile(repoRoot,'results','sensitivity');
addpath(fullfile(repoRoot,'validation','experiments'), ...
        fullfile(repoRoot,'validation','manuscript_tables'));
run_verification_experiments('sensitivity',freshRoot);
[table8,table9] = RUN_MANUSCRIPT_TABLES( ...
    fullfile(repoRoot,'results','fresh_tables'),freshRoot);
```

The second argument may be the experiment output root or its `runs/` directory.
Only the 17 cantilever sensitivity cases are required; bridge runs are not
needed. Missing fresh input causes an error, with no bundled-data fallback.
For the 0.05, 0.5 and 5 MPa cases, a recorded `zero_history/<run_id>/full_history.mat`
is also accepted. Its `first_stop` state is extracted explicitly. A common-state
214 result or a continued endpoint cannot replace the first-stop value.

`table_generation_status.json` records input paths, hashes and selected states.
Bundled endpoint MAT data also contain two bridge baseline records for source
context; those records do not enter Table 9. The hashes in
`data/source_manifest.csv` identify the source experiment records from which
the compact fields were extracted. Those full source records are not bundled.
The final-cycle classification is supplied only for bundled histories; a fresh
endpoint alone cannot establish a two-cycle and is reported as `NaN`.
