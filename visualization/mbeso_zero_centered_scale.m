% SPDX-License-Identifier: GPL-3.0-or-later
function scale = mbeso_zero_centered_scale(values, mask, tick_count)
%MBESO_ZERO_CENTERED_SCALE Actual extrema with zero halfway along the bar.
% Negative and positive values use separate linear halves. CLim and image
% CData are display coordinates; tick labels and data tips use physical units.
if nargin < 2 || isempty(mask), mask = true(size(values)); end
if nargin < 3 || isempty(tick_count), tick_count = 5; end
validateattributes(values, {'numeric'}, {'real'});
assert(isequal(size(mask),size(values)), 'Scale mask must match the field size.');
validateattributes(tick_count, {'numeric'}, {'scalar','integer','>=',3});
assert(mod(tick_count,2)==1, 'Use an odd tick count to include the central zero.');
selected = values(logical(mask) & isfinite(values));
actual_extrema = [NaN NaN];
negative_limit = 0;
positive_limit = 0;
if ~isempty(selected)
    actual_extrema = [min(selected(:)),max(selected(:))];
    negative_limit = min(0,actual_extrema(1));
    positive_limit = max(0,actual_extrema(2));
end
levels = linspace(-1,1,257).';
palette = mbeso_material_palette();
colors = ones(numel(levels),3);
negative = levels<0; positive = levels>0;
colors(negative,:) = 1 + abs(levels(negative)) * (palette.compressive-1);
colors(positive,:) = 1 + levels(positive) * (palette.tensile-1);
ticks = linspace(-1,1,tick_count);
ticks((tick_count+1)/2) = 0;
physical_ticks = zeros(size(ticks));
physical_ticks(ticks<0) = ticks(ticks<0)*abs(negative_limit);
physical_ticks(ticks>0) = ticks(ticks>0)*positive_limit;
scale = struct('color_limits',[-1 1], 'colormap',colors, ...
    'ticks',ticks,'tick_labels',{{}},'extrema',actual_extrema, ...
    'negative_limit',negative_limit,'positive_limit',positive_limit, ...
    'physical_ticks',physical_ticks, ...
    'mapping','separate linear negative and positive halves');
scale.tick_labels = arrayfun(@(v)sprintf('%.4g',v),physical_ticks,'UniformOutput',false);
if negative_limit == 0, scale.tick_labels(ticks<0) = {''}; end
if positive_limit == 0, scale.tick_labels(ticks>0) = {''}; end
scale.display_values = mbeso_centered_display_values(values,scale);
end
