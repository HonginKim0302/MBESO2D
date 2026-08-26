%MBESO Stress-based multi-material BESO topology optimizer.
%   result = mbeso(nelx, nely, volfrac, er, options)
%   Returns the final design, material map, history, response, and settings.
%   Plotting and report writing are provided in visualization/.
% SPDX-License-Identifier: GPL-3.0-or-later
% Includes portions adapted from MIT-licensed BESO79 in NewBESO.
% See THIRD_PARTY_NOTICE.md for the source mapping and preserved MIT notice.
% Copyright (C) 2026 MBESO2D contributors
% Main author: Hongin Kim
function result = mbeso(nelx, nely, volfrac, er, options)
if nargin < 4 || nargin > 5, error('Usage: result = mbeso(nelx, nely, volfrac, er, options)'); end
if nargin < 5 || isempty(options), options = struct(); end
run_timer = tic;
%% Default materials
materials = struct( ...
    'E1', 200000, 'nu1', 0.3, 'sigma_m1', 250, ...
    'E2', 20000,  'nu2', 0.3, 'sigma_m2', 50, ...
    'nu3', 0.3);
materials = get_option(options, 'materials', materials);

%% Options
bc_case = get_option(options, 'bc_case', 'cantilever');
bc_load = get_option(options, 'bc_load', 1000);
tension_eta_mode = get_option(options, 'tension_eta_mode', 'with_nk');
max_iterations = get_option(options, 'max_iterations', get_option(options, 'iteration_limit', 1000));
force_iteration_limit = get_option(options, 'force_iteration_limit', false);
if ~isscalar(force_iteration_limit) || ~(islogical(force_iteration_limit) || isnumeric(force_iteration_limit))
    error('force_iteration_limit must be a logical or numeric scalar.');
end
force_iteration_limit = logical(force_iteration_limit);
penal = get_option(options, 'penal', 3.0);
tau = get_option(options, 'tau', 1e-3);
xmin = get_option(options, 'xmin', 1e-3);
r1_mm = get_option(options, 'r1_mm', 20);
r2_mm = get_option(options, 'r2_mm', 30);
structure_width = get_option(options, 'structure_width', 1000);
structure_height = get_option(options, 'structure_height', 600);
structure_dimension_unit = get_option(options, 'structure_dimension_unit', 'mm');
% Default plane-stress thickness is 1 mm, matching the manuscript example.
out_of_plane_thickness_m = get_option(options, 'out_of_plane_thickness_m', 1e-3);
verbose = get_option(options, 'verbose', true);
plotting = get_option(options, 'plotting', true);
write_run_report = get_option(options, 'write_run_report', false);
run_report_file = get_option(options, 'run_report_file', '');
even_keep_count = get_option(options, 'even_keep_count', false);
designMask = get_option(options, 'designMask', true(nely, nelx));
if isfield(options, 'design_mask') && ~isempty(options.design_mask), designMask = options.design_mask; end
if ~isequal(size(designMask), [nely, nelx]), error('designMask must have size [nely, nelx].'); end
designMask = logical(designMask);
if ~any(designMask(:)), error('designMask must contain at least one active design element.'); end
if ~isscalar(out_of_plane_thickness_m) || ~isfinite(out_of_plane_thickness_m) || out_of_plane_thickness_m <= 0
    error('out_of_plane_thickness_m must be a positive finite scalar.');
