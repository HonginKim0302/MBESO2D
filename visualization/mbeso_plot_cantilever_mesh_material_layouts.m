% SPDX-License-Identifier: GPL-3.0-or-later
function fig = mbeso_plot_cantilever_mesh_material_layouts(results, plot_style)
%MBESO_PLOT_CANTILEVER_MESH_MATERIAL_LAYOUTS Compare final material layouts.
%
%   fig = mbeso_plot_cantilever_mesh_material_layouts(results)
%   fig = mbeso_plot_cantilever_mesh_material_layouts(results, plot_style)
%
% Tensile material (ID 1) is blue, compressive material (ID 2) is red, and void is white. Results are
% ordered from the coarsest to the finest mesh resolution.

if nargin < 2 || isempty(plot_style)
    plot_style = struct();
end
results = normalize_results(results);
palette = mbeso_material_palette();

mesh_widths = cellfun(@(result) size(result.x, 2), results);
[~, order] = sort(mesh_widths);
results = results(order);

font_name = get_style(plot_style, 'font_name', 'Times New Roman');
font_size = get_style(plot_style, 'material_layout_font_size', 9);
figure_width_cm = get_style(plot_style, 'material_layout_figure_width_cm', 18.0);
figure_height_cm = get_style(plot_style, 'material_layout_figure_height_cm', 4.8);

fig = figure('Color', 'w', 'Name', ...
    'Cantilever mesh-independence material layouts', 'NumberTitle', 'off');
set(fig, 'Units', 'centimeters', ...
    'Position', [2, 2, figure_width_cm, figure_height_cm], ...
    'PaperUnits', 'centimeters', ...
    'PaperPosition', [0, 0, figure_width_cm, figure_height_cm], ...
    'PaperSize', [figure_width_cm, figure_height_cm], ...
    'DefaultAxesFontName', font_name, ...
    'DefaultAxesFontSize', font_size, ...
    'DefaultTextFontName', font_name);

layout = tiledlayout(fig, 1, numel(results), ...
    'Padding', 'compact', 'TileSpacing', 'compact');

for k = 1:numel(results)
    result = results{k};
    mi_map = validate_and_get_material_map(result);
    [nely, nelx] = size(mi_map);

    ax = nexttile(layout, k);
    image(ax, material_rgb(mi_map));
    axis(ax, 'equal');
    axis(ax, 'tight');
    set(ax, 'YDir', 'reverse', 'XTick', [], 'YTick', [], ...
        'XColor', 'none', 'YColor', 'none', ...
        'FontName', font_name, 'FontSize', font_size, 'Box', 'off');
    title(ax, sprintf('%d \\times %d', nelx, nely), ...
        'Interpreter', 'tex', 'FontName', font_name, ...
        'FontSize', font_size, 'FontWeight', 'normal');
    if k == 1
        hold(ax, 'on');
        hT = plot(ax, NaN, NaN, 's', 'MarkerFaceColor', palette.tensile, 'MarkerEdgeColor', palette.tensile);
        hC = plot(ax, NaN, NaN, 's', 'MarkerFaceColor', palette.compressive, 'MarkerEdgeColor', palette.compressive);
        hV = plot(ax, NaN, NaN, 's', 'MarkerFaceColor', palette.void, 'MarkerEdgeColor', [0.4 0.4 0.4]);
        lg = legend(ax, [hT hC hV], {'Tensile material', 'Compressive material', 'Void'}, ...
            'Orientation', 'horizontal', 'Box', 'off', 'FontName', font_name, 'FontSize', font_size);
        lg.Layout.Tile = 'south';
        hold(ax, 'off');
    end
end

setappdata(fig, 'MBESO_MeshResultOrder', order);
end

function results = normalize_results(results)
if isstruct(results)
    results = num2cell(results);
end
if ~iscell(results) || isempty(results)
    error('results must be a nonempty cell array or structure array.');
end
results = results(:).';
end

function mi_map = validate_and_get_material_map(result)
if ~isstruct(result) || ~isfield(result, 'x') || isempty(result.x) || ...
        ~ismatrix(result.x)
    error('Every result must contain a nonempty two-dimensional x field.');
end
if isfield(result, 'mi_map')
    mi_map = result.mi_map;
elseif isfield(result, 'M')
    mi_map = result.M;
else
    error('Every result must contain mi_map or M.');
end
if ~isequal(size(mi_map), size(result.x))
    error('The material map must have the same size as result.x.');
end
if any(~ismember(mi_map(:), [0, 1, 2]))
    error('The material map may contain only IDs 0, 1, and 2.');
end
end

function rgb = material_rgb(mi_map)
[nely, nelx] = size(mi_map);
palette = mbeso_material_palette();
rgb = reshape(palette.map(double(mi_map(:))+1,:),nely,nelx,3);
end

function value = get_style(style, field_name, default_value)
if isfield(style, field_name) && ~isempty(style.(field_name))
    value = style.(field_name);
else
    value = default_value;
end
end
