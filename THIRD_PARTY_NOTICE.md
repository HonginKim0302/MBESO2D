# Third-Party Code and Methodology Notice

MBESO2D is distributed under the GNU General Public License version 3 or
later (`GPL-3.0-or-later`). Portions of the compact finite-element
implementation were adapted from the MIT-licensed `BESO79.m` file in the
NewBESO repository. Those portions retain the upstream MIT copyright and
permission notice reproduced below.

This file distinguishes source-code adaptation from scientific-method and
implementation-lineage citations.

## Adapted implementation: BESO79 in NewBESO

- Zicheng Zhuang and Yi Min Xie, `NewBESO`, including `BESO79.m` and
  `BESO94.m`: <https://github.com/zhuanginhongkong/NewBESO>
- Upstream revision reviewed for MBESO2D:
  `e4b94dff5a93d3420fc27a6afed8fa50457318c1` (`main`, accessed
  2026-08-20).
- The repository-root `LICENSE` grants the MIT License and identifies
  `Copyright (c) 2025 ZC Zhuang TopOpt`.

The adapted implementation patterns are located in `src/mbeso.m` and
`src/mbeso_fixed_solid.m`:

| Adapted element | MBESO2D location | Modification in MBESO2D |
| --- | --- | --- |
| Structured Q4 node/DOF indexing and sparse stiffness-assembly pattern | `prepare_fem`, `FE_vectorized`, and `FE_displacement` | Extended to two solid materials, ersatz void stiffness, retained/non-design masks, multiple load definitions, self-weight, and explicit thickness. |
| Plane-stress Q4 element coefficient form | Local `lk` routines | Evaluated for two solid materials and the ersatz void material and scaled by out-of-plane thickness. |
| Sparse distance-weighted filter assembly | Local `prepare_filter` routines | Applied separately to the stress-state and material-utilization fields with independent radii. |

No NewBESO MATLAB file is redistributed as a standalone file. The adapted
patterns are incorporated under the NewBESO repository's MIT grant. The
project-level GPL license governs distribution of MBESO2D as a combined work;
the upstream MIT notice and the permissions it grants remain preserved for the
adapted portions.

The NewBESO MIT notice is reproduced in full:

> MIT License
>
> Copyright (c) 2025 ZC Zhuang TopOpt
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all
> copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
> SOFTWARE.

## Scientific formulation

The stress-based multi-material formulation and the general soft-kill BESO
framework are based on the following publications. These are scientific-method
citations rather than declarations that their source code is bundled here.

- Y. Li and Y. M. Xie, "Evolutionary topology optimization for structures made
  of multiple materials with different properties in tension and compression,"
  *Composite Structures*, 259, 113497, 2021.
  <https://doi.org/10.1016/j.compstruct.2020.113497>
- X. Huang and Y. M. Xie, *Evolutionary Topology Optimization of Continuum
  Structures: Methods and Applications*, Wiley, 2010.
  <https://doi.org/10.1002/9780470689486>

## Related compact-code lineage

NewBESO acknowledges the compact topology-optimization codes below. MBESO2D
cites them as related implementation lineage; its immediate adapted source is
the MIT-licensed NewBESO revision identified above.

- O. Sigmund, "A 99 line topology optimization code written in Matlab,"
  *Structural and Multidisciplinary Optimization*, 21, 120-127, 2001.
  <https://doi.org/10.1007/s001580050176>
- E. Andreassen, A. Clausen, M. Schevenels, B. S. Lazarov, and O. Sigmund,
  "Efficient topology optimization in MATLAB using 88 lines of code,"
  *Structural and Multidisciplinary Optimization*, 43, 1-16, 2011.
  <https://doi.org/10.1007/s00158-010-0594-7>
- F. Ferrari and O. Sigmund, "A new generation 99 line Matlab code for
  compliance topology optimization and its extension to 3D,"
  *Structural and Multidisciplinary Optimization*, 62, 2211-2228, 2020.
  <https://doi.org/10.1007/s00158-020-02629-w>

No third-party MATLAB package or toolbox is required to run MBESO2D.