end
elSize = resolve_element_size_from_structure(structure_width, structure_height, structure_dimension_unit, nelx, nely);
r1 = r1_mm / elSize;
r2 = r2_mm / elSize;
% Stiffness includes thickness; the stress-recovery matrices do not.
thickness_mm = 1000 * out_of_plane_thickness_m;
KE1 = thickness_mm * lk(materials.E1, materials.nu1);
KE2 = thickness_mm * lk(materials.E2, materials.nu2);
% Ersatz void uses E2, nu3, and xmin^penal; no E3 modulus is used.
KE3 = thickness_mm * lk(materials.E2, materials.nu3);
D1 = compute_D_matrix(materials.E1, materials.nu1);
D2 = compute_D_matrix(materials.E2, materials.nu2);
fem = prepare_fem(nelx, nely, elSize, bc_case, bc_load);
[H1, Hs1] = prepare_filter(nelx, nely, r1);
[H2, Hs2] = prepare_filter(nelx, nely, r2);
%% Initialization
x = ones(nely, nelx);
mi_map = ones(nely, nelx);
x(~designMask) = xmin;
mi_map(~designMask) = 0;
eta = ones(nely, nelx);
nk = 1;
vol = 1.0;
change = 1.0;
reached_vol = false;
volume_tolerance = 1 / max(1, nelx * nely);
history = struct( 'Vk_hist', [], 'solid_fraction_hist', [], 'nk_hist', [], 'V1_hist', [], 'pre_compliance_hist', [], 'compliance_hist', [], 'change_hist', [], 'target_keep_hist', [], 'effective_keep_hist', [], 'keep_count_hist', [], 'iteration_time_hist', [], 'initial_beso_state', []);
% Cache the current analysis for the first design update.
[U, sig1, sig2, sigvm] = FE_vectorized(x, penal, KE1, KE2, KE3, D1, D2, mi_map, fem);
initial_compliance = element_compliance(U, x, penal, KE1, KE2, KE3, mi_map, fem);
current_compliance = initial_compliance;
history.initial_beso_state = struct( 'Vk', vol, 'solid_fraction', nnz(x > xmin) / numel(x), 'nk', nk, 'V1', sum((mi_map(:) == 1) & (x(:) > xmin)) / numel(x), 'compliance', initial_compliance);
i = 0;
plot_handle = [];
eta_filtered_history = eta;
%% Optimization loop
while (i < max_iterations) && ...
        (force_iteration_limit || (~reached_vol) || (change > tau))
    i = i + 1;
    iteration_timer = tic;
if i == 1, eta_filtered_old = eta; end
    c = current_compliance;
    sigma_e = sig1 + sig2;
    [nk, eta] = update_material_utilization(materials.sigma_m1, materials.sigma_m2, sigvm, er, volfrac, sigma_e, i, tension_eta_mode, nk);
    eta_filtered_new = apply_filter(H2, Hs2, eta, nely, nelx);
    if i == 1
        eta_filtered_history = eta_filtered_new;
    else
        eta_filtered_history = (eta_filtered_old + eta_filtered_new) / 2;
    end
    eta_filtered_old = eta_filtered_new;
    sigma_e_filtered = apply_filter(H1, Hs1, sigma_e, nely, nelx);
    vol_next = max(vol * (1 - er), volfrac);
    [keep_mask, num_to_keep, cutoff, effective_keep_count] = select_keep_mask( ...
        eta_filtered_history, designMask, vol_next, even_keep_count);
    x(:) = xmin;
    x(keep_mask) = 1.0;
    x(~designMask) = xmin;
    vol = vol_next;
    solid_mask = x > xmin;
    mi_map(:) = 2;
    mi_map(~solid_mask) = 0;
    mi_map(solid_mask & (sigma_e_filtered >= 0)) = 1;
    mi_map(~designMask) = 0;
    % Reuse this updated analysis in the next iteration.
    [U_next, sig1_next, sig2_next, sigvm_next] = ...
        FE_vectorized(x, penal, KE1, KE2, KE3, D1, D2, mi_map, fem);
    history_compliance = element_compliance(U_next, x, penal, KE1, KE2, KE3, mi_map, fem);
    current_volume_ratio = nnz(solid_mask) / (nelx * nely);
    reached_vol = current_volume_ratio <= (volfrac + volume_tolerance);
    if i > 10 && ~isempty(history.compliance_hist)
        prev_compliance = history.compliance_hist(end);
        change = abs(history_compliance - prev_compliance) / max(abs(history_compliance), 1e-12);
    else
        change = 1.0;
    end
    % Vk is scheduled volume; solid_fraction excludes xmin.
    history.Vk_hist(end+1, 1) = vol;
    history.solid_fraction_hist(end+1, 1) = current_volume_ratio;
    history.nk_hist(end+1, 1) = nk;
    history.V1_hist(end+1, 1) = sum((mi_map(:) == 1) & solid_mask(:)) / numel(x);
    history.pre_compliance_hist(end+1, 1) = c;
    history.compliance_hist(end+1, 1) = history_compliance;
    history.change_hist(end+1, 1) = change;
    history.target_keep_hist(end+1, 1) = num_to_keep;
    history.effective_keep_hist(end+1, 1) = effective_keep_count;
    history.keep_count_hist(end+1, 1) = nnz(keep_mask);
    history.iteration_time_hist(end+1, 1) = toc(iteration_timer);
    U = U_next;
    sig1 = sig1_next;
    sig2 = sig2_next;
    sigvm = sigvm_next;
    current_compliance = history_compliance;
