% SPDX-License-Identifier: GPL-3.0-or-later
function test_material_palette()
%TEST_MATERIAL_PALETTE Guard material IDs, legend colors and numerical output.
% These small real solves exercise both solver plot paths. No reference
% image colors or manuscript captions are used to infer material identity.
repo_root = fileparts(fileparts(mfilename('fullpath')));
original_path = path;
old_visibility = get(groot, 'DefaultFigureVisible');
original_figures = findall(groot, 'Type', 'figure');
cleanup = onCleanup(@() restore_environment(original_path, old_visibility, original_figures)); %#ok<NASGU>
addpath(fullfile(repo_root, 'src'), fullfile(repo_root, 'visualization'));
set(groot, 'DefaultFigureVisible', 'off');

expected_map = [1 1 1; 0 0 1; 1 0 0];
palette = mbeso_material_palette();
assert(isequal(palette.map, expected_map), 'Material IDs 0/1/2 must map to white/blue/red.');

base = struct('max_iterations', 3, 'force_iteration_limit', true, ...
    'verbose', false, 'plotting', false, 'write_run_report', false, ...
    'save_result', false, 'structure_width', 120, 'structure_height', 60, ...
    'structure_dimension_unit', 'mm', 'out_of_plane_thickness_m', 1e-3, ...
    'r1_mm', 15, 'r2_mm', 20, 'bc_case', 'cantilever', 'bc_load', 100);
for case_number = 1:3
    options = base;
    if case_number == 1
        solver = @mbeso;
    else
        solver = @mbeso_fixed_solid;
        options.include_self_weight = true;
        options.deck_line_load_N_per_m = 1000;
        options.deck_load_distribution = 'equal_nodes';
        mask = false(6, 12);
        if case_number == 2
            options.bc_case = 'run_case_3a';
            options.deck_load_node_row = 6;
            mask(end, :) = true;
        else
            options.bc_case = 'run_case_3b';
            options.deck_load_node_row = 1;
            mask(1, :) = true;
        end
        options.fixed_solid_mask = mask;
    end
    without_plot = solver(12, 6, 0.6, 0.1, options);
    before = findall(groot, 'Type', 'figure');
    options.plotting = true;
    with_plot = solver(12, 6, 0.6, 0.1, options);
    assert(isequal(with_plot.x, without_plot.x));
    assert(isequal(with_plot.mi_map, without_plot.mi_map));
    assert(isequal(with_plot.response.U, without_plot.response.U));
    assert(isequal(with_plot.response.sigvm, without_plot.response.sigvm));
    assert(isequal(with_plot.compliance, without_plot.compliance));
    current = findall(groot, 'Type', 'figure');
    figures = current(~ismember(current, before));
    assert(numel(figures) == 1, 'Each solver should open one material-layout figure.');
    images = findall(figures, 'Type', 'image');
    assert(numel(images) == 1);
    assert(isequal(images.CData, with_plot.mi_map), ...
        'Displayed material IDs must match the returned final iteration.');
    ax = ancestor(images, 'axes');
    assert(isequal(colormap(ax), expected_map));
    assert(isequal(ax.CLim, [0 2]));
    check_legend(figures, {'Void', 'Tension material (M1)', ...
        'Compression material (M2)'}, expected_map);
end

% Exercise RGB mesh output independently of the indexed solver images.
mesh_results = cell(1, 3);
for k = 1:3
    ids = repmat([0 1 2; 2 1 0], 1, k);
    mesh_results{k} = struct('x', double(ids > 0), 'mi_map', ids);
end
mesh_figure = mbeso_plot_cantilever_mesh_material_layouts(mesh_results);
images = findall(mesh_figure, 'Type', 'image');
assert(numel(images) == 3);
for k = 1:numel(images)
    width = size(images(k).CData, 2);
    ids = mesh_results{width / 3}.mi_map;
    expected_rgb = reshape(expected_map(ids(:) + 1, :), [size(ids), 3]);
    assert(isequal(images(k).CData, expected_rgb));
end
check_legend(mesh_figure, {'Tensile material', 'Compressive material', 'Void'}, ...
    expected_map([2 3 1], :));

% The assigned-material utilization uses positive blue M1 and negative red
% M2 even when the unfiltered stress sum has the opposite sign.
contour_result = struct('x', [1 1 1e-3; 1 1 1e-3], ...
    'mi_map', [1 2 0; 1 2 0], 'settings', struct('xmin', 1e-3), ...
    'materials', struct('sigma_m1', 250, 'sigma_m2', 50), ...
    'response', struct('sigvm', [125 50 0; 50 25 0], ...
    'sigma_e', [-10 10 0; -20 20 0]));
contour_figure = mbeso_plot_stress_contours(contour_result);
images = findall(contour_figure, 'Type', 'image');
found_utilization = false;
for k = 1:numel(images)
    data = getappdata(images(k), 'MBESO_ElementDatatipData');
    if isstruct(data) && isfield(data, 'material_map')
        found_utilization = true;
        assert(isequaln(data.values, [50 -100 NaN; 20 -50 NaN]));
        map = colormap(ancestor(images(k), 'axes'));
        assert(isequal(map(1, :), [1 0 0]));
        assert(isequal(map(end, :), [0 0 1]));
    end
end
assert(found_utilization);
fprintf('Material palette checks passed: 3 solver plots, mesh layouts and utilization.\n');
end

function check_legend(fig, names, colors)
legends = findall(fig, 'Type', 'legend');
assert(numel(legends) == 1);
assert(isequal(string(legends.String(:)), string(names(:))));
for k = 1:numel(names)
    proxy = findall(fig, 'Type', 'line', 'DisplayName', names{k});
    assert(numel(proxy) == 1, 'Missing or duplicate material legend proxy.');
    assert(isequal(proxy.MarkerFaceColor, colors(k, :)), ...
        'Material legend color differs from the material ID convention.');
end
end

function restore_environment(original_path, old_visibility, original_figures)
current = findall(groot, 'Type', 'figure');
new_figures = current(~ismember(current, original_figures));
if ~isempty(new_figures)
    close(new_figures);
end
set(groot, 'DefaultFigureVisible', old_visibility);
path(original_path);
end
