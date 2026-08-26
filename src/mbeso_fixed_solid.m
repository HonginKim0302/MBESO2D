% SPDX-License-Identifier: GPL-3.0-or-later
% Includes portions adapted from MIT-licensed BESO79 in NewBESO.
% See THIRD_PARTY_NOTICE.md for the source mapping and preserved MIT notice.
% Copyright (C) 2026 MBESO2D contributors
%MBESO_FIXED_SOLID MBESO with retained solid regions.
%   result = mbeso_fixed_solid(nelx, nely, volfrac, er, options)
%   Supports design masks, deck loads, self-weight, and fixed-layout FEM.
%   Formulation follows Li and Xie (2021). Main author: Hongin Kim.

function result = mbeso_fixed_solid(nelx, nely, volfrac, er, options)
if nargin < 4 || nargin > 5
    error('Usage: result = mbeso_fixed_solid(nelx, nely, volfrac, er, options)');
end
if nargin < 5 || isempty(options)
    options = struct();
end
run_timer = tic;

%% Default materials
default_materials = struct( ...
    'E1', 200000, 'nu1', 0.3, 'sigma_m1', 250, ...
    'E2', 20000,  'nu2', 0.3, 'sigma_m2', 50, ...
    'nu3', 0.3, ...
    'rho1', 7.8e3, 'rho2', 2.4e3, 'rho0', 0);
materials = merge_struct(default_materials, get_option(options, 'materials', struct()));

%% Options
bc_case = get_option(options, 'bc_case', 'cantilever');
bc_load = get_option(options, 'bc_load', 1000);
tension_eta_mode = get_option(options, 'tension_eta_mode', 'with_nk');
max_iterations = get_option(options, 'max_iterations', get_option(options, 'iteration_limit', 1000));
penal = get_option(options, 'penal', 3.0);
tau = get_option(options, 'tau', 1e-3);
xmin = get_option(options, 'xmin', 1e-3);
r1_mm = get_option(options, 'r1_mm', 15);
r2_mm = get_option(options, 'r2_mm', 30);
structure_width = get_option(options, 'structure_width', 1000);
structure_height = get_option(options, 'structure_height', 600);
structure_dimension_unit = get_option(options, 'structure_dimension_unit', 'mm');
deck_line_load_N_per_m = get_option(options, 'deck_line_load_N_per_m', []);
deck_load_sign = get_option(options, 'deck_load_sign', 1);
deck_load_distribution = get_option(options, 'deck_load_distribution', 'consistent');
deck_load_node_row = get_option(options, 'deck_load_node_row', []);
include_self_weight = get_option(options, 'include_self_weight', false);
gravity = get_option(options, 'gravity', 9.81);
gravity_load_sign = get_option(options, 'gravity_load_sign', deck_load_sign);
% Default plane-stress thickness is 1 mm; bridge examples set 1 m explicitly.
out_of_plane_thickness_m = get_option(options, 'out_of_plane_thickness_m', 1e-3);
verbose = get_option(options, 'verbose', true);
plotting = get_option(options, 'plotting', true);
write_run_report = get_option(options, 'write_run_report', true);
run_report_file = get_option(options, 'run_report_file', '');
save_result = get_option(options, 'save_result', true);
result_file = get_option(options, 'result_file', '');
analysis_only = get_option(options, 'analysis_only', false);
initial_x = get_option(options, 'initial_x', []);
initial_mi_map = get_option(options, 'initial_mi_map', []);
layout_source = get_option(options, 'layout_source', '');
even_keep_count = get_option(options, 'even_keep_count', true);
designMask = get_option(options, 'designMask', true(nely, nelx));
fixed_solid_mask = get_option(options, 'fixed_solid_mask', false(nely, nelx));
explicit_non_design_mask = get_option(options, 'non_design_mask', false(nely, nelx));
if isfield(options, 'design_mask') && ~isempty(options.design_mask)
    designMask = options.design_mask;
end
if isfield(options, 'fixedSolidMask') && ~isempty(options.fixedSolidMask)
    fixed_solid_mask = options.fixedSolidMask;
end
if isfield(options, 'nonDesignMask') && ~isempty(options.nonDesignMask)
    explicit_non_design_mask = options.nonDesignMask;
end
if isfield(options, 'non_design_domain_mask') && ~isempty(options.non_design_domain_mask)
    explicit_non_design_mask = options.non_design_domain_mask;
end
if ~isequal(size(designMask), [nely, nelx])
    error('designMask must have size [nely, nelx].');
end
if ~isequal(size(fixed_solid_mask), [nely, nelx])
    error('fixed_solid_mask must have size [nely, nelx].');
end
if ~isequal(size(explicit_non_design_mask), [nely, nelx])
    error('non_design_mask must have size [nely, nelx].');
end
designMask = logical(designMask);
fixed_solid_mask = logical(fixed_solid_mask);
explicit_non_design_mask = logical(explicit_non_design_mask);
if any(explicit_non_design_mask(:) & fixed_solid_mask(:))
    error('non_design_mask must not overlap fixed_solid_mask.');
end
designMask(explicit_non_design_mask) = false;
non_design_mask = (~designMask) & ~fixed_solid_mask;
freeDesignMask = designMask & ~fixed_solid_mask;
if ~any(designMask(:) | fixed_solid_mask(:))
    error('designMask must contain at least one active design element.');
end
if ~any(freeDesignMask(:))
    error('mbeso_fixed_solid needs at least one non-fixed design element.');
end
if ~isscalar(out_of_plane_thickness_m) || ~isfinite(out_of_plane_thickness_m) || out_of_plane_thickness_m <= 0
    error('out_of_plane_thickness_m must be a positive finite scalar.');