if plotting
plot_handle = update_iteration_plot(plot_handle, mi_map, i, history_compliance);
end
if verbose, print_iteration_summary(i, history_compliance, vol, current_volume_ratio, change, history.V1_hist(end), nk, cutoff); end
end
% The cached analysis already corresponds to the final layout.
final_response = build_design_response_from_analysis( U, sig1, sig2, sigvm, x, penal, KE1, KE2, KE3, mi_map, fem, materials, er, volfrac, tension_eta_mode, nk, H1, Hs1, H2, Hs2);
final_response.eta_filtered_history = eta_filtered_history;
if isempty(history.compliance_hist)
    final_compliance = final_response.compliance;
else
    final_compliance = history.compliance_hist(end);
end
run_time_seconds = toc(run_timer);
converged = reached_vol && (change <= tau);
if force_iteration_limit
    termination_reason = 'fixed_iteration_limit';
elseif converged
    termination_reason = 'converged';
else
    termination_reason = 'max_iterations';
end
settings = struct( 'bc_case', bc_case, 'bc_load', bc_load, 'tension_eta_mode', tension_eta_mode, 'max_iterations', max_iterations, 'force_iteration_limit', force_iteration_limit, 'penal', penal, 'tau', tau, 'xmin', xmin, 'r1_mm', r1_mm, 'r2_mm', r2_mm, 'structure_width', structure_width, 'structure_height', structure_height, 'structure_dimension_unit', structure_dimension_unit, 'out_of_plane_thickness_m', out_of_plane_thickness_m, 'out_of_plane_thickness_mm', thickness_mm, 'elSize', elSize, 'even_keep_count', even_keep_count, 'designMask', designMask, 'plotting', plotting, 'write_run_report', write_run_report, 'run_report_file', run_report_file, 'run_time_seconds', run_time_seconds, 'converged', converged, 'termination_reason', termination_reason);
result = struct( 'x', x, 'mi_map', mi_map, 'history', history, 'iterations', i, 'compliance', final_compliance, 'response', final_response, 'materials', materials, 'settings', settings, 'converged', converged, 'termination_reason', termination_reason);
result = write_run_report_if_requested(result, write_run_report, run_report_file);
end
function result = write_run_report_if_requested(result, write_run_report, run_report_file)
if ~write_run_report
    return;
end
if isstring(run_report_file) && isscalar(run_report_file)
    run_report_file = char(run_report_file);
end
try
    ensure_visualization_path();
    if isempty(run_report_file)
        run_report_file = default_run_report_file_from_solver();
    end
    report_file = mbeso_write_run_report(result, run_report_file);
    result.report_file = report_file;
    result.settings.report_file = report_file;
catch ME
    result.report_file = '';
    result.report_error = ME.message;
    result.settings.report_file = '';
    result.settings.report_error = ME.message;
    warning('MBESO:RunReportNotWritten', 'Could not write MBESO run report: %s', ME.message);
