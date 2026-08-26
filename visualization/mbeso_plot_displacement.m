% SPDX-License-Identifier: GPL-3.0-or-later
% Copyright (C) 2026 MBESO2D contributors
function fig = mbeso_plot_displacement(result)
%MBESO_PLOT_DISPLACEMENT Plot the final deformed optimized structure.
%
%   fig = mbeso_plot_displacement(result)
%
% The displayed geometry uses the true displacement scale (scale = 1).

scale = 1.0;

response = require_response(result);
x = result.x;
[nely, nelx] = size(x);
elSize = result.settings.elSize;
xmin = result.settings.xmin;
solid_mask = x > xmin;

U = response.U(:);
used_node_mask = false((nely + 1) * (nelx + 1), 1);

fig = figure('Color', 'w', 'Name', 'MBESO displacement', 'NumberTitle', 'off');
set_figure_font(fig);
ax = axes('Parent', fig);
hold(ax, 'on');

for elx = 1:nelx
    for ely = 1:nely
        if ~solid_mask(ely, elx)
            continue;
        end

        n1 = (nely + 1) * (elx - 1) + ely;
        n2 = (nely + 1) * elx + ely;
        nodes = [n1, n2, n2 + 1, n1 + 1];
        used_node_mask(nodes) = true;

        x0 = elSize * [elx - 1, elx, elx, elx - 1];
        y0 = elSize * [ely - 1, ely - 1, ely, ely];
        ux_nodes = U(2 * nodes - 1).';
        uy_nodes = U(2 * nodes).';
        c_value = mean(sqrt(ux_nodes.^2 + uy_nodes.^2));

        patch(ax, x0 + scale * ux_nodes, y0 + scale * uy_nodes, c_value * ones(1, 4), ...
            'EdgeColor', 'none', 'FaceColor', 'flat');
    end
end

axis(ax, 'equal');
axis(ax, 'tight');
set(ax, 'YDir', 'reverse');
set(ax, 'Color', [1 1 1]);
set(ax, 'FontName', 'Times New Roman', 'FontSize', 11);
colormap(ax, parula(256));
cb = colorbar(ax);
set(cb, 'FontName', 'Times New Roman', 'FontSize', 10);
cb.Label.String = 'Displacement magnitude';
cb.Label.FontName = 'Times New Roman';
xlabel(ax, 'x', 'FontName', 'Times New Roman');
ylabel(ax, 'y', 'FontName', 'Times New Roman');
title(ax, {'Deformed final structure (scale = 1)', ...
    'Click the structure for actual nodal ux and uy'}, ...
    'FontName', 'Times New Roman', 'FontWeight', 'normal');

datatip_data = make_2d_displacement_datatip_data( ...
    U, used_node_mask, nely, nelx, elSize, scale);
mbeso_enable_displacement_datatips(fig, datatip_data);
end

function data = make_2d_displacement_datatip_data(U, used_node_mask, nely, nelx, elSize, scale)
node_ids = find(used_node_mask);
if isempty(node_ids)
    error('No retained topology nodes are available for displacement datatips.');
end

nodenrs = reshape(1:(nely + 1) * (nelx + 1), nely + 1, nelx + 1);
[node_row, node_col] = ind2sub(size(nodenrs), node_ids);
original_x = (node_col - 1) * elSize;
original_y = (node_row - 1) * elSize;
ux = U(2 * node_ids - 1);
uy = U(2 * node_ids);

data = struct( ...
    'node_ids', node_ids, ...
    'original_x', original_x, ...
    'original_y', original_y, ...
    'display_x', original_x + scale * ux, ...
    'display_y', original_y + scale * uy, ...
    'ux', ux, ...
    'uy', uy, ...
    'scale', scale, ...
    'unit', 'mm');
end

function set_figure_font(fig)
set(fig, 'DefaultAxesFontName', 'Times New Roman', 'DefaultTextFontName', 'Times New Roman');
end

function response = require_response(result)
if ~isfield(result, 'response') || isempty(result.response)
    error('The result structure does not contain response fields. Re-run mbeso with the current version.');
end
response = result.response;
end
