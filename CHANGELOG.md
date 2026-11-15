# Changelog

## 2026-11-15 — Version 1.0.0 source-link correction

- Reassigned `v1.0.0` to the manuscript reproduction source so that the code URL
  printed in the manuscript opens the reviewed implementation and reproduction
  files. The software version remains 1.0.0.
- Preserved the original tag target `62584e38400df776a31de9db3eb5d46ca5e4a923` as
  `archive/v1.0.0-20260826`. Zenodo DOI `10.5281/zenodo.22109432` continues to identify that
  initial release and does not identify the revised source.
- Added permanent Table 3 source links and documented the tag correction in
  the README and reproduction guide. MATLAB code and numerical records are
  unchanged from `ee6a39a00c2f3343081cc890edb5ce155158ae80`.

## 2026-10-29 — Manuscript reproducibility update

- Organized the repository around the final manuscript numbering. Figures 6
  and 7 have dedicated folders; figure and table entry points, verification
  experiments and documentation use one consistent structure. Superseded
  figure numbers, dated add-on folders and intermediate reports are retained
  in Git history rather than in the current source tree.
- Added editable MATLAB reproduction of the final manuscript Figures 6 and 7,
  with numerical inputs, separate zooms, and optional material-assignment artwork.
- Added table reconstruction for the Abaqus comparison (Table 8) and the
  17-condition sensitivity analysis (Table 9), together with review experiments
  and an adapter for plotting newly computed histories.
- Standardized tensile M1 as blue, compressive M2 as red, and void as white.
  Reported utilization is evaluated within each assigned material region;
  signed colorbars place zero at the midpoint while retaining actual extrema.
- Added concise solver comments and the manuscript equation-to-code map.
  The FE, optimization-update and termination calculations are unchanged.
- Updated examples documentation, numerical previews and reproduction instructions.
  Recorded-data replay, a relocated source package and the fresh-history adapter
  were checked in MATLAB R2024b. No new full optimization or Abaqus run is claimed.
- Kept the software version at 1.0.0. The existing v1.0.0 release and tag are
  preserved; this dated main-branch update does not create a new release.
