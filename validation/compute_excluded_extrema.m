% SPDX-License-Identifier: GPL-3.0-or-later
% Copyright (C) 2026 MBESO2D contributors
function metrics = compute_excluded_extrema(result, exclusion_size_mm)
%COMPUTE_EXCLUDED_EXTREMA Report extrema outside load/support patches.
%
% The exclusion affects post-processing only. No element is removed from the
% finite-element analysis or optimization.

if nargin ~= 2 || ~isstruct(result) || ~isfield(result, 'x')
    error('Usage: metrics = compute_excluded_extrema(result, exclusion_size_mm)');
end
if ~isscalar(exclusion_size_mm) || ~isfinite(exclusion_size_mm) || exclusion_size_mm <= 0
    error('exclusion_size_mm must be a positive finite scalar.');
end
if ~isfield(result, 'settings') || ~isfield(result.settings, 'elSize')
    error('result.settings.elSize is required.');
end

[nely, nelx] = size(result.x);
element_size_mm = result.settings.elSize;
layers = max(1, ceil(exclusion_size_mm / element_size_mm - 1e-12));
layers = min(layers, min(nely, nelx));

first_rows = 1:layers;
last_rows = (nely - layers + 1):nely;
left_cols = 1:layers;
right_cols = (nelx - layers + 1):nelx;
excluded_mask = false(nely, nelx);

bc_case = lower(char(result.settings.bc_case));
switch bc_case
    case 'cantilever'
        excluded_mask(first_rows, left_cols) = true;
        excluded_mask(last_rows, left_cols) = true;
        excluded_mask(last_rows, right_cols) = true;
    case 'run_case_3a'
        excluded_mask(last_rows, left_cols) = true;
        excluded_mask(last_rows, right_cols) = true;
    case 'run_case_3b'
        excluded_mask(first_rows, left_cols) = true;
        excluded_mask(first_rows, right_cols) = true;
    otherwise
        error('No exclusion-zone definition is available for bc_case=%s.', bc_case);
end

xmin = result.settings.xmin;
solid_mask = result.x > xmin;
regular_mask = solid_mask & ~excluded_mask;
sigvm = result.response.sigvm;
eta = result.response.eta;
sigma_state = result.response.sigma_e;

signed_eta = eta;
signed_eta(sigma_state < 0) = -signed_eta(sigma_state < 0);

metrics = struct( ...
    'bc_case', bc_case, ...
    'requested_size_mm', exclusion_size_mm, ...
    'actual_size_mm', layers * element_size_mm, ...
    'patch_layers', layers, ...
    'excluded_mask', excluded_mask, ...
    'regular_mask', regular_mask, ...
    'vm_max_full_MPa', masked_max(sigvm, solid_mask), ...
    'vm_max_regular_MPa', masked_max(sigvm, regular_mask), ...
    'signed_eta_tension_max_full_percent', 100 * masked_max(signed_eta, solid_mask & signed_eta >= 0), ...
    'signed_eta_tension_max_regular_percent', 100 * masked_max(signed_eta, regular_mask & signed_eta >= 0), ...
    'signed_eta_compression_min_full_percent', 100 * masked_min(signed_eta, solid_mask & signed_eta < 0), ...
    'signed_eta_compression_min_regular_percent', 100 * masked_min(signed_eta, regular_mask & signed_eta < 0));
end

function value = masked_max(field, mask)
values = field(mask & isfinite(field));
if isempty(values), value = NaN; else, value = max(values); end
end

function value = masked_min(field, mask)
values = field(mask & isfinite(field));
if isempty(values), value = NaN; else, value = min(values); end
end