end
end
function ensure_visualization_path()
repo_root = find_repo_root_from_solver();
visualization_dir = fullfile(repo_root, 'visualization');
if exist(fullfile(visualization_dir, 'mbeso_write_run_report.m'), 'file') ~= 2
    error('MBESO:RunReportWriterNotFound', 'Could not find mbeso_write_run_report.m in %s', visualization_dir);
end
addpath(visualization_dir, '-begin');
rehash;
end
function report_file = default_run_report_file_from_solver()
repo_root = find_repo_root_from_solver();
results_dir = fullfile(repo_root, 'results');
timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
report_file = fullfile(results_dir, ['mbeso_run_report_' timestamp '.txt']);
end
function repo_root = find_repo_root_from_solver()
src_dir = fileparts(mfilename('fullpath'));
candidate_dirs = {fileparts(src_dir), fileparts(fileparts(src_dir))};
repo_root = fileparts(src_dir);
for k = 1:numel(candidate_dirs)
    candidate_root = candidate_dirs{k};
    if exist(fullfile(candidate_root, 'visualization', 'mbeso_write_run_report.m'), 'file') == 2
        repo_root = candidate_root;
        return;
    end
end
end
function h = update_iteration_plot(h, mi_map, i, compliance)
if isempty(h) || ~isvalid(h.fig)
    h.fig = figure('Color', 'w', 'Name', 'MBESO minimal material layout', 'NumberTitle', 'off');
    set(h.fig, 'DefaultAxesFontName', 'Times New Roman', 'DefaultTextFontName', 'Times New Roman');
    h.ax = axes('Parent', h.fig);
    h.img = imagesc(h.ax, mi_map, [0 2]);
    colormap(h.ax, [1 1 1; 1 0 0; 0 0 1]); axis(h.ax, 'equal'); axis(h.ax, 'tight'); axis(h.ax, 'off');
    h.key_void = line(h.ax, NaN, NaN, 'LineStyle', 'none', 'Marker', 's', ...
        'MarkerSize', 9, 'MarkerFaceColor', [1 1 1], 'MarkerEdgeColor', [0.3 0.3 0.3]);
    h.key_tension = line(h.ax, NaN, NaN, 'LineStyle', 'none', 'Marker', 's', ...
        'MarkerSize', 9, 'MarkerFaceColor', [1 0 0], 'MarkerEdgeColor', [1 0 0]);
    h.key_compression = line(h.ax, NaN, NaN, 'LineStyle', 'none', 'Marker', 's', ...
        'MarkerSize', 9, 'MarkerFaceColor', [0 0 1], 'MarkerEdgeColor', [0 0 1]);
    h.legend = legend(h.ax, [h.key_void, h.key_tension, h.key_compression], ...
        {'Void', 'Tension material (M1)', 'Compression material (M2)'}, ...
        'Location', 'southoutside', 'Orientation', 'horizontal', 'Box', 'off', ...
        'FontName', 'Times New Roman', 'FontSize', 10);
else
    set(h.img, 'CData', mi_map);
