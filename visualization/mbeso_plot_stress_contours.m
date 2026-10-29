% SPDX-License-Identifier: GPL-3.0-or-later
% Copyright (C) 2026 MBESO2D contributors
function fig = mbeso_plot_stress_contours(result)
%MBESO_PLOT_STRESS_CONTOURS Plot final stress and utilization contours.
%
%   fig = mbeso_plot_stress_contours(result)
%
% The input result is the structure returned by mbeso.

response = require_response(result);
utilization = mbeso_assigned_material_utilization(result);
solid_mask = utilization.solid_mask;

sigvm = mask_void(response.sigvm, solid_mask);
sigma_e = mask_void(response.sigma_e, solid_mask);
utilization_scale = mbeso_zero_centered_scale(utilization.signed_percent);
stress_sum_title = {'Principal stress sum', ...
    '\sigma_{e,i} = \sigma_{I,i} + \sigma_{II,i}'};
stress_sum_cbar = 'MPa';
utilization_title = {'Assigned-material utilization', ...
    '+: Tensile material region', '-: Compressive material region'};

fig = figure('Color', 'w', 'Name', 'MBESO stress contours', 'NumberTitle', 'off');
set(fig, 'Units', 'pixels', 'Position', [100 100 1250 330]);
set_figure_font(fig);
tiledlayout(fig, 1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

plot_field(nexttile, sigvm, 'von Mises stress', 'von Mises stress (MPa)', ...
    jet(256), [], [], [], [], [], sigvm, 'von Mises stress', 'MPa', false);
utilization_image = plot_field(nexttile, utilization_scale.display_values, ...
    utilization_title, 'Signed utilization (%)', ...
    utilization_scale.colormap, utilization_scale.ticks, utilization_scale.tick_labels, [], [], [], ...
    utilization.signed_percent, 'Signed assigned-material utilization', '%', false);
utilization_data = getappdata(utilization_image, 'MBESO_ElementDatatipData');
utilization_data.material_map = utilization.material_map;
utilization_data.utilization_percent = utilization.percent;
setappdata(utilization_image, 'MBESO_ElementDatatipData', utilization_data);
setappdata(utilization_image, 'MBESO_ColorScale', utilization_scale);
plot_field(nexttile, sigma_e, stress_sum_title, stress_sum_cbar, ...
    signed_redblue_map(sigma_e, 256), [], [], [], [], [], ...
    sigma_e, 'Principal stress sum', 'MPa', true);
enable_element_datatips(fig);
end

function response = require_response(result)
if ~isfield(result, 'response') || isempty(result.response)
    error('The result structure does not contain response fields. Re-run mbeso with the current version.');
end
response = result.response;
end

function field_out = mask_void(field_in, solid_mask)
field_out = field_in;
field_out(~solid_mask) = NaN;
end

function img = plot_field(ax, field_value, title_text, cbar_text, cmap, cbar_ticks, cbar_tick_labels, ...
        x_label, y_label, reverse_y, datatip_value, datatip_name, datatip_unit, show_stress_state)
if nargin < 8 || isempty(x_label), x_label = 'Element x'; end
if nargin < 9 || isempty(y_label), y_label = 'Element y'; end
if nargin < 10 || isempty(reverse_y), reverse_y = true; end
if nargin < 11 || isempty(datatip_value), datatip_value = field_value; end
if nargin < 12 || isempty(datatip_name), datatip_name = title_text; end
if nargin < 13 || isempty(datatip_unit), datatip_unit = ''; end
if nargin < 14 || isempty(show_stress_state), show_stress_state = false; end
[nely, nelx] = size(field_value);
if ~isequal(size(datatip_value), [nely, nelx])
    error('Stress-contour data-tip values must match the plotted field size.');
end
valid_value = field_value(isfinite(field_value));
img = imagesc(ax, field_value);
set(img, 'AlphaData', isfinite(field_value));
setappdata(img, 'MBESO_ElementDatatipData', struct( ...
    'values', datatip_value, ...
    'quantity', datatip_name, ...
    'unit', datatip_unit, ...
    'x_label', x_label, ...
    'y_label', y_label, ...
    'show_stress_state', logical(show_stress_state)));
axis(ax, 'equal');
axis(ax, 'tight');
if reverse_y, set(ax, 'YDir', 'reverse'); else, set(ax, 'YDir', 'normal'); end
set(ax, 'Color', [1 1 1]);
set(ax, 'FontName', 'Times New Roman', 'FontSize', 11, 'LineWidth', 0.75);
colormap(ax, cmap);
if ~isempty(valid_value)
    data_min = min(valid_value);
    data_max = max(valid_value);
    if data_max > data_min, set(ax, 'CLim', [data_min data_max]); end
end
if ~isempty(cbar_ticks)
    set(ax, 'CLim', [min(cbar_ticks) max(cbar_ticks)]);
end
if show_stress_state
    scale = mbeso_zero_centered_scale(field_value, [], 7);
    set(img, 'CData', scale.display_values);
    setappdata(img, 'MBESO_ColorScale', scale);
    set(ax, 'CLim', scale.color_limits);
    colormap(ax, scale.colormap);
    cbar_ticks = scale.ticks;
    cbar_tick_labels = scale.tick_labels;
end
cb = colorbar(ax);
set(cb, 'FontName', 'Times New Roman', 'FontSize', 10);
ylabel(cb, cbar_text, 'FontName', 'Times New Roman', 'FontSize', 11);
if isempty(cbar_ticks)
    set_colorbar_minmax(cb, ax);
else
    set(cb, 'Ticks', cbar_ticks, 'TickLabels', cbar_tick_labels);
end
title(ax, title_text, 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'normal');
xlabel(ax, x_label, 'FontName', 'Times New Roman');
ylabel(ax, y_label, 'FontName', 'Times New Roman');
box(ax, 'on');
end

function enable_element_datatips(fig)
setappdata(fig, 'MBESO_StressContourDatatipsEnabled', true);
dcm = datacursormode(fig);
set(dcm, ...
    'Enable', 'on', ...
    'DisplayStyle', 'datatip', ...
    'SnapToDataVertex', 'off', ...
    'UpdateFcn', @element_datatip_text);
end

function text_rows = element_datatip_text(~, event_obj)
target = get(event_obj, 'Target');
if isempty(target) || ~isgraphics(target, 'image') || ...
        ~isappdata(target, 'MBESO_ElementDatatipData')
    position = get(event_obj, 'Position');
    text_rows = default_position_text(position);
    return;
end

data = getappdata(target, 'MBESO_ElementDatatipData');
position = get(event_obj, 'Position');
if numel(position) < 2 || any(~isfinite(position(1:2)))
    text_rows = {'Element value unavailable'};
    return;
end

element_x = min(max(round(position(1)), 1), size(data.values, 2));
element_y = min(max(round(position(2)), 1), size(data.values, 1));
value = data.values(element_y, element_x);
text_rows = { ...
    sprintf('%s: %d', data.x_label, element_x), ...
    sprintf('%s: %d', data.y_label, element_y)};
if isfield(data, 'material_map')
    material_id = data.material_map(element_y, element_x);
    text_rows{end + 1} = sprintf('Assigned material ID: %d', material_id);
end
if ~isfinite(value)
    text_rows{end + 1} = 'Value: void element';
    return;
end

if isempty(data.unit)
    text_rows{end + 1} = sprintf('%s: %.9g', data.quantity, value);
else
    text_rows{end + 1} = sprintf('%s: %.9g %s', data.quantity, value, data.unit);
end
if isfield(data, 'utilization_percent')
    text_rows{end + 1} = sprintf('Assigned-material utilization magnitude: %.9g %%', ...
        data.utilization_percent(element_y, element_x));
end
if data.show_stress_state
    if value > 0
        state = 'tension-dominated';
    elseif value < 0
        state = 'compression-dominated';
    else
        state = 'neutral';
    end
    text_rows{end + 1} = ['Stress state: ' state];
end
end

function text_rows = default_position_text(position)
if numel(position) >= 2
    text_rows = {sprintf('x: %.9g', position(1)), ...
        sprintf('y: %.9g', position(2))};
else
    text_rows = {'Position unavailable'};
end
end

function set_colorbar_minmax(cb, ax)
clim = get(ax, 'CLim');
if clim(1) < 0 && clim(2) > 0
    compression_ticks = linspace(clim(1), 0, 4);
    tension_ticks = linspace(0, clim(2), 4);
    ticks = [compression_ticks, tension_ticks(2:end)];
else
    ticks = linspace(clim(1), clim(2), 7);
end
ticks(1) = clim(1);
ticks(end) = clim(2);
set(cb, 'Ticks', ticks, 'TickLabels', arrayfun(@(v) sprintf('%.4g', v), ticks, 'UniformOutput', false));
end

function set_figure_font(fig)
set(fig, 'DefaultAxesFontName', 'Times New Roman', 'DefaultTextFontName', 'Times New Roman');
end


function cmap = signed_redblue_map(field_value, ~)
% The shared signed scale has a central white bin and actual-extrema labels.
scale = mbeso_zero_centered_scale(field_value);
cmap = scale.colormap;
end