end
if ~isscalar(max_iterations) || ~isfinite(max_iterations) || ...
        max_iterations < 1 || max_iterations ~= round(max_iterations)
    error('max_iterations must be a positive integer.');
end
if ~isempty(deck_line_load_N_per_m) && (~isscalar(deck_line_load_N_per_m) || ~isfinite(deck_line_load_N_per_m) || deck_line_load_N_per_m < 0)
    error('deck_line_load_N_per_m must be empty or a nonnegative finite scalar.');
end
if ~(ischar(deck_load_distribution) || (isstring(deck_load_distribution) && isscalar(deck_load_distribution)))
    error('deck_load_distribution must be ''consistent'' or ''equal_nodes''.');
end
deck_load_distribution = lower(strtrim(char(deck_load_distribution)));
if ~ismember(deck_load_distribution, {'consistent', 'equal_nodes'})
    error('deck_load_distribution must be ''consistent'' or ''equal_nodes''.');
end
if ~isempty(deck_load_node_row) && ...
        (~isscalar(deck_load_node_row) || ~isfinite(deck_load_node_row) || ...
         deck_load_node_row ~= round(deck_load_node_row) || ...
         deck_load_node_row < 1 || deck_load_node_row > nely + 1)
    error('deck_load_node_row must be empty or an integer from 1 to nely + 1.');
end
if ~isscalar(gravity) || ~isfinite(gravity) || gravity < 0
    error('gravity must be a nonnegative finite scalar.');
end
if any([materials.rho1, materials.rho2, materials.rho0] < 0) || ...
        any(~isfinite([materials.rho1, materials.rho2, materials.rho0]))
    error('Material densities rho1, rho2, and rho0 must be nonnegative finite values.');
end

%% Initialization
elSize = resolve_element_size_from_structure(structure_width, structure_height, structure_dimension_unit, nelx, nely);
r1 = r1_mm / elSize;
r2 = r2_mm / elSize;

% Scale unit-thickness stiffness to the specified physical thickness.
thickness_mm = 1000 * out_of_plane_thickness_m;
KE1 = thickness_mm * lk(materials.E1, materials.nu1);
KE2 = thickness_mm * lk(materials.E2, materials.nu2);
% Ersatz void uses E2, nu3, and xmin^penal; no E3 modulus is used.
KE3 = thickness_mm * lk(materials.E2, materials.nu3);

D1 = compute_D_matrix(materials.E1, materials.nu1);
D2 = compute_D_matrix(materials.E2, materials.nu2);

fem = prepare_fem(nelx, nely, elSize, bc_case, bc_load, ...
    deck_line_load_N_per_m, deck_load_sign, deck_load_distribution, deck_load_node_row, ...
    include_self_weight, gravity, ...
    gravity_load_sign, out_of_plane_thickness_m, materials);
resolved_deck_load_node_row = deck_load_node_row;
if isfield(fem.load_case_info, 'nominal_loads') && ...
        isfield(fem.load_case_info.nominal_loads, 'deck_load_node_row')
    resolved_deck_load_node_row = fem.load_case_info.nominal_loads.deck_load_node_row;
end
[H1, Hs1] = prepare_filter(nelx, nely, r1);
[H2, Hs2] = prepare_filter(nelx, nely, r2);

x = ones(nely, nelx);
mi_map = ones(nely, nelx);
x(~designMask & ~fixed_solid_mask) = xmin;
x(fixed_solid_mask) = 1.0;
mi_map(~designMask & ~fixed_solid_mask) = 0;

if analysis_only && isempty(initial_mi_map)
    error('analysis_only requires options.initial_mi_map.');
end
if ~isempty(initial_mi_map)
    if ~isnumeric(initial_mi_map) || ~isreal(initial_mi_map) || ...
            ~isequal(size(initial_mi_map), [nely, nelx]) || ...
            any(~isfinite(initial_mi_map(:))) || ...
            any(~ismember(initial_mi_map(:), [0, 1, 2]))
        error('initial_mi_map must be a finite [nely, nelx] array containing only 0, 1, and 2.');
    end
    mi_map = double(initial_mi_map);
    supplied_solid_mask = mi_map ~= 0;
    if ~isempty(initial_x)
        if ~isnumeric(initial_x) || ~isreal(initial_x) || ...
                ~isequal(size(initial_x), [nely, nelx]) || any(~isfinite(initial_x(:)))
            error('initial_x must be a finite real [nely, nelx] array.');
        end
        if any((initial_x(:) > xmin) ~= supplied_solid_mask(:))
            error('initial_x and initial_mi_map disagree about which elements are solid.');
        end
    end
    if any(supplied_solid_mask(non_design_mask))
        error('The supplied layout contains solid elements in non_design_mask.');
    end
    if any(~supplied_solid_mask(fixed_solid_mask))
        error('Every fixed_solid_mask element must be solid in the supplied layout.');
    end
    x(:) = xmin;
    x(supplied_solid_mask) = 1.0;
end
eta = ones(nely, nelx);
nk = 1;
vol = 1.0;
change = 1.0;
reached_vol = false;
volume_tolerance = 1 / max(1, nelx * nely);

history = struct( ...
    'Vk_hist', [], ...
    'solid_fraction_hist', [], ...
    'nk_hist', [], ...
    'V1_hist', [], ...
    'pre_compliance_hist', [], ...
    'compliance_hist', [], ...
    'change_hist', [], ...
    'target_keep_hist', [], ...
    'effective_keep_hist', [], ...
    'keep_count_hist', [], ...
    'iteration_time_hist', [], ...
    'initial_beso_state', []);