end
set(h.ax, 'FontName', 'Times New Roman', 'FontSize', 11);
title(h.ax, sprintf('It:%d  Compliance:%g', i, compliance), 'FontName', 'Times New Roman', 'FontWeight', 'normal'); drawnow;
end
function response = build_design_response_from_analysis(U, sig1, sig2, sigvm, x, penal, KE1, KE2, KE3, mi_map, fem, materials, er, volfrac, tension_eta_mode, nk, H1, Hs1, H2, Hs2)
sigma_e = sig1 + sig2;
[~, eta] = update_material_utilization(materials.sigma_m1, materials.sigma_m2, sigvm, er, volfrac, sigma_e, 0, tension_eta_mode, nk);
eta_filtered = apply_filter(H2, Hs2, eta, fem.nely, fem.nelx);
sigma_e_filtered = apply_filter(H1, Hs1, sigma_e, fem.nely, fem.nelx);
compliance = element_compliance(U, x, penal, KE1, KE2, KE3, mi_map, fem);
response = struct( 'U', U, 'sig1', sig1, 'sig2', sig2, 'sigvm', sigvm, 'sigma_e', sigma_e, 'sigma_e_filtered', sigma_e_filtered, 'eta', eta, 'eta_filtered', eta_filtered, 'compliance', compliance);
end
function [U, sig1, sig2, sigvm] = FE_vectorized(x, penal, KE1, KE2, KE3, D1, D2, mi_map, fem)
U = FE_displacement(x, penal, KE1, KE2, KE3, mi_map, fem);
% Recover element principal and von Mises stresses.
Ue = U(fem.edofMat);
strain = Ue * fem.B';
xpen = x(:).^penal;
m1 = mi_map(:) == 1;
stress = zeros(fem.nele, 3);
stress(m1, :) = bsxfun(@times, strain(m1, :) * D1', xpen(m1));
stress(~m1, :) = bsxfun(@times, strain(~m1, :) * D2', xpen(~m1));
sx = stress(:, 1);
sy = stress(:, 2);
txy = stress(:, 3);
avg = 0.5 * (sx + sy);
rad = sqrt((0.5 * (sx - sy)).^2 + txy.^2);
sig1 = reshape(avg + rad, fem.nely, fem.nelx);
sig2 = reshape(avg - rad, fem.nely, fem.nelx);
sigvm = reshape(sqrt(sx.^2 - sx .* sy + sy.^2 + 3 * txy.^2), fem.nely, fem.nelx);
end
function U = FE_displacement(x, penal, KE1, KE2, KE3, mi_map, fem)
% Assemble and solve the sparse FE system.
xpen = x(:)'.^penal;
m1 = (mi_map(:)' == 1);
m2 = (mi_map(:)' == 2);
m0 = ~(m1 | m2);
sK = reshape(KE1(:) * (xpen .* m1) + KE2(:) * (xpen .* m2) + KE3(:) * (xpen .* m0), 64 * fem.nele, 1);
K = sparse(fem.iK, fem.jK, sK, fem.ndof, fem.ndof);
K = (K + K') / 2;
U = zeros(fem.ndof, 1);
U(fem.freedofs, :) = K(fem.freedofs, fem.freedofs) \ fem.F(fem.freedofs, :);
U(fem.fixeddofs, :) = 0;
end
function compliance = element_compliance(U, x, penal, KE1, KE2, KE3, mi_map, fem)
ce = element_energy(U, KE1, KE2, KE3, mi_map, fem);
compliance = 0.5 * sum((x(:).^penal) .* ce);
end
function ce = element_energy(U, KE1, KE2, KE3, mi_map, fem)
Ue = U(fem.edofMat);
ce1 = sum((Ue * KE1) .* Ue, 2);
ce2 = sum((Ue * KE2) .* Ue, 2);
ce3 = sum((Ue * KE3) .* Ue, 2);
m1 = mi_map(:) == 1;
m2 = mi_map(:) == 2;
m0 = ~(m1 | m2);
ce = ce1 .* m1 + ce2 .* m2 + ce3 .* m0;
end
function [keep_mask, num_to_keep, cutoff, effective_keep_count] = select_keep_mask(eta_history, designMask, vol_next, even_keep_count)
total_elements = numel(eta_history);
num_to_keep = floor(vol_next * total_elements);
num_to_keep = max(1, min(num_to_keep, nnz(designMask)));
effective_keep_count = num_to_keep;
if even_keep_count && mod(effective_keep_count, 2) == 1
    if effective_keep_count < nnz(designMask)
        effective_keep_count = effective_keep_count + 1;
    elseif effective_keep_count > 1
        effective_keep_count = effective_keep_count - 1;
    end
end

eta_vec = eta_history(designMask);
[eta_sorted, sort_idx] = sort(eta_vec, 'descend');
keep_vec = false(numel(eta_vec), 1);
keep_vec(sort_idx(1:effective_keep_count)) = true;

keep_mask = false(size(eta_history));
keep_mask(designMask) = keep_vec;
cutoff = eta_sorted(effective_keep_count);
if nnz(keep_mask) ~= effective_keep_count
    error('Keep-count selection failed: requested %d elements but selected %d.', ...
        effective_keep_count, nnz(keep_mask));
end
end
function print_iteration_summary(i, compliance, target_volume_ratio, solid_fraction, change, vol_1_ratio, nk, cutoff)
fprintf('iter %4d | Compliance: %12.6f | Vk: %6.3f | Solid: %6.3f | V1: %6.3f | nk: %.10f | cutoff: %.6e | change: %.6e\n', i, compliance, target_volume_ratio, solid_fraction, vol_1_ratio, nk, cutoff, change);
end
% Q4 DOF indexing and sparse assembly adapted from BESO79 in NewBESO.
% See THIRD_PARTY_NOTICE.md for the source mapping and preserved MIT notice.
function fem = prepare_fem(nelx, nely, elSize, bc_case, bc_load)
nodenrs = reshape(1:(nelx + 1) * (nely + 1), nely + 1, nelx + 1);
n1 = reshape(nodenrs(1:end-1, 1:end-1), nelx * nely, 1);
n2 = reshape(nodenrs(1:end-1, 2:end), nelx * nely, 1);
edofMat = [2*n1-1, 2*n1, 2*n2-1, 2*n2, 2*n2+1, 2*n2+2, 2*n1+1, 2*n1+2];
iK = reshape(kron(edofMat, ones(8, 1))', 64 * nelx * nely, 1);
jK = reshape(kron(edofMat, ones(1, 8))', 64 * nelx * nely, 1);
ndof = 2 * (nelx + 1) * (nely + 1);
[F, fixeddofs] = get_boundary_conditions(bc_case, bc_load, nelx, nely, ndof);
freedofs = setdiff(1:ndof, fixeddofs);
fem = struct( 'nelx', nelx, 'nely', nely, 'nele', nelx * nely, 'ndof', ndof, 'edofMat', edofMat, 'iK', iK, 'jK', jK, 'F', F, 'fixeddofs', fixeddofs, 'freedofs', freedofs, 'B', (1 / elSize) * B0());
end
function [F, fixeddofs] = get_boundary_conditions(bc_case, bc_load, nelx, nely, ndof)
bc_case = lower(char(bc_case));
F = sparse(ndof, 1);
switch bc_case
    case 'cantilever'
        F(2 * (nelx + 1) * (nely + 1), 1) = bc_load;
        fixeddofs = 1:2 * (nely + 1);
    otherwise
        error('Unknown bc_case: %s', bc_case);
end
fixeddofs = unique(fixeddofs(:))';
end
% Sparse distance-weighted filter assembly adapted from BESO79 in NewBESO.
% See THIRD_PARTY_NOTICE.md for the source mapping and preserved MIT notice.
function [H, Hs] = prepare_filter(nelx, nely, rmin)
span = 2 * (ceil(rmin) - 1) + 1;
iH = ones(nelx * nely * span^2, 1);
jH = ones(size(iH));
sH = zeros(size(iH));
index = 0;
for i1 = 1:nelx
    for j1 = 1:nely
        e1 = (i1 - 1) * nely + j1;
        [i2, j2] = ndgrid(max(i1 - (ceil(rmin) - 1), 1):min(i1 + (ceil(rmin) - 1), nelx), max(j1 - (ceil(rmin) - 1), 1):min(j1 + (ceil(rmin) - 1), nely));
        e2 = (i2(:) - 1) * nely + j2(:);
        ids = index + (1:numel(e2));
        iH(ids) = e1;
        jH(ids) = e2;
        sH(ids) = max(0, rmin - sqrt((i1 - i2(:)).^2 + (j1 - j2(:)).^2));
        index = index + numel(e2);
    end
end
H = sparse(iH(1:index), jH(1:index), sH(1:index), nelx * nely, nelx * nely);
Hs = sum(H, 2);
end
function filtered = apply_filter(H, Hs, field, nely, nelx)
filtered = reshape(H * field(:) ./ max(Hs, 1e-6), nely, nelx);
end
% Plane-stress Q4 coefficient form adapted from BESO79 in NewBESO.
% See THIRD_PARTY_NOTICE.md for the source mapping and preserved MIT notice.
function KE = lk(E, nu)
k = [1/2-nu/6, 1/8+nu/8, -1/4-nu/12, -1/8+3*nu/8, -1/4+nu/12, -1/8-nu/8, nu/6, 1/8-3*nu/8];
KE = E/(1-nu^2) * [ k(1) k(2) k(3) k(4) k(5) k(6) k(7) k(8)
    k(2) k(1) k(8) k(7) k(6) k(5) k(4) k(3)
    k(3) k(8) k(1) k(6) k(7) k(4) k(5) k(2)
    k(4) k(7) k(6) k(1) k(8) k(3) k(2) k(5)
    k(5) k(6) k(7) k(8) k(1) k(2) k(3) k(4)
    k(6) k(5) k(4) k(3) k(2) k(1) k(8) k(7)
    k(7) k(4) k(5) k(2) k(3) k(8) k(1) k(6)
    k(8) k(3) k(2) k(5) k(4) k(7) k(6) k(1)];
end
function B = B0()
B = 1/2 * [ -1  0  1  0  1  0 -1  0
     0 -1  0 -1  0  1  0  1
    -1 -1 -1  1  1  1  1 -1];
end
function D = compute_D_matrix(E, nu)
D = E / (1 - nu^2) * [1, nu, 0; nu, 1, 0; 0, 0, (1 - nu) / 2];
end
function [nk, eta] = update_material_utilization(sigma_m1, sigma_m2, sigvm, er, volfrac, sigma_e, iteration, tension_eta_mode, nk)
sigma_m1 = max(sigma_m1, 1e-6);
sigma_m2 = max(sigma_m2, 1e-6);
er = min(max(er, 1e-3), 0.999);
tension_eta_mode = lower(char(tension_eta_mode));
if iteration > 0
    target_ratio = abs(sigma_m1) / abs(sigma_m2);
    value = log(volfrac) / log(1 - er);
    nk = nk * (target_ratio)^(1 / value);
    nk = min(nk, target_ratio);
end
eta = sigvm / sigma_m2;
tension_mask = sigma_e >= 0;
if any(tension_mask(:))
    switch tension_eta_mode
        case 'with_nk'
            eta(tension_mask) = sigvm(tension_mask) / max(nk * sigma_m2, 1e-12);
        case 'without_nk'
            eta(tension_mask) = sigvm(tension_mask) / sigma_m1;
        otherwise
            error('Unknown tension_eta_mode: %s', tension_eta_mode);
    end
end
end
function elSize = resolve_element_size_from_structure(structure_width, structure_height, structure_dimension_unit, nelx, nely)
width_mm = convert_length_to_mm(structure_width, structure_dimension_unit);
height_mm = convert_length_to_mm(structure_height, structure_dimension_unit);
elx = width_mm / nelx;
ely = height_mm / nely;
if abs(elx - ely) > 1e-9, error('Automatic elSize requires square elements: width/nelx (%.6f mm) must match height/nely (%.6f mm).', elx, ely); end
elSize = elx;
end
function length_mm = convert_length_to_mm(length_value, length_unit)
switch lower(char(length_unit))
    case 'mm'
        length_mm = length_value;
    case 'cm'
        length_mm = 10 * length_value;
    case 'm'
        length_mm = 1000 * length_value;
    otherwise
        error('Unsupported length unit: %s', char(length_unit));
end
end
function value = get_option(options, field_name, default_value)
if isfield(options, field_name) && ~isempty(options.(field_name))
    value = options.(field_name);
else
    value = default_value;
end
end
