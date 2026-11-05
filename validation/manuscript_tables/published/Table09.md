# Table 9. One-factor endpoint sensitivity

Each condition is reported at its own analysis-termination point or iteration cap. All stresses are centroidal and evaluated over all solid elements. Assigned-material utilization uses M1 = 250 MPa and M2 = 50 MPa; the M2 maximum magnitude is shown with a minus sign.

| Setting | C change (%) | Peak VM (MPa) | M1 (%) | Signed M2 (%) | Iterations | Termination |
|---|---:|---:|---:|---:|---:|---|
| manuscript baseline | +0.00 | 128.91 | 51.56 | -59.79 | 214 | response_criterion |
| stress_measure=gauss_mean_vm | -1.02 | 128.93 | 51.57 | -57.65 | 1000 | max_iterations |
| stress_measure=gauss_max_vm | -0.89 | 128.96 | 51.58 | -56.24 | 1000 | max_iterations |
| r1_mm=15 | +1.03 | 128.86 | 51.54 | -60.65 | 154 | response_criterion |
| r1_mm=25 | +1.46 | 128.86 | 51.54 | -62.61 | 158 | response_criterion |
| r2_mm=20 | +7.57 | 128.82 | 51.53 | -65.21 | 1000 | max_iterations |
| r2_mm=40 | +3.20 | 128.78 | 51.51 | -59.82 | 127 | response_criterion |
| material_zero_tolerance=5e-07 | +0.00 | 128.91 | 51.56 | -59.79 | 214 | response_criterion |
| material_zero_tolerance=5e-05 | +0.00 | 128.91 | 51.56 | -59.79 | 214 | response_criterion |
| material_zero_tolerance=0.005 | +4.52 | 128.80 | 51.52 | -63.76 | 117 | response_criterion |
| material_zero_tolerance=0.05 | +1.87 | 128.84 | 51.54 | -61.16 | 153 | response_criterion |
| material_zero_tolerance=0.5 | -0.47 | 128.90 | 51.56 | -58.73 | 216 | response_criterion |
| material_zero_tolerance=5 | +2.48 | 128.92 | 51.57 | -59.14 | 133 | response_criterion |
| volume_rounding=round | -0.14 | 128.93 | 51.57 | -58.30 | 232 | response_criterion |
| volume_rounding=ceil | +0.75 | 128.94 | 51.58 | -59.80 | 179 | response_criterion |
| tie_policy=reverse | +0.00 | 128.91 | 51.56 | -59.79 | 214 | response_criterion |
| tie_policy=fixed_random | +0.00 | 128.91 | 51.56 | -59.79 | 214 | response_criterion |