if analysis_only
    final_response = evaluate_design_response( ...
        x, penal, KE1, KE2, KE3, D1, D2, mi_map, fem, ...
        materials, er, volfrac, tension_eta_mode, nk, H1, Hs1, H2, Hs2);
    final_response.eta_filtered_history = final_response.eta_filtered;

    solid_mask = (x > xmin) & (mi_map ~= 0);
    material1_mask = solid_mask & (mi_map == 1);
    material2_mask = solid_mask & (mi_map == 2);
    material1_max_vm = masked_maximum(final_response.sigvm, material1_mask);
    material2_max_vm = masked_maximum(final_response.sigvm, material2_mask);
    safety_factor = min_finite([ ...
        safe_ratio(materials.sigma_m1, material1_max_vm), ...
        safe_ratio(materials.sigma_m2, material2_max_vm)]);
    nodal_displacement = hypot(final_response.U(1:2:end), final_response.U(2:2:end));

    final_response.material1_max_sigvm = material1_max_vm;
    final_response.material2_max_sigvm = material2_max_vm;
    final_response.material_safety_factor = safety_factor;
    final_response.max_displacement = max(nodal_displacement);
    final_response.compliance_N_mm = final_response.compliance;
    final_response.compliance_N_m = final_response.compliance / 1000;

    history.initial_beso_state = struct( ...
        'Vk', nnz(solid_mask) / numel(x), ...
        'solid_fraction', nnz(solid_mask) / numel(x), ...
        'nk', nk, ...
        'V1', nnz(material1_mask) / numel(x), ...
        'compliance', final_response.compliance);

    run_time_seconds = toc(run_timer);
    termination_reason = 'fixed_layout_fem_evaluation_completed';
    settings = struct( ...
        'bc_case', bc_case, ...
        'bc_load', bc_load, ...
        'tension_eta_mode', tension_eta_mode, ...
        'max_iterations', max_iterations, ...
        'penal', penal, ...
        'tau', tau, ...
        'xmin', xmin, ...
        'r1_mm', r1_mm, ...
        'r2_mm', r2_mm, ...
        'structure_width', structure_width, ...
        'structure_height', structure_height, ...
        'structure_dimension_unit', structure_dimension_unit, ...
        'deck_line_load_N_per_m', deck_line_load_N_per_m, ...
        'deck_load_sign', deck_load_sign, ...
        'deck_load_distribution', deck_load_distribution, ...
        'deck_load_node_row', resolved_deck_load_node_row, ...
        'include_self_weight', include_self_weight, ...
        'gravity', gravity, ...
        'gravity_load_sign', gravity_load_sign, ...
        'out_of_plane_thickness_m', out_of_plane_thickness_m, ...
        'out_of_plane_thickness_mm', thickness_mm, ...
        'elSize', elSize, ...
        'even_keep_count', even_keep_count, ...
        'designMask', designMask, ...
        'freeDesignMask', freeDesignMask, ...
        'fixed_solid_mask', fixed_solid_mask, ...
        'non_design_mask', non_design_mask, ...
        'load_case_info', fem.load_case_info, ...
        'analysis_only', true, ...
        'plotting', plotting, ...
        'layout_source', layout_source, ...
        'analysis_completed', true, ...
        'write_run_report', write_run_report, ...
        'run_report_file', run_report_file, ...
        'save_result', save_result, ...
        'result_file', result_file, ...
        'run_time_seconds', run_time_seconds, ...
        'converged', NaN, ... % Fixed-layout analysis has no convergence state.
        'termination_reason', termination_reason);

    result = struct( ...
        'x', x, ...
        'mi_map', mi_map, ...
        'history', history, ...
        'iterations', 0, ...
        'compliance', final_response.compliance, ...
        'response', final_response, ...
        'materials', materials, ...
        'settings', settings, ...
        'converged', NaN, ...
        'analysis_completed', true, ...
        'termination_reason', termination_reason);

    if verbose
        fprintf(['Fixed-layout FEM | Compliance: %.12g N*mm (%.12g N*m) | ', ...
            'VM M1: %.6g MPa | VM M2: %.6g MPa | SF: %.6g | max |U|: %.6g mm\n'], ...
            final_response.compliance_N_mm, final_response.compliance_N_m, ...
            material1_max_vm, material2_max_vm, safety_factor, final_response.max_displacement);
    end
    % Show the supplied material layout as a one-shot FEM result.
    if plotting
        update_iteration_plot([], mi_map, 0, final_response.compliance);
    end
    result = write_run_report_if_requested(result, write_run_report, run_report_file);
    result = save_result_if_requested(result, save_result, result_file);
    return;
end

[U_all, sig1, sig2, sigvm, governing_stress_case] = FE_vectorized( ...
    x, penal, KE1, KE2, KE3, D1, D2, mi_map, fem);
initial_compliance = element_compliance(U_all, x, penal, KE1, KE2, KE3, mi_map, fem);
current_compliance = initial_compliance;
history.initial_beso_state = struct( ...
    'Vk', vol, ...
    'solid_fraction', nnz(x > xmin) / numel(x), ...
    'nk', nk, ...
    'V1', sum((mi_map(:) == 1) & (x(:) > xmin)) / numel(x), ...
    'compliance', initial_compliance);

