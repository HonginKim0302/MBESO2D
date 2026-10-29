% SPDX-License-Identifier: GPL-3.0-or-later
function display_values = mbeso_centered_display_values(values, scale)
%MBESO_CENTERED_DISPLAY_VALUES Map physical values to the two colorbar halves.
% Preserve physical arrays separately for reporting and data tips. Values
% outside a selected scale mask can saturate at the display limits.
display_values = NaN(size(values));
finite = isfinite(values);
display_values(finite & values==0) = 0;
negative = finite & values<0;
positive = finite & values>0;
if scale.negative_limit < 0
    display_values(negative) = values(negative)/abs(scale.negative_limit);
else
    display_values(negative) = -1;
end
if scale.positive_limit > 0
    display_values(positive) = values(positive)/scale.positive_limit;
else
    display_values(positive) = 1;
end
end
