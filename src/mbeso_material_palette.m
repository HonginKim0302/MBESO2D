% SPDX-License-Identifier: GPL-3.0-or-later
function palette = mbeso_material_palette()
%MBESO_MATERIAL_PALETTE Single material-color convention for this release.
% Material IDs are physical assignments, never inferred from stress signs.
% 0: void (white), 1: tensile M1 (blue), 2: compressive M2 (red).
% Use these fields for layouts, material legends, strips and fraction curves.
palette = struct('void',[1 1 1], 'tensile',[0 0 1], ...
    'compressive',[1 0 0], 'map',[1 1 1;0 0 1;1 0 0], ...
    'convention','0 = void (white), 1 = tensile M1 (blue), 2 = compressive M2 (red)');
end
