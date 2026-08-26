% SPDX-License-Identifier: GPL-3.0-or-later
% Copyright (C) 2026 MBESO2D contributors
function fig = mbeso_plot_stress_contours(result)
%MBESO_PLOT_STRESS_CONTOURS Plot final stress and utilization contours.
%
%   fig = mbeso_plot_stress_contours(result)
%
% The input result is the structure returned by mbeso.

response = require_response(result);
x = result.x;
solid_mask = x > result.settings.xmin;

sigvm = mask_void(response.sigvm, solid_mask);
sigma_e = mask_void(response.sigma_e, solid_mask);
eta_percent = mask_void(get_utilization_field(response), solid_mask) * 100;
[eta_plot, eta_signed_percent, eta_ticks, eta_tick_labels] = ...
    signed_utilization_plot(eta_percent, sigma_e);
stress_sum_title = 'Principal stress sum \sigma_1 + \sigma_2';
stress_sum_cbar = 'MPa';

fig = figure('Color', 'w', 'Name', 'MBESO stress contours', 'NumberTitle', 'off');
set(fig, 'Units', 'pixels', 'Position', [100 100 1250 330]);
set_figure_font(fig);
tiledlayout(fig, 1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

plot_field(nexttile, sigvm, 'von Mises stress', 'von Mises stress (MPa)', ...
    jet(256), [], [], [], [], [], sigvm, 'von Mises stress', 'MPa', false);
plot_field(nexttile, eta_plot, 'Unfiltered signed material utilization', '(%)', ...
    redblue_map(256), eta_ticks, eta_tick_labels, [], [], [], ...
    eta_signed_percent, 'Unfiltered signed material utilization', '%', true);
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

function eta = get_utilization_field(response)
if isfield(response, 'eta') && ~isempty(response.eta)
    eta = response.eta;
else
    eta = response.eta_filtered;
end
end

function [eta_plot, eta_signed_percent, ticks, tick_labels] = signed_utilization_plot(eta_percent, sigma_e)
eta_plot = NaN(size(eta_percent));
eta_signed_percent = NaN(size(eta_percent));
tension = isfinite(eta_percent) & isfinite(sigma_e) & sigma_e >= 0;
compression = isfinite(eta_percent) & isfinite(sigma_e) & sigma_e < 0;
tension_max = max_or_zero(abs(eta_percent(tension)));
compression_max = max_or_zero(abs(eta_percent(compression)));
eta_signed_percent(tension) = abs(eta_percent(tension));
eta_signed_percent(compression) = -abs(eta_percent(compression));
if tension_max > 0, eta_plot(tension) = abs(eta_percent(tension)) / tension_max; else, eta_plot(tension) = 0; end
if compression_max > 0, eta_plot(compression) = -abs(eta_percent(compression)) / compression_max; else, eta_plot(compression) = 0; end
ticks = [-1 -0.5 0 0.5 1];
tick_labels = {sprintf('-%.4g', compression_max), sprintf('-%.4g', compression_max/2), '0', sprintf('%.4g', tension_max/2), sprintf('%.4g', tension_max)};
end

function value = max_or_zero(values)
if isempty(values), value = 0; else, value = max(values); end
end

function field_out = mask_void(field_in, solid_mask)
field_out = field_in;
field_out(~solid_mask) = NaN;
end

function plot_field(ax, field_value, title_text, cbar_text, cmap, cbar_ticks, cbar_tick_labels, ...
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
if ~isfinite(value)
    text_rows{end + 1} = 'Value: void element';
    return;
end

if isempty(data.unit)
    text_rows{end + 1} = sprintf('%s: %.9g', data.quantity, value);
else
    text_rows{end + 1} = sprintf('%s: %.9g %s', data.quantity, value, data.unit);
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


function cmap = redblue_map(n)
half = floor(n / 2);
red_to_white = [ones(half, 1), linspace(0, 1, half)', linspace(0, 1, half)'];
white_to_blue = [linspace(1, 0, n - half)', linspace(1, 0, n - half)', ones(n - half, 1)];
cmap = [red_to_white; white_to_blue];
end

function cmap = signed_redblue_map(field_value, n)
% Keep zero white while using the actual, generally asymmetric data limits.
n = max(2, round(n));
valid_value = field_value(isfinite(field_value));
if isempty(valid_value)
    cmap = redblue_map(n);
    return;
end

data_min = min(valid_value);
data_max = max(valid_value);
if data_max == data_min
    cmap = repmat([1, 1, 1], n, 1);
elseif data_min < 0 && data_max > 0
    zero_fraction = -data_min / (data_max - data_min);
    zero_index = 1 + round(zero_fraction * (n - 1));
    zero_index = min(max(zero_index, 2), n - 1);
    negative_count = zero_index;
    positive_count = n - zero_index + 1;
    red_to_white = [ones(negative_count, 1), ...
        linspace(0, 1, negative_count)', linspace(0, 1, negative_count)'];
    white_to_blue = [linspace(1, 0, positive_count)', ...
        linspace(1, 0, positive_count)', ones(positive_count, 1)];
    cmap = [red_to_white; white_to_blue(2:end, :)];
elseif data_max <= 0
    cmap = [ones(n, 1), linspace(0, 1, n)', linspace(0, 1, n)'];
else
    cmap = [linspace(1, 0, n)', linspace(1, 0, n)', ones(n, 1)];
end
end