%% Optimization loop
i = 0;
plot_handle = [];
eta_filtered_history = eta;
while (i < max_iterations) && ((~reached_vol) || (change > tau))
    i = i + 1;
    iteration_timer = tic;

    if i == 1
        eta_filtered_old = eta;
    end

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
        eta_filtered_history, freeDesignMask, fixed_solid_mask, vol_next, even_keep_count);

    x(:) = xmin;
    x(keep_mask) = 1.0;
    x(fixed_solid_mask) = 1.0;
    x(~designMask & ~fixed_solid_mask) = xmin;
    vol = vol_next;

    solid_mask = x > xmin;
    mi_map(:) = 2;
    mi_map(~solid_mask) = 0;
    mi_map(solid_mask & (sigma_e_filtered >= 0)) = 1;
    mi_map(~designMask & ~fixed_solid_mask) = 0;

    [U_all_next, sig1_next, sig2_next, sigvm_next, governing_stress_case_next] = FE_vectorized( ...
        x, penal, KE1, KE2, KE3, D1, D2, mi_map, fem);
    history_compliance = element_compliance( ...
        U_all_next, x, penal, KE1, KE2, KE3, mi_map, fem);

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

    U_all = U_all_next;
    sig1 = sig1_next;
    sig2 = sig2_next;
    sigvm = sigvm_next;
    governing_stress_case = governing_stress_case_next;
    current_compliance = history_compliance;

    if plotting
        plot_handle = update_iteration_plot(plot_handle, mi_map, i, history_compliance);
    end
    if verbose
        print_iteration_summary(i, history_compliance, vol, current_volume_ratio, change, history.V1_hist(end), nk, cutoff);
    end
end

final_response = build_design_response_from_analysis( ...
    U_all, sig1, sig2, sigvm, governing_stress_case, ...
    x, penal, KE1, KE2, KE3, mi_map, fem, ...
    materials, er, volfrac, tension_eta_mode, nk, H1, Hs1, H2, Hs2);
final_response.eta_filtered_history = eta_filtered_history;

if isempty(history.compliance_hist)
    final_compliance = final_response.compliance;
else
    final_compliance = history.compliance_hist(end);
end
run_time_seconds = toc(run_timer);
converged = reached_vol && (change <= tau);
if converged
    termination_reason = 'converged';
elseif i >= max_iterations
    termination_reason = 'max_iterations';
else
    termination_reason = 'stopped_before_convergence';
end

settings = struct( ...
    'bc_case', bc_case, ...
    'bc_load', bc_load, ...
    'tension_eta_mode', tension_eta_mode, ...
    'max_iterations', max_iterations, ...
    'penal', penal, ...
    'tau', tau, ...
    'xmin', xmin, ...
    'r1_mm', r1_mm, ...
    'r2_mm', r2_mm, ...
    'structure_width', structure_width, ...
    'structure_height', structure_height, ...
    'structure_dimension_unit', structure_dimension_unit, ...
    'deck_line_load_N_per_m', deck_line_load_N_per_m, ...
    'deck_load_sign', deck_load_sign, ...
    'deck_load_distribution', deck_load_distribution, ...
    'deck_load_node_row', resolved_deck_load_node_row, ...
    'include_self_weight', include_self_weight, ...
    'gravity', gravity, ...
    'gravity_load_sign', gravity_load_sign, ...
    'out_of_plane_thickness_m', out_of_plane_thickness_m, ...
    'out_of_plane_thickness_mm', thickness_mm, ...
    'elSize', elSize, ...
    'even_keep_count', even_keep_count, ...
        'designMask', designMask, ...
        'freeDesignMask', freeDesignMask, ...
        'fixed_solid_mask', fixed_solid_mask, ...
    'non_design_mask', non_design_mask, ...
        'load_case_info', fem.load_case_info, ...
    'plotting', plotting, ...
    'write_run_report', write_run_report, ...
    'run_report_file', run_report_file, ...
    'save_result', save_result, ...
    'result_file', result_file, ...
    'run_time_seconds', run_time_seconds, ...
    'converged', converged, ...
    'termination_reason', termination_reason);

result = struct( ...
    'x', x, ...
    'mi_map', mi_map, ...
    'history', history, ...
    'iterations', i, ...
    'compliance', final_compliance, ...
    'response', final_response, ...
    'materials', materials, ...
    'settings', settings, ...
    'converged', converged, ...
    'termination_reason', termination_reason);
result = write_run_report_if_requested(result, write_run_report, run_report_file);
result = save_result_if_requested(result, save_result, result_file);
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
    warning('MBESO:RunReportNotWritten', 'Could not write MBESO fixed-solid run report: %s', ME.message);
end
end

function result = save_result_if_requested(result, save_result, result_file)
if ~save_result
    return;
end
if isstring(result_file) && isscalar(result_file)
    result_file = char(result_file);
end
try
    if isempty(result_file)
        result_file = default_result_file_from_solver();
    end
    result_dir = fileparts(result_file);
    if ~isempty(result_dir) && exist(result_dir, 'dir') ~= 7
        mkdir(result_dir);
    end
    result.result_file = result_file;
    result.settings.result_file = result_file;
    save(result_file, 'result');
catch ME
    result.result_file = '';
    result.result_save_error = ME.message;
    result.settings.result_file = '';
    result.settings.result_save_error = ME.message;
    warning('MBESO:ResultNotSaved', 'Could not save MBESO fixed-solid result file: %s', ME.message);
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
report_file = fullfile(results_dir, ['mbeso_fixed_solid_run_report_' timestamp '.txt']);
end

function result_file = default_result_file_from_solver()
repo_root = find_repo_root_from_solver();
results_dir = fullfile(repo_root, 'results');
timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
result_file = fullfile(results_dir, ['mbeso_fixed_solid_result_' timestamp '.mat']);
end

