% SPDX-License-Identifier: GPL-3.0-or-later
% Copyright (C) 2026 MBESO2D contributors
function test_assigned_material_utilization()
%TEST_ASSIGNED_MATERIAL_UTILIZATION Check physical postprocessing, without FEM.
repo_root = fileparts(fileparts(mfilename('fullpath')));
original_path = path;
cleanup_path = onCleanup(@() path(original_path));
addpath(fullfile(repo_root, 'src'), fullfile(repo_root, 'visualization'));

% Deliberately reverse raw stress signs relative to assigned material IDs and
% use nondefault strengths. Neither stress sign nor optimization eta is the
% assigned-material denominator or display sign.
result = struct('x', [1, 1, 1e-3; 1, 1, 1e-3], ...
    'mi_map', [1, 2, 0; 1, 2, 0], ...
    'settings', struct('xmin', 1e-3), ...
    'materials', struct('sigma_m1', 300, 'sigma_m2', 40), ...
    'response', struct('sigvm', [150, 80, NaN; 90, 60, 1e12], ...
        'sigma_e', [-10, 10, 0; -20, 20, 0], ...
        'eta', ones(2, 3) * 99, 'eta_filtered', ones(2, 3) * 77));
expected = [50, -200, NaN; 30, -150, NaN];
utilization = mbeso_assigned_material_utilization(result);
assert(isequaln(utilization.signed_percent, expected));
assert(isequaln(utilization.percent, abs(expected)));
assert(utilization.tensile_max_percent == 50);
assert(utilization.compressive_max_percent == 200);
assert(utilization.tensile_max_element_index == 1);
assert(utilization.compressive_max_element_index == 3);
assert(isequal(utilization.tensile_mask, result.mi_map == 1));
assert(isequal(utilization.compressive_mask, result.mi_map == 2));
assert(isequal(utilization.solid_mask, result.x > result.settings.xmin));

without_optimization_fields = result;
without_optimization_fields.response = rmfield(result.response, ...
    {'sigma_e', 'eta', 'eta_filtered'});
assert(isequaln(mbeso_assigned_material_utilization(without_optimization_fields), utilization));

one_material = result;
one_material.mi_map(one_material.mi_map == 1) = 2;
one_material.response.sigvm(:) = 0;
one_utilization = mbeso_assigned_material_utilization(one_material);
assert(isnan(one_utilization.tensile_max_percent));
assert(isnan(one_utilization.tensile_max_element_index));
assert(one_utilization.compressive_max_percent == 0);
assert(nnz(one_utilization.compressive_mask) == 4);

all_void = result;
all_void.x(:) = result.settings.xmin;
all_void.mi_map(:) = 0;
all_void.response.sigvm(:) = NaN;
void_utilization = mbeso_assigned_material_utilization(all_void);
assert(all(isnan(void_utilization.percent(:))));
assert(isnan(void_utilization.tensile_max_percent));
assert(isnan(void_utilization.compressive_max_percent));

invalid = result;
invalid.mi_map(1) = 0;
assert_invalid(invalid, 'UnassignedSolid');
invalid = result;
invalid.mi_map(1) = 3;
assert_invalid(invalid, 'InvalidMaterialMap');
invalid = result;
invalid.response.sigvm = zeros(3, 2);
assert_invalid(invalid, 'InvalidStress');
invalid = result;
invalid.response.sigvm(1) = NaN;
assert_invalid(invalid, 'InvalidStress');
invalid = result;
invalid.response.sigvm(1) = -1;
assert_invalid(invalid, 'InvalidStress');
invalid = result;
invalid.materials.sigma_m1 = 0;
assert_invalid(invalid, 'InvalidStrength');

old_visibility = get(groot, 'DefaultFigureVisible');
cleanup_visibility = onCleanup(@() set(groot, 'DefaultFigureVisible', old_visibility));
set(groot, 'DefaultFigureVisible', 'off');
fig = mbeso_plot_stress_contours(result);
cleanup_figure = onCleanup(@() close(fig));
images = findall(fig, 'Type', 'image');
assert(numel(images) == 3, 'The public contour must retain its three original panels.');
utilization_image = [];
for k = 1:numel(images)
    data = getappdata(images(k), 'MBESO_ElementDatatipData');
    if isfield(data, 'material_map')
        utilization_image = images(k);
        assert(isequal(data.material_map, result.mi_map));
        assert(isequaln(data.values, expected));
        assert(isequaln(data.utilization_percent, abs(expected)));
        assert(~data.show_stress_state, 'Material sign must not be labeled as raw stress state.');
    end
