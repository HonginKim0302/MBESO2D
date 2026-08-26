# Reproducibility Notes

This document summarizes the recommended reproduction workflow for `MBESO2D` version `1.0.0`.

## Setup

Open MATLAB in the repository root:

```matlab
setup_mbeso_path
```

The repository uses base MATLAB only. It has been tested with MATLAB R2024b
Update 7 on Windows 64-bit. MATLAB R2019b or later is expected to be compatible
with the plotting utilities, but older releases have not been regression-tested.

## Example Runs

Run individual examples:

```matlab
run('examples/run_cantilever.m')
run('examples/run_case_3a.m')
run('examples/run_case_3b.m')
```

The bridge-like fixed-solid examples are large and can take substantial time to run.

## Fixed Physical Conditions

The public examples define their numerical conditions directly in the scripts.
The principal conditions that must not be inferred from solver defaults are:

| Example | Mesh | Dimensions | Thickness | External load | Self-weight |
| --- | --- | --- | --- | --- | --- |
| Cantilever | 100 x 60 | 1000 x 600 mm | 1 mm | 1000 N point load | No |
| Case 3a | 320 x 80 | 160 x 40 m | 1 m | 100 kN/m over 160 m, equal nodes, row 78 above the lower deck | Yes |
| Case 3b | 320 x 80 | 160 x 40 m | 1 m | 100 kN/m over 160 m, equal nodes, upper row 1 | Yes |

Both bridge examples use `rho1 = 7800 kg/m^3`, `rho2 = 2400 kg/m^3`,
`rho0 = 0`, and `g = 9.81 m/s^2`. The total prescribed deck load is 16 MN.
Self-weight is recomputed from the current material layout at every finite-
element analysis.

## Generated Files

Text reports contain MATLAB version, release, computer type, operating system, CPU, CPU core count, physical RAM when available, run settings, run time, response summary, and full iteration log.

Expected generated file patterns:

```text
results/mbeso_run_report_*.txt
results/mbeso_fixed_solid_run_report_*.txt
results/mbeso_fixed_solid_result_*.mat
```

Generated files are ignored by Git. The empty `results/` directory is preserved by `results/.gitkeep`.

## Numerical Baselines

Compact reference values and comparison rules are stored in:

```text
validation/VALIDATION_SUMMARY.md
validation/reference_results.csv
validation/cantilever_literature_comparison.csv
validation/mesh_independence_reference.csv
validation/bridge_benchmark_reference.csv
validation/abaqus_crosscheck.csv
```

The executable baseline includes convergence status, iteration count,
compliance, solid ratio, material counts, and full-domain response extrema.
The mesh study uses a fixed 40 x 40 mm exclusion only for extrema evaluation.
The bridge baseline uses a 1 m out-of-plane thickness and full-domain response
values. These data are intended to detect unintended code or example changes;
they are not a claim that all MATLAB releases or sparse linear-algebra
libraries will produce an identical discrete topology.

## Release Checklist

Before creating a GitHub release:

1. Run the manuscript example scripts and keep the generated reports outside the Git repository.
2. Confirm all figure/table inputs are fixed in the example scripts.
3. Compare the results with `validation/reference_results.csv`.
4. Confirm that the copyright, GPL, and preserved third-party MIT notices are
   current and complete.
5. Remove generated MAT/report files and unreferenced documentation assets from the upload package.
6. Update `README.md` and `CITATION.cff` with final public metadata.
7. Create a Git tag such as `v1.0.0`.
8. Archive that exact tag and add the archival DOI to `CITATION.cff`.

## Reporting Computational Environment

For each manuscript result, report at least:

- MATLAB version and release,
- operating system,
- CPU model and core count,
- RAM,
- mesh size,
- material constants,
- filter radii,
- boundary/load case,
- line-load distribution and loaded node row,
- densities, gravity, and out-of-plane thickness when self-weight is used,
- run time,
- Git release tag and DOI.
