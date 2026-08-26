% SPDX-License-Identifier: GPL-3.0-or-later
% Copyright (C) 2026 MBESO2D contributors
function dcm = mbeso_enable_displacement_datatips(fig, data)
%MBESO_ENABLE_DISPLACEMENT_DATATIPS Show actual nodal displacements on click.
%
%   dcm = mbeso_enable_displacement_datatips(fig, data)
%
% The displacement plot uses scale = 1. This helper keeps the nodal solution
% in figure appdata and configures the data cursor to report the nearest node:
% original coordinates, ux, uy, and displacement magnitude.

if ~(isscalar(fig) && isgraphics(fig, 'figure'))
    error('fig must be a valid MATLAB figure.');
end
if ~isstruct(data)
    error('data must be a structure.');
end

required_fields = {'node_ids', 'original_x', 'original_y', ...
    'display_x', 'display_y', 'ux', 'uy'};
for i = 1:numel(required_fields)
    field_name = required_fields{i};
    if ~isfield(data, field_name) || isempty(data.(field_name))
        error('data.%s is required.', field_name);
    end
    data.(field_name) = double(data.(field_name)(:));
end

node_count = numel(data.node_ids);
for i = 2:numel(required_fields)
    field_name = required_fields{i};
    if numel(data.(field_name)) ~= node_count
        error('All displacement datatip arrays must have the same length.');
    end
end
if any(~isfinite([data.original_x; data.original_y; data.display_x; ...
        data.display_y; data.ux; data.uy]))
    error('Displacement datatip values must be finite.');
end

if ~isfield(data, 'scale') || isempty(data.scale)
    data.scale = NaN;
else
    data.scale = double(data.scale(1));
end
if ~isfield(data, 'unit') || isempty(data.unit)
    data.unit = 'mm';
else
    data.unit = char(string(data.unit));
end
data.umag = hypot(data.ux, data.uy);

setappdata(fig, 'MBESO_DisplacementDatatipData', data);
dcm = datacursormode(fig);
set(dcm, ...
    'Enable', 'on', ...
    'DisplayStyle', 'datatip', ...
    'SnapToDataVertex', 'off', ...
    'UpdateFcn', @displacement_datatip_text);
end

function text_rows = displacement_datatip_text(~, event_obj)
target = get(event_obj, 'Target');
fig = ancestor(target, 'figure');
if isempty(fig) || ~isappdata(fig, 'MBESO_DisplacementDatatipData')
    position = get(event_obj, 'Position');
    text_rows = default_position_text(position);
    return;
end

data = getappdata(fig, 'MBESO_DisplacementDatatipData');
position = get(event_obj, 'Position');
if numel(position) < 2 || any(~isfinite(position(1:2)))
    text_rows = {'Actual displacement unavailable'};
    return;
end

distance_squared = (data.display_x - position(1)).^2 + ...
    (data.display_y - position(2)).^2;
[~, index] = min(distance_squared);
unit = data.unit;

text_rows = { ...
    sprintf('Nearest node: %d', round(data.node_ids(index))), ...
    sprintf('x0: %.9g %s', data.original_x(index), unit), ...
    sprintf('y0: %.9g %s', data.original_y(index), unit), ...
    sprintf('ux actual: %+.9g %s', data.ux(index), unit), ...
    sprintf('uy actual: %+.9g %s', data.uy(index), unit), ...
    sprintf('|u| actual: %.9g %s', data.umag(index), unit)};
if isfinite(data.scale)
    text_rows{end + 1} = sprintf('Display scale: %.9g', data.scale);
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