end
assert(~isempty(utilization_image));
assert(isequaln(get(utilization_image, 'CData'), [1 -1 NaN;.6 -.75 NaN]));
assert(isequal(logical(get(utilization_image, 'AlphaData')), utilization.solid_mask));
utilization_axes = ancestor(utilization_image, 'axes');
assert(isequal(get(utilization_axes, 'CLim'), [-1, 1]), ...
    'Display coordinates must center zero using separate negative/positive halves.');
scale = getappdata(utilization_image, 'MBESO_ColorScale');
assert(isequal(scale.extrema, [-200 50]));
assert(isequal(scale.physical_ticks, [-200 -100 0 25 50]));
assert(isequal(scale.tick_labels, {'-200','-100','0','25','50'}));
cmap = colormap(utilization_axes);
assert(isequal(cmap(1, :), [1, 0, 0]));
assert(isequal(cmap(end, :), [0, 0, 1]));
zero_index = (size(cmap, 1) + 1) / 2;
assert(isequal(cmap(zero_index, :), [1, 1, 1]));

% The zero anchor and physical limits must also work when one material is
% absent and when the surviving material has zero utilization everywhere.
for material_id = 1:2
    one_sided = result;
    one_sided.mi_map(utilization.solid_mask) = material_id;
    one_sided_utilization = mbeso_assigned_material_utilization(one_sided);
    one_sided_figure = mbeso_plot_stress_contours(one_sided);
    cleanup_one_sided = onCleanup(@() close(one_sided_figure));
    one_sided_images = findall(one_sided_figure, 'Type', 'image');
    for k = 1:numel(one_sided_images)
        data = getappdata(one_sided_images(k), 'MBESO_ElementDatatipData');
        if isfield(data, 'material_map')
            values = one_sided_utilization.signed_percent;
            values = values(isfinite(values));
            scale = getappdata(one_sided_images(k), 'MBESO_ColorScale');
            assert(isequal(get(ancestor(one_sided_images(k), 'axes'), 'CLim'), [-1 1]));
            assert(scale.negative_limit == min(0,min(values)));
            assert(scale.positive_limit == max(0,max(values)));
            if material_id == 1
                assert(all(cellfun(@isempty,scale.tick_labels(scale.ticks<0))));
            else
                assert(all(cellfun(@isempty,scale.tick_labels(scale.ticks>0))));
            end
        end
    end
    clear cleanup_one_sided
end

zero_figure = mbeso_plot_stress_contours(one_material);
cleanup_zero_figure = onCleanup(@() close(zero_figure));
zero_images = findall(zero_figure, 'Type', 'image');
for k = 1:numel(zero_images)
    data = getappdata(zero_images(k), 'MBESO_ElementDatatipData');
    if isfield(data, 'material_map')
        assert(isequal(get(ancestor(zero_images(k), 'axes'), 'CLim'), [-1, 1]));
        assert(all(data.values(one_utilization.solid_mask) == 0));
    end
end

report_file = [tempname, '.txt'];
cleanup_report = onCleanup(@() delete_if_present(report_file));
mbeso_write_run_report(result, report_file, 0);
report = fileread(report_file);
assert(contains(report, 'Optimization metric: max raw eta'));
assert(contains(report, 'Optimization metric: max filtered eta'));
assert(contains(report, 'Max assigned M1 utilization (full M1 solid domain, positive percent): 50'));
assert(contains(report, 'Max assigned M2 utilization (full M2 solid domain, positive percent): 200'));
fprintf('Assigned-material utilization postprocessing tests passed.\n');
end

function assert_invalid(result, suffix)
try
    mbeso_assigned_material_utilization(result);
catch exception
    assert(strcmp(exception.identifier, ['MBESO2D:AssignedUtilization:', suffix]), ...
        'Unexpected validation error: %s', exception.identifier);
    return;
end
error('Expected assigned-utilization validation error: %s', suffix);
end

function delete_if_present(file)
if exist(file, 'file') == 2
    delete(file);
end
end