function repo_root = find_repo_root_from_solver()
src_dir = fileparts(mfilename('fullpath'));
candidate_dirs = { ...
    fileparts(src_dir), ...
    fileparts(fileparts(src_dir))};
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
% Fixed-solid elements retain their assigned M1/M2 colors.
if isempty(h) || ~isvalid(h.fig)
    h.fig = figure('Color', 'w', 'Name', 'MBESO fixed-solid material layout', 'NumberTitle', 'off');
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
    h.legend = legend(h.ax, ...
        [h.key_void, h.key_tension, h.key_compression], ...
        {'Void', 'Tension material (M1)', 'Compression material (M2)'}, ...
        'Location', 'southoutside', 'Orientation', 'horizontal', 'Box', 'off', ...
        'FontName', 'Times New Roman', 'FontSize', 10);
else
    set(h.img, 'CData', mi_map);
end
set(h.ax, 'FontName', 'Times New Roman', 'FontSize', 11);
if i == 0
    title_text = sprintf('Fixed-layout FEM  Compliance:%g', compliance);
else
    title_text = sprintf('It:%d  Compliance:%g', i, compliance);
end
title(h.ax, title_text, 'FontName', 'Times New Roman', 'FontWeight', 'normal'); drawnow;
end

function response = evaluate_design_response(x, penal, KE1, KE2, KE3, D1, D2, mi_map, fem, materials, er, volfrac, tension_eta_mode, nk, H1, Hs1, H2, Hs2)
[U_all, sig1, sig2, sigvm, governing_stress_case] = FE_vectorized(x, penal, KE1, KE2, KE3, D1, D2, mi_map, fem);
response = build_design_response_from_analysis( ...
    U_all, sig1, sig2, sigvm, governing_stress_case, ...
    x, penal, KE1, KE2, KE3, mi_map, fem, ...
    materials, er, volfrac, tension_eta_mode, nk, H1, Hs1, H2, Hs2);
end

function response = build_design_response_from_analysis( ...
    U_all, sig1, sig2, sigvm, governing_stress_case, ...
    x, penal, KE1, KE2, KE3, mi_map, fem, ...
    materials, er, volfrac, tension_eta_mode, nk, H1, Hs1, H2, Hs2)
sigma_e = sig1 + sig2;
[~, eta] = update_material_utilization(materials.sigma_m1, materials.sigma_m2, sigvm, er, volfrac, sigma_e, 0, tension_eta_mode, nk);
eta_filtered = apply_filter(H2, Hs2, eta, fem.nely, fem.nelx);
sigma_e_filtered = apply_filter(H1, Hs1, sigma_e, fem.nely, fem.nelx);
compliance = element_compliance(U_all, x, penal, KE1, KE2, KE3, mi_map, fem);
load_case_compliance = compute_load_case_compliance(U_all, x, penal, KE1, KE2, KE3, mi_map, fem);
[~, governing_load_case] = max(load_case_compliance);
if isempty(governing_load_case)
    governing_load_case = 1;
end
U = U_all(:, governing_load_case);
load_case_names = {};
if isfield(fem, 'load_case_info') && isfield(fem.load_case_info, 'names')
    load_case_names = fem.load_case_info.names;
end
[F_total, F_gravity, total_mass_kg] = current_load_vector(x, mi_map, fem);
% Convert sparse load sums to ordinary scalar doubles.
external_vertical_load_N = full(sum(fem.F_base(2:2:end, governing_load_case)));
self_weight_N = full(sum(F_gravity(2:2:end, governing_load_case)));
total_vertical_load_N = full(sum(F_total(2:2:end, governing_load_case)));

response = struct( ...
        'U', U, ...
        'U_all', U_all, ...
        'sig1', sig1, ...
        'sig2', sig2, ...
        'sigvm', sigvm, ...
    'sigma_e', sigma_e, ...
    'sigma_e_filtered', sigma_e_filtered, ...
        'eta', eta, ...
        'eta_filtered', eta_filtered, ...
        'compliance', compliance, ...
        'load_case_compliance', load_case_compliance, ...
        'governing_load_case', governing_load_case, ...
        'governing_stress_case', governing_stress_case, ...
        'load_case_names', {load_case_names}, ...
        'total_mass_kg', total_mass_kg, ...
        'external_vertical_load_N', external_vertical_load_N, ...
        'self_weight_N', self_weight_N, ...
        'total_vertical_load_N', total_vertical_load_N);
end

function [U, sig1, sig2, sigvm, governing_case] = FE_vectorized(x, penal, KE1, KE2, KE3, D1, D2, mi_map, fem)
U = FE_displacement(x, penal, KE1, KE2, KE3, mi_map, fem);
nLC = size(U, 2);
xpen = x(:).^penal;
m1 = mi_map(:) == 1;
sig1_all = zeros(fem.nely, fem.nelx, nLC);
sig2_all = zeros(fem.nely, fem.nelx, nLC);
sigvm_all = zeros(fem.nely, fem.nelx, nLC);

