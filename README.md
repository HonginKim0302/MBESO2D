# MBESO2D

[![Version: 1.0.0](https://img.shields.io/badge/version-1.0.0-blue.svg)](#status)
[![MATLAB: tested R2024b](https://img.shields.io/badge/MATLAB-tested%20R2024b-orange.svg)](#requirements)

`MBESO2D` is a MATLAB implementation for stress-state-based multi-material bi-directional evolutionary structural optimization (MBESO). The code targets two-dimensional continuum topology optimization problems with two solid materials and void, where material assignment is updated from stress-state indicators and element utilization.

This repository accompanies the manuscript:

> MBESO2D: An open MATLAB implementation of stress-state-based multi-material BESO

The implementation is organized for a reproducible SoftwareX-style release: compact MATLAB solvers are kept in `src/`, manuscript examples in `examples/`, plotting/report utilities in `visualization/`, and documentation in `docs/`.

## Status

- Software name: `MBESO2D`
- Version: `1.0.0`
- Repository: https://github.com/HonginKim0302/MBESO2D
- Language: MATLAB
- License: GNU General Public License v3.0 or later (`GPL-3.0-or-later`)
- Third-party code: identified NewBESO/BESO79 portions retain their MIT notice;
  see `THIRD_PARTY_NOTICE.md`

## Contents

- [Authors](#authors)
- [Main Features](#main-features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Solver Entry Points](#solver-entry-points)
- [Materials and Units](#materials-and-units)
- [Repository Structure](#repository-structure)
- [Examples](#examples)
- [Design Masks](#design-masks)
- [Outputs and Visualization](#outputs-and-visualization)
- [Validation and Reproducibility](#validation-and-reproducibility)
- [Troubleshooting](#troubleshooting)
- [Citation](#citation)
- [Copyright and License](#copyright-and-license)

## Authors

- Hongin Kim, Department of Civil, Environmental and Architectural Engineering, Korea University, Seoul 02841, Korea
- Jaehee Choi, Department of Civil, Environmental and Architectural Engineering, Korea University, Seoul 02841, Korea
- Minsoo Sung, Department of Civil and Environmental Engineering, Ohio University, Athens, OH, USA
- Donghyuk Jung, School of Civil, Environmental and Architectural Engineering, Korea University, Seoul 02841, Korea

Corresponding authors: Minsoo Sung (`msung@ohio.edu`) and Donghyuk Jung (`jungd@korea.ac.kr`).

Public contact: `kimhongin13@korea.ac.kr`; `jungd@korea.ac.kr`.

## Main Features

- Compact 2D MBESO solver in `src/mbeso.m`
- Retained-solid and non-design-domain solver in `src/mbeso_fixed_solid.m`
- Two-material tension/compression reassignment based on recovered stress fields
- Sparse finite-element assembly and density-filtered utilization fields
- Optional line loads, material-dependent self-weight, and explicit plane-stress thickness
- Optional even keep-count correction without mirror-pair enforcement
- Plotting utilities for BESO histories, stress fields, and displacement
- Text run reports with MATLAB version, OS, CPU, RAM, timing, settings, response summary, and iteration log
- Automatic `.mat` result export for `mbeso_fixed_solid` examples

## Requirements

- Tested with MATLAB R2024b Update 7 on Windows 64-bit.
- MATLAB R2019b or later is expected to be compatible; older releases have not been regression-tested.
- No additional MATLAB toolbox is required.
- The code uses base MATLAB sparse matrices and graphics.

Large examples such as the `320 x 80` bridge-like cases require substantial time and memory.

## Installation

Clone or download the repository, open MATLAB in the repository root, and run:

```matlab
setup_mbeso_path
```

This adds `src/` and `visualization/` to the MATLAB path.

## Quick Start

Run the manuscript cantilever example with all numerical settings fixed explicitly:

```matlab
run('examples/run_cantilever.m')
```

Run a retained-solid bridge-like example:

```matlab
run('examples/run_case_3b.m')
```

For `mbeso_fixed_solid`, the example scripts write:

```text
results/mbeso_fixed_solid_run_report_YYYYMMDD_HHMMSS.txt
results/mbeso_fixed_solid_result_YYYYMMDD_HHMMSS.mat
```

The generated file paths are stored in:

```matlab
result.report_file
result.result_file
```

## Solver Entry Points

```matlab
result = mbeso(nelx, nely, volfrac, er, options);
result = mbeso_fixed_solid(nelx, nely, volfrac, er, options);
```

Use `mbeso` for the compact reference workflow and `mbeso_fixed_solid` when retained-solid or forced-void non-design regions are needed.

## Materials and Units

The default material fields are:

```matlab
materials.E1 = 200000;
materials.nu1 = 0.3;
materials.sigma_m1 = 250;
materials.E2 = 20000;
materials.nu2 = 0.3;
materials.sigma_m2 = 50;
materials.nu3 = 0.3;
materials.rho1 = 7.8e3;  % kg/m^3, fixed-solid solver
materials.rho2 = 2.4e3;  % kg/m^3, fixed-solid solver
materials.rho0 = 0;      % kg/m^3, void
```

Elastic moduli and stresses use MPa (`N/mm^2`), and assembled loads use N. No
independent `E3` is defined for void elements. Their constitutive matrix uses
`E2` as the reference modulus and `nu3` as the Poisson ratio, with stiffness
reduced by `xmin^penal` during finite-element assembly.

Density and gravity use `kg/m^3` and `m/s^2`. The fixed-solid solver converts
the physical element dimensions and plane-stress thickness to SI units for
self-weight:

```text
m_e = rho_e * A_e * t
W_e = m_e * g
```

One quarter of `W_e` is assembled at each vertical nodal degree of freedom of
the Q4 element. Thickness also multiplies the plane-stress stiffness matrix.
The bridge examples use `t = 1 m`; the cantilever uses `t = 1 mm`.

## Repository Structure

```text
MBESO2D/
  src/
    mbeso.m
    mbeso_fixed_solid.m
  examples/
    run_cantilever.m
    run_case_3b.m
    run_case_3a.m
  visualization/
    mbeso_plot_beso_evolution.m
    mbeso_plot_history.m
    mbeso_plot_stress_contours.m
    mbeso_plot_displacement.m
    mbeso_enable_displacement_datatips.m
    mbeso_write_run_report.m
  docs/
    assets/
      cantilever_boundary_conditions.png
      case_3a_boundary_conditions.png
      case_3b_boundary_conditions.png
    algorithm_overview.md
    examples.md
    input_parameters.md
    reproducibility.md
  validation/
    figures/
      cantilever_benchmark.png
      mesh_exclusion_regions_40mm.png
      mesh_resolution_study.png
      bridge_benchmarks_1m.png
      abaqus_crosscheck.png
    VALIDATION_SUMMARY.md
    reference_results.csv
    cantilever_literature_comparison.csv
    mesh_independence_reference.csv
    bridge_benchmark_reference.csv
    abaqus_crosscheck.csv
    compute_excluded_extrema.m
    run_all_validation.m
    run_mesh_independence.m
    run_regression_checks.m
  tests/
    run_smoke_tests.m
  results/
    .gitkeep
    README.md
  README.md
  AUTHORS.md
  CONTRIBUTING.md
  CITATION.cff
  CHANGELOG.md
  LICENSE
  LICENSE-NOTICE
  THIRD_PARTY_NOTICE.md
  .zenodo.json
  VERSION
  setup_mbeso_path.m
  .gitignore
```

Generated files under `results/` are ignored by Git.

## Examples

| Script | Solver | Case | Notes |
| --- | --- | --- | --- |
| `examples/run_cantilever.m` | `mbeso` | Cantilever | Compact reference example |
| `examples/run_case_3a.m` | `mbeso_fixed_solid` | Case III(a), lower retained deck | Retained 1.5 m band at the bottom |
| `examples/run_case_3b.m` | `mbeso_fixed_solid` | Case III(b), upper retained deck | Retained 1.5 m band at the top |

The mesh/plot convention places node row 1 at the top (`y = 0 m`) and node
row 81 at the bottom (`y = 40 m`). Case III(a) applies equal nodal forces on
row 78 (`y = 38.5 m`), the upper surface of the retained lower deck, with
supports at the lower-boundary endpoints on row 81. Case III(b) applies the
same load distribution and its supports on row 1, along the retained upper
deck. In both bridge cases, the deck load totals 16 MN and self-weight is
included. These discrete locations are stated explicitly for reproducibility.

See [`docs/examples.md`](docs/examples.md) for compact boundary-condition
schematics and the complete physical settings.

## Important Options

Common options include:

- `materials`: struct with `E1`, `nu1`, `sigma_m1`, `E2`, `nu2`, `sigma_m2`, and `nu3`; void stiffness uses `E2` as its reference modulus and is reduced by `xmin^penal`
- `bc_case`: `'cantilever'`, `'run_case_3b'`, or `'run_case_3a'` depending on solver
- `bc_load`: scalar load magnitude
- `r1_mm`, `r2_mm`: filter radii in millimeters after unit conversion
- `structure_width`, `structure_height`, `structure_dimension_unit`: physical dimensions
- `out_of_plane_thickness_m`: physical plane-stress thickness in meters; it scales element stiffness and, when self-weight is enabled, element mass
- `designMask`: logical design-domain mask
- `even_keep_count`: adjust an odd keep count to an even count without forcing mirror pairs
- `max_iterations`: safety limit for both solvers; default `1000`
- `plotting`: enable or disable the live material-layout figure
- `fixed_solid_mask`: logical retained-solid mask for `mbeso_fixed_solid`
- `non_design_mask`: logical forced-void mask for `mbeso_fixed_solid`
- `write_run_report`: write a text report after a run
- `run_report_file`: optional explicit report path
- `save_result`: save the returned `result` struct for `mbeso_fixed_solid`
- `result_file`: optional explicit `.mat` result path

Additional `mbeso_fixed_solid` load and analysis options include:

- `deck_line_load_N_per_m`: deck line-load magnitude in N/m
- `deck_load_distribution`: `'consistent'` for half end-node forces or `'equal_nodes'` for equal force at every loaded node
- `deck_load_node_row`: one-based mesh node row on which the deck load is applied
- `include_self_weight`, `gravity`, `gravity_load_sign`: self-weight controls
- `materials.rho1`, `materials.rho2`, `materials.rho0`: densities in kg/m^3
- `analysis_only`, `initial_x`, `initial_mi_map`, `layout_source`: evaluate a supplied fixed layout without topology updates

See [`docs/input_parameters.md`](docs/input_parameters.md) for the complete
option and output-field reference.

## Design Masks

Use `mbeso_fixed_solid` when selected elements must remain solid or void:

```matlab
fixed_solid_mask = false(nely, nelx);
fixed_solid_mask(end, :) = true;

non_design_mask = false(nely, nelx);
non_design_mask(:, 1:4) = true;

options.fixed_solid_mask = fixed_solid_mask;
options.non_design_mask = non_design_mask;
result = mbeso_fixed_solid(nelx, nely, 0.4, 0.01, options);
```

`non_design_mask` must not overlap `fixed_solid_mask`. The accepted aliases
and validation rules are listed in
[`docs/input_parameters.md`](docs/input_parameters.md). For a supplied fixed
layout, set `analysis_only = true` and provide `initial_mi_map`; the public
package does not include an Abaqus importer.

## Output Structure

The returned `result` struct includes:

- `result.x`: final density field
- `result.mi_map`: final material map (`0` void, `1` material 1, `2` material 2)
- `result.history`: iteration history
- `result.iterations`: number of completed iterations
- `result.compliance`: final objective function value
- `result.response`: displacement, stress, utilization, and objective function response fields
- `result.materials`: material properties used in the run
- `result.settings`: resolved solver settings and masks
- `result.report_file`: text report path when a report is written
- `result.result_file`: saved `.mat` file path when result export is enabled

The raw signed-utilization contour uses the unfiltered principal-stress-sum
sign. Material reassignment uses the separately filtered stress-state field.

## Outputs and Visualization

The optional plotting functions operate on the returned result structure:

```matlab
mbeso_plot_beso_evolution(result);
mbeso_plot_history(result);
mbeso_plot_stress_contours(result);
mbeso_plot_displacement(result);
```

White denotes void, red denotes tension material M1, and blue denotes
compression material M2. Stress fields are element-wise and unsmoothed. The
unfiltered signed material-utilization plot uses the principal-stress-sum sign,
whereas material reassignment uses the filtered stress-state field.

When enabled, reports and MAT files are written under `results/`; their actual
paths are returned in `result.report_file` and `result.result_file`. Generated
outputs are ignored by Git.

## Validation and Reproducibility

For manuscript reproduction:

1. Record MATLAB version, operating system, CPU, RAM, and run time from the generated report.
2. Keep the exact example scripts used for manuscript figures.
3. Run `validation/run_regression_checks.m` and `tests/run_smoke_tests.m` before tagging a release.
4. Compare the numerical summaries against the CSV files in `validation/`.
5. Review the third-party attribution.
6. Create a fixed GitHub release tag.
7. Archive the release and add the DOI to `CITATION.cff` when available.

The quantitative tables, interpretation notes, and rerun entry points are in
[`validation/VALIDATION_SUMMARY.md`](validation/VALIDATION_SUMMARY.md). The
release procedure is detailed in
[`docs/reproducibility.md`](docs/reproducibility.md).

The final manuscript validation uses full-domain responses for the primary
cantilever and 1 m bridge benchmarks. A fixed 40 x 40 mm post-processing patch
is used only in the three-resolution cantilever study; the excluded elements
remain active in both optimization and finite-element analysis.

## Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `Undefined function 'mbeso'` | `src/` is not on the MATLAB path. | Run `setup_mbeso_path`. |
| Plotting function not found | `visualization/` is not on the path. | Run `setup_mbeso_path`. |
| Expected output file is missing | The run did not finish, output is disabled, or MATLAB cached an old function. | Inspect the returned output-path/error fields, then run `clear functions; rehash`. |
| Mask-size error | A mask is not `[nely, nelx]`. | Create masks with `false(nely, nelx)`. |
| Square-element error | `structure_width/nelx` differs from `structure_height/nely`. | Make the physical dimensions and mesh aspect ratio consistent. |

## Citation

Citation metadata for the software and its principal methodology references is
provided in `CITATION.cff`. After an archived release is created, its DOI and
the final publication metadata can be added without changing the source code.

## Method and Code Provenance

The stress-based multi-material formulation follows Li and Xie (2021), and the
general soft-kill BESO framework follows Huang and Xie (2010). The immediate
implementation source for the Q4 node/DOF indexing, sparse stiffness-assembly
pattern, plane-stress element coefficient form, and sparse distance-filter
assembly was `BESO79.m` in NewBESO. The exact file-level mapping, upstream
compact-code lineage, and preserved NewBESO repository-root MIT notice are
recorded in
[`THIRD_PARTY_NOTICE.md`](THIRD_PARTY_NOTICE.md).

## Copyright and License

MBESO2D is distributed under the GNU General Public License, either version 3
of the License or, at your option, any later version
(`GPL-3.0-or-later`). Identified portions adapted from NewBESO/BESO79 retain
the upstream MIT copyright and permission notice. See `LICENSE` for the
complete GPLv3 text, `LICENSE-NOTICE` for the project-level notice, and
`THIRD_PARTY_NOTICE.md` for the source mapping and complete preserved MIT
notice. Copyright notices identify the `MBESO2D contributors`; individual
contributors retain copyright in their contributions unless otherwise agreed.

## References

1. Y. Li and Y. M. Xie, "Evolutionary topology optimization for structures made of multiple materials with different properties in tension and compression," *Composite Structures*, vol. 259, 113497, 2021. https://doi.org/10.1016/j.compstruct.2020.113497
2. X. Huang and Y. M. Xie, *Evolutionary Topology Optimization of Continuum Structures: Methods and Applications*, Wiley, 2010. https://doi.org/10.1002/9780470689486
3. Z. Zhuang and Y. M. Xie, `NewBESO`: compact MATLAB implementations of BESO79 and BESO94. https://github.com/zhuanginhongkong/NewBESO
4. E. Andreassen, A. Clausen, M. Schevenels, B. S. Lazarov, and O. Sigmund, "Efficient topology optimization in MATLAB using 88 lines of code," *Structural and Multidisciplinary Optimization*, 43, 1-16, 2011. https://doi.org/10.1007/s00158-010-0594-7
5. F. Ferrari and O. Sigmund, "A new generation 99 line Matlab code for compliance topology optimization and its extension to 3D," *Structural and Multidisciplinary Optimization*, 62, 2211-2228, 2020. https://doi.org/10.1007/s00158-020-02629-w
6. O. Sigmund, "A 99 line topology optimization code written in Matlab," *Structural and Multidisciplinary Optimization*, 21, 120-127, 2001. https://doi.org/10.1007/s001580050176