for lc = 1:nLC
    U_lc = U(:, lc);
    Ue = U_lc(fem.edofMat);
    strain = Ue * fem.B';
    stress = zeros(fem.nele, 3);
    stress(m1, :) = bsxfun(@times, strain(m1, :) * D1', xpen(m1));
    stress(~m1, :) = bsxfun(@times, strain(~m1, :) * D2', xpen(~m1));

    sx = stress(:, 1);
    sy = stress(:, 2);
    txy = stress(:, 3);
    avg = 0.5 * (sx + sy);
    rad = sqrt((0.5 * (sx - sy)).^2 + txy.^2);
    sig1_all(:, :, lc) = reshape(avg + rad, fem.nely, fem.nelx);
    sig2_all(:, :, lc) = reshape(avg - rad, fem.nely, fem.nelx);
    sigvm_all(:, :, lc) = reshape(sqrt(sx.^2 - sx .* sy + sy.^2 + 3 * txy.^2), fem.nely, fem.nelx);
end

[sigvm, governing_case] = max(sigvm_all, [], 3);
sig1 = select_load_case_field(sig1_all, governing_case);
sig2 = select_load_case_field(sig2_all, governing_case);
end

function field = select_load_case_field(field_all, governing_case)
[nely, nelx, nLC] = size(field_all);
if nLC == 1
    field = field_all(:, :, 1);
    return;
end
[rows, cols] = ndgrid(1:nely, 1:nelx);
idx = sub2ind([nely, nelx, nLC], rows(:), cols(:), governing_case(:));
field = reshape(field_all(idx), nely, nelx);
end

function U = FE_displacement(x, penal, KE1, KE2, KE3, mi_map, fem)
xpen = x(:)'.^penal;
m1 = (mi_map(:)' == 1);
m2 = (mi_map(:)' == 2);
m0 = ~(m1 | m2);
sK = reshape(KE1(:) * (xpen .* m1) + KE2(:) * (xpen .* m2) + KE3(:) * (xpen .* m0), 64 * fem.nele, 1);
K = sparse(fem.iK, fem.jK, sK, fem.ndof, fem.ndof);
K = (K + K') / 2;
[F, ~, ~] = current_load_vector(x, mi_map, fem);
nLC = size(F, 2);
U = zeros(fem.ndof, nLC);
U(fem.freedofs, :) = K(fem.freedofs, fem.freedofs) \ F(fem.freedofs, :);
U(fem.fixeddofs, :) = 0;
end

function [F, F_gravity, total_mass_kg] = current_load_vector(x, mi_map, fem)
F = fem.F_base;
F_gravity = sparse(fem.ndof, size(F, 2));
total_mass_kg = 0;
if ~fem.include_self_weight
    return;
end

% Void elements (mi_map == 0) carry no mass.
solid = (mi_map(:) ~= 0) & (x(:) > 0);
rho = zeros(fem.nele, 1);
rho(solid & (mi_map(:) == 1)) = fem.rho1;
rho(solid & (mi_map(:) == 2)) = fem.rho2;
rho(solid & (mi_map(:) == 0)) = fem.rho0;

element_mass = rho * fem.element_area_m2 * fem.out_of_plane_thickness_m;
element_weight = fem.gravity_load_sign * element_mass * fem.gravity;
vertical_dofs = fem.edofMat(:, [2 4 6 8]);
gravity_single = sparse(vertical_dofs(:), 1, ...
    reshape(repmat(element_weight / 4, 1, 4), [], 1), fem.ndof, 1);
F_gravity = repmat(gravity_single, 1, size(F, 2));
F = F + F_gravity;
total_mass_kg = sum(element_mass);
end

function compliance = element_compliance(U, x, penal, KE1, KE2, KE3, mi_map, fem)
ce = element_energy(U, KE1, KE2, KE3, mi_map, fem);
compliance = 0.5 * sum((x(:).^penal) .* ce);
end

function compliance_by_case = compute_load_case_compliance(U, x, penal, KE1, KE2, KE3, mi_map, fem)
nLC = size(U, 2);
compliance_by_case = zeros(nLC, 1);
for lc = 1:nLC
    ce = element_energy(U(:, lc), KE1, KE2, KE3, mi_map, fem);
    compliance_by_case(lc) = 0.5 * sum((x(:).^penal) .* ce);
end
end

function ce = element_energy(U, KE1, KE2, KE3, mi_map, fem)
nLC = size(U, 2);
ce = zeros(fem.nele, 1);
m1 = mi_map(:) == 1;
m2 = mi_map(:) == 2;
m0 = ~(m1 | m2);
for lc = 1:nLC
    U_lc = U(:, lc);
    Ue = U_lc(fem.edofMat);
    ce1 = sum((Ue * KE1) .* Ue, 2);
    ce2 = sum((Ue * KE2) .* Ue, 2);
    ce3 = sum((Ue * KE3) .* Ue, 2);
    ce = ce + ce1 .* m1 + ce2 .* m2 + ce3 .* m0;
end
end

function [keep_mask, num_to_keep, cutoff, effective_keep_count] = select_keep_mask(eta_history, freeDesignMask, fixed_solid_mask, vol_next, even_keep_count)
total_elements = numel(eta_history);
num_to_keep = floor(vol_next * total_elements);
num_fixed = nnz(fixed_solid_mask);
num_free_to_keep = max(0, min(num_to_keep - num_fixed, nnz(freeDesignMask)));
keep_mask = fixed_solid_mask;
cutoff = -Inf;
eta_vec = eta_history(freeDesignMask);
total_free = numel(eta_vec);
free_keep_count = num_free_to_keep;

% Optional even-count correction only; mirror pairs are not enforced.
if even_keep_count && mod(free_keep_count, 2) == 1
    if free_keep_count < total_free
        free_keep_count = free_keep_count + 1;
    else
        free_keep_count = free_keep_count - 1;
    end
end
effective_keep_count = num_fixed + free_keep_count;

if free_keep_count > 0
    [eta_sorted, sort_idx] = sort(eta_vec, 'descend');
    keep_vec = false(total_free, 1);
    keep_vec(sort_idx(1:free_keep_count)) = true;
    keep_mask(freeDesignMask) = keep_vec;
    cutoff = eta_sorted(free_keep_count);
end

keep_mask = keep_mask | fixed_solid_mask;
keep_mask = keep_mask & (freeDesignMask | fixed_solid_mask);
if nnz(keep_mask) ~= effective_keep_count
    error('Keep-count selection failed: requested %d total elements but selected %d.', ...
        effective_keep_count, nnz(keep_mask));
end
end

function print_iteration_summary(i, compliance, target_volume_ratio, solid_fraction, change, vol_1_ratio, nk, cutoff)
fprintf('iter %4d | Compliance: %12.6f | Vk: %6.3f | Solid: %6.3f | V1: %6.3f | nk: %.10f | cutoff: %.6e | change: %.6e\n', ...
    i, compliance, target_volume_ratio, solid_fraction, vol_1_ratio, nk, cutoff, change);
end

% Q4 DOF indexing and sparse assembly adapted from BESO79 in NewBESO.
% See THIRD_PARTY_NOTICE.md for the source mapping and preserved MIT notice.
function fem = prepare_fem(nelx, nely, elSize, bc_case, bc_load, ...
    deck_line_load_N_per_m, deck_load_sign, deck_load_distribution, deck_load_node_row, ...
    include_self_weight, gravity, ...
    gravity_load_sign, out_of_plane_thickness_m, materials)
nodenrs = reshape(1:(nelx + 1) * (nely + 1), nely + 1, nelx + 1);
n1 = reshape(nodenrs(1:end-1, 1:end-1), nelx * nely, 1);
n2 = reshape(nodenrs(1:end-1, 2:end), nelx * nely, 1);
edofMat = [2*n1-1, 2*n1, 2*n2-1, 2*n2, 2*n2+1, 2*n2+2, 2*n1+1, 2*n1+2];
iK = reshape(kron(edofMat, ones(8, 1))', 64 * nelx * nely, 1);
jK = reshape(kron(edofMat, ones(1, 8))', 64 * nelx * nely, 1);
ndof = 2 * (nelx + 1) * (nely + 1);
elSize_m = elSize / 1000;
[F_base, fixeddofs, load_case_info] = get_boundary_conditions( ...
    bc_case, bc_load, deck_line_load_N_per_m, deck_load_sign, deck_load_distribution, deck_load_node_row, ...
    nelx, nely, ndof, elSize_m);
freedofs = setdiff(1:ndof, fixeddofs);
fem = struct( ...
        'nelx', nelx, ...
    'nely', nely, ...
    'nele', nelx * nely, ...
    'ndof', ndof, ...
    'edofMat', edofMat, ...
    'iK', iK, ...
    'jK', jK, ...
        'F_base', F_base, ...
        'fixeddofs', fixeddofs, ...
        'freedofs', freedofs, ...
        'load_case_info', load_case_info, ...
        'element_area_m2', elSize_m * elSize_m, ...
        'include_self_weight', include_self_weight, ...
        'gravity', gravity, ...
        'gravity_load_sign', gravity_load_sign, ...
        'out_of_plane_thickness_m', out_of_plane_thickness_m, ...
        'rho1', materials.rho1, ...
        'rho2', materials.rho2, ...
        'rho0', materials.rho0, ...
        'B', (1 / elSize) * B0());
end

function [F, fixeddofs, load_case_info] = get_boundary_conditions( ...
    bc_case, bc_load, deck_line_load_N_per_m, deck_load_sign, deck_load_distribution, deck_load_node_row, ...
    nelx, nely, ndof, elSize_m)
bc_case = lower(char(bc_case));
F = sparse(ndof, 1);
load_case_info = struct('names', {{char(bc_case)}}, 'description', '', 'factors', struct(), 'nominal_loads', struct());

switch bc_case
    case 'cantilever'
        F(2 * (nelx + 1) * (nely + 1), 1) = bc_load;
        fixeddofs = 1:2 * (nely + 1);
        load_case_info.description = sprintf('Concentrated vertical nodal load: %.12g N.', bc_load);
        load_case_info.nominal_loads = struct('point_load_N', bc_load);
    case 'run_case_3b'
        nodenrs = reshape(1:(nelx + 1) * (nely + 1), nely + 1, nelx + 1);
        if isempty(deck_load_node_row)
            deck_load_node_row = 1;
        end
        deck_nodes = nodenrs(deck_load_node_row, :);
        [deck_node_load, load_description, nominal_loads] = make_deck_node_load( ...
            nelx, elSize_m, bc_load, deck_line_load_N_per_m, deck_load_sign, deck_load_distribution);
        F(2 * deck_nodes, 1) = deck_node_load(:);
        support_nodes = nodenrs(1, :);
        nLeft = support_nodes(1);
        nRight = support_nodes(end);
        fixeddofs = [2*nLeft-1; 2*nLeft; 2*nRight];
        load_case_info.description = sprintf([ ...
            'Upper retained-deck bridge; load applied at node row %d (y = %.12g m); ' ...
            'supports at the upper-boundary endpoints; %s'], ...
            deck_load_node_row, (deck_load_node_row - 1) * elSize_m, load_description);
        nominal_loads.deck_load_node_row = deck_load_node_row;
        nominal_loads.deck_load_y_m = (deck_load_node_row - 1) * elSize_m;
        load_case_info.nominal_loads = nominal_loads;
    case 'run_case_3a'
        nodenrs = reshape(1:(nelx + 1) * (nely + 1), nely + 1, nelx + 1);
        if isempty(deck_load_node_row)
            deck_load_node_row = nely + 1;
        end
        deck_surface_nodes = nodenrs(deck_load_node_row, :);
        support_nodes = nodenrs(end, :);
        [deck_node_load, load_description, nominal_loads] = make_deck_node_load( ...
            nelx, elSize_m, bc_load, deck_line_load_N_per_m, deck_load_sign, deck_load_distribution);
        F(2 * deck_surface_nodes, 1) = deck_node_load(:);
        nLeft = support_nodes(1);
        nRight = support_nodes(end);
        fixeddofs = [2*nLeft-1; 2*nLeft; 2*nRight];
        load_case_info.description = sprintf([ ...
            'Lower retained-deck bridge; load applied at node row %d (y = %.12g m); ' ...
            'supports at the lower-boundary endpoints; %s'], ...
            deck_load_node_row, (deck_load_node_row - 1) * elSize_m, load_description);
        nominal_loads.deck_load_node_row = deck_load_node_row;
        nominal_loads.deck_load_y_m = (deck_load_node_row - 1) * elSize_m;
        load_case_info.nominal_loads = nominal_loads;
    otherwise
        error('Unknown bc_case: %s', bc_case);
end

fixeddofs = unique(fixeddofs(:))';
end

function [deck_node_load, description, nominal_loads] = make_deck_node_load( ...
    nelx, elSize_m, bc_load, deck_line_load_N_per_m, deck_load_sign, deck_load_distribution)
if isempty(deck_line_load_N_per_m)
    deck_node_load = bc_load * ones(1, nelx + 1);
    description = sprintf('backward-compatible equal nodal loads of %.12g N at %d nodes.', bc_load, nelx + 1);
    nominal_loads = struct( ...
        'legacy_nodal_load_N', bc_load, ...
        'total_external_load_N', sum(deck_node_load));
    return;
end

span_m = nelx * elSize_m;
total_external_load_N = deck_load_sign * deck_line_load_N_per_m * span_m;
switch deck_load_distribution
    case 'consistent'
        deck_node_load = deck_load_sign * deck_line_load_N_per_m * elSize_m * ones(1, nelx + 1);
        deck_node_load([1 end]) = 0.5 * deck_node_load([1 end]);
        description = sprintf( ...
            'consistent nodal loads for q = %.12g N/m over %.12g m.', ...
            deck_line_load_N_per_m, span_m);
    case 'equal_nodes'
        deck_node_load = (total_external_load_N / (nelx + 1)) * ones(1, nelx + 1);
        description = sprintf( ...
            'equal nodal loads at %d nodes for q = %.12g N/m over %.12g m.', ...
            nelx + 1, deck_line_load_N_per_m, span_m);
    otherwise
        error('Unknown deck_load_distribution: %s', deck_load_distribution);
end
nominal_loads = struct( ...
    'deck_line_load_N_per_m', deck_line_load_N_per_m, ...
    'deck_load_distribution', deck_load_distribution, ...
    'first_nodal_load_N', deck_node_load(1), ...
    'interior_nodal_load_N', deck_node_load(ceil((nelx + 1) / 2)), ...
    'last_nodal_load_N', deck_node_load(end), ...
    'total_external_load_N', sum(deck_node_load));
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
        [i2, j2] = ndgrid(max(i1 - (ceil(rmin) - 1), 1):min(i1 + (ceil(rmin) - 1), nelx), ...
                          max(j1 - (ceil(rmin) - 1), 1):min(j1 + (ceil(rmin) - 1), nely));
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
k = [1/2-nu/6, 1/8+nu/8, -1/4-nu/12, -1/8+3*nu/8, ...
    -1/4+nu/12, -1/8-nu/8, nu/6, 1/8-3*nu/8];
KE = E/(1-nu^2) * [ ...
    k(1) k(2) k(3) k(4) k(5) k(6) k(7) k(8)
    k(2) k(1) k(8) k(7) k(6) k(5) k(4) k(3)
    k(3) k(8) k(1) k(6) k(7) k(4) k(5) k(2)
    k(4) k(7) k(6) k(1) k(8) k(3) k(2) k(5)
    k(5) k(6) k(7) k(8) k(1) k(2) k(3) k(4)
    k(6) k(5) k(4) k(3) k(2) k(1) k(8) k(7)
    k(7) k(4) k(5) k(2) k(3) k(8) k(1) k(6)
    k(8) k(3) k(2) k(5) k(4) k(7) k(6) k(1)];
end

function B = B0()
B = 1/2 * [ ...
    -1  0  1  0  1  0 -1  0
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
if abs(elx - ely) > 1e-9
    error('Automatic elSize requires square elements: width/nelx (%.6f mm) must match height/nely (%.6f mm).', elx, ely);
end
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

function value = masked_maximum(field_value, mask)
values = field_value(mask & isfinite(field_value));
if isempty(values)
    value = NaN;
else
    value = max(values);
end
end

function value = safe_ratio(numerator, denominator)
if ~isfinite(denominator) || denominator <= 0
    value = NaN;
else
    value = numerator / denominator;
end
end

function value = min_finite(values)
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = min(values);
end
end

function value = get_option(options, field_name, default_value)
if isfield(options, field_name) && ~isempty(options.(field_name))
    value = options.(field_name);
else
    value = default_value;
end
end

function merged = merge_struct(defaults, overrides)
merged = defaults;
if isempty(overrides)
    return;
end
if ~isstruct(overrides) || ~isscalar(overrides)
    error('materials must be a scalar struct.');
end
names = fieldnames(overrides);
for k = 1:numel(names)
    merged.(names{k}) = overrides.(names{k});
end
end
