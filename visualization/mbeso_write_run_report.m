% SPDX-License-Identifier: GPL-3.0-or-later
% Copyright (C) 2026 MBESO2D contributors
function report_file = mbeso_write_run_report(result, report_file, elapsed_seconds)
%MBESO_WRITE_RUN_REPORT Write environment, settings, and iteration log to text.
%
%   report_file = mbeso_write_run_report(result)
%   report_file = mbeso_write_run_report(result, report_file)
%   report_file = mbeso_write_run_report(result, report_file, elapsed_seconds)
%
% If report_file is omitted, the report is written to the repository results
% folder. elapsed_seconds can be supplied when timing was measured outside the
% solver; otherwise result.settings.run_time_seconds is used when available.

if nargin < 1 || ~isstruct(result)
    error('A result structure returned by an MBESO solver is required.');
end
if nargin < 2 || isempty(report_file)
    report_file = default_report_file();
end
if isstring(report_file) && isscalar(report_file)
    report_file = char(report_file);
end
if nargin < 3
    elapsed_seconds = get_optional_scalar(result, {'settings', 'run_time_seconds'}, NaN);
end

report_dir = fileparts(report_file);
if ~isempty(report_dir) && exist(report_dir, 'dir') ~= 7
    mkdir(report_dir);
end

fid = fopen(report_file, 'w');
if fid < 0
    error('Could not open report file for writing: %s', report_file);
end
cleanup_file = onCleanup(@() fclose(fid));

fprintf(fid, 'MBESO2D run report\n');
generated_at = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss');
fprintf(fid, 'Generated: %s\n', char(generated_at));
fprintf(fid, 'Report file: %s\n\n', report_file);

write_environment(fid);
write_run_summary(fid, result, elapsed_seconds);
write_settings(fid, result);
write_history(fid, result);
write_response_summary(fid, result);

fprintf(fid, '\nEnd of report\n');
clear cleanup_file
end

function report_file = default_report_file()
repo_root = fileparts(fileparts(mfilename('fullpath')));
results_dir = fullfile(repo_root, 'results');
timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
report_file = fullfile(results_dir, ['mbeso_run_report_' timestamp '.txt']);
end

function write_environment(fid)
fprintf(fid, 'Environment\n');
fprintf(fid, '-----------\n');
fprintf(fid, 'MATLAB version: %s\n', version);
fprintf(fid, 'MATLAB release: %s\n', safe_eval_string(@() version('-release')));
fprintf(fid, 'Computer: %s\n', computer);
fprintf(fid, 'Operating system: %s\n', get_os_description());
fprintf(fid, 'CPU: %s\n', get_cpu_description());
fprintf(fid, 'CPU cores: %s\n', safe_eval_string(@() num2str(feature('numcores'))));
fprintf(fid, 'Physical RAM: %s\n\n', get_ram_description());
end

function write_run_summary(fid, result, elapsed_seconds)
fprintf(fid, 'Run summary\n');
fprintf(fid, '-----------\n');
if isfield(result, 'x')
    fprintf(fid, 'Density field size [nely, nelx]: [%d, %d]\n', size(result.x, 1), size(result.x, 2));
    xmin = get_optional_scalar(result, {'settings', 'xmin'}, 1e-3);
    solid_mask = result.x > xmin;
    fprintf(fid, 'Final solid ratio: %.12g\n', nnz(solid_mask) / numel(result.x));
end
if isfield(result, 'mi_map')
    fprintf(fid, 'Material ID counts: void=%d, material1=%d, material2=%d\n', ...
        nnz(result.mi_map == 0), nnz(result.mi_map == 1), nnz(result.mi_map == 2));
end
fprintf(fid, 'Iterations: %s\n', value_to_string(get_optional_scalar(result, {'iterations'}, NaN)));
fprintf(fid, 'Converged: %s\n', value_to_string(get_optional_scalar(result, {'converged'}, NaN)));
fprintf(fid, 'Termination reason: %s\n', get_optional_text(result, {'termination_reason'}, ...
    get_optional_text(result, {'settings', 'termination_reason'}, 'not_recorded')));
fprintf(fid, 'Final compliance (N*mm): %s\n', value_to_string(get_optional_scalar(result, {'compliance'}, NaN)));
fprintf(fid, 'Recorded run time (s): %s\n\n', value_to_string(elapsed_seconds));
end

function write_settings(fid, result)
fprintf(fid, 'Settings\n');
fprintf(fid, '--------\n');
if ~isfield(result, 'settings') || ~isstruct(result.settings)
    fprintf(fid, 'No settings structure found.\n\n');
    return;
end

settings = result.settings;
names = fieldnames(settings);
for k = 1:numel(names)
    name = names{k};
    value = settings.(name);
    if strcmp(name, 'load_case_info')
        write_load_case_info(fid, value);
    else
        fprintf(fid, '%s: %s\n', name, summarize_value(value));
    end
end
fprintf(fid, '\n');
end

function write_load_case_info(fid, value)
if ~isstruct(value)
    fprintf(fid, 'load_case_info: %s\n', summarize_value(value));
    return;
end
if isfield(value, 'description')
    fprintf(fid, 'load_case_info.description: %s\n', value.description);
end
if isfield(value, 'names')
    names = value.names;
    fprintf(fid, 'load_case_info.names count: %d\n', numel(names));
    for k = 1:numel(names)
        fprintf(fid, '  LC%d: %s\n', k, names{k});
    end
end
end

function write_history(fid, result)
fprintf(fid, 'Iteration log\n');
fprintf(fid, '-------------\n');
if ~isfield(result, 'history') || ~isstruct(result.history)
    fprintf(fid, 'No history structure found.\n\n');
    return;
end

history = result.history;
niter = max_history_length(history);
if niter == 0
    fprintf(fid, 'No iteration history found.\n\n');
    return;
end

fprintf(fid, '%6s %14s %14s %14s %24s %24s %14s %14s %14s %14s %14s\n', ...
    'iter', 'Vk', 'V1', 'nk', 'pre_compliance', 'compliance', 'change', ...
    'target_keep', 'effective_keep', 'keep_count', 'iter_time_s');
for i = 1:niter
    fprintf(fid, '%6d %14s %14s %14s %24s %24s %14s %14s %14s %14s %14s\n', ...
        i, ...
        value_to_string(history_value(history, 'Vk_hist', i)), ...
        value_to_string(history_value(history, 'V1_hist', i)), ...
        value_to_string(history_value(history, 'nk_hist', i)), ...
        value_to_string(history_value(history, 'pre_compliance_hist', i)), ...
        value_to_string(history_value(history, 'compliance_hist', i)), ...
        value_to_string(history_value(history, 'change_hist', i)), ...
        value_to_string(history_value(history, 'target_keep_hist', i)), ...
        value_to_string(history_value(history, 'effective_keep_hist', i)), ...
        value_to_string(history_value(history, 'keep_count_hist', i)), ...
        value_to_string(history_value(history, 'iteration_time_hist', i)));
end
fprintf(fid, '\n');

if isfield(history, 'initial_beso_state')
    write_initial_beso_state(fid, history.initial_beso_state);
end
end

function write_initial_beso_state(fid, state)
if ~isstruct(state)
    fprintf(fid, 'Initial BESO state: %s\n\n', summarize_value(state));
    return;
end
fprintf(fid, 'Initial BESO state:\n');
if isfield(state, 'Vk')
    fprintf(fid, '  Vk: %s\n', value_to_string(state.Vk));
end
if isfield(state, 'V1')
    fprintf(fid, '  V1: %s\n', value_to_string(state.V1));
end
if isfield(state, 'nk')
    fprintf(fid, '  nk: %s\n', value_to_string(state.nk));
end
if isfield(state, 'compliance')
    fprintf(fid, '  compliance: %s\n', value_to_string(state.compliance));
end
fprintf(fid, '\n');
end

function write_response_summary(fid, result)
fprintf(fid, 'Response summary\n');
fprintf(fid, '----------------\n');
if ~isfield(result, 'response') || ~isstruct(result.response)
    fprintf(fid, 'No response structure found.\n');
    return;
end

response = result.response;
if isfield(response, 'load_case_compliance')
    values = response.load_case_compliance(:);
    fprintf(fid, 'Load-case compliance:');
    for k = 1:numel(values)
        fprintf(fid, ' %.12g', values(k));
    end
    fprintf(fid, '\n');
end
if isfield(response, 'governing_load_case')
    fprintf(fid, 'Governing load case: %s\n', summarize_value(response.governing_load_case));
end
solid_mask = get_solid_mask(result);
fprintf(fid, 'Max von Mises stress (full solid domain): %s\n', ...
    value_to_string(masked_response_max(response, 'sigvm', solid_mask)));
fprintf(fid, 'Max raw utilization (full solid domain): %s\n', ...
    value_to_string(masked_response_max(response, 'eta', solid_mask)));
fprintf(fid, 'Max filtered utilization (full solid domain): %s\n', ...
    value_to_string(masked_response_max(response, 'eta_filtered', solid_mask)));
write_optional_response_scalar(fid, response, 'compliance_N_m', 'Compliance (N*m)');
write_optional_response_scalar(fid, response, 'material1_max_sigvm', 'Max von Mises stress, material 1 (MPa)');
write_optional_response_scalar(fid, response, 'material2_max_sigvm', 'Max von Mises stress, material 2 (MPa)');
write_optional_response_scalar(fid, response, 'material_safety_factor', 'Material safety factor');
write_optional_response_scalar(fid, response, 'max_displacement', 'Maximum displacement magnitude (mm)');
write_optional_response_scalar(fid, response, 'total_mass_kg', 'Total solid mass (kg)');
write_optional_response_scalar(fid, response, 'external_vertical_load_N', 'External vertical load (N)');
write_optional_response_scalar(fid, response, 'self_weight_N', 'Self-weight (N)');
end

function write_optional_response_scalar(fid, response, field_name, label)
if isfield(response, field_name) && isnumeric(response.(field_name)) && ...
        isscalar(response.(field_name))
    fprintf(fid, '%s: %s\n', label, value_to_string(response.(field_name)));
end
end

function solid_mask = get_solid_mask(result)
xmin = 1e-3;
if isfield(result, 'settings') && isstruct(result.settings) && ...
        isfield(result.settings, 'xmin') && isnumeric(result.settings.xmin) && ...
        isscalar(result.settings.xmin) && isfinite(result.settings.xmin)
    xmin = result.settings.xmin;
end
solid_mask = result.x > xmin;
end

function value = masked_response_max(response, field_name, mask)
value = NaN;
if ~isfield(response, field_name) || isempty(response.(field_name))
    return;
end
field_value = response.(field_name);
if ~isequal(size(field_value), size(mask))
    return;
end
values = field_value(mask & isfinite(field_value));
if ~isempty(values)
    value = max(values);
end
end

function n = max_history_length(history)
fields = {'Vk_hist', 'V1_hist', 'nk_hist', 'pre_compliance_hist', 'compliance_hist', ...
    'change_hist', 'target_keep_hist', 'effective_keep_hist', 'keep_count_hist', ...
    'iteration_time_hist'};
n = 0;
for k = 1:numel(fields)
    if isfield(history, fields{k})
        n = max(n, numel(history.(fields{k})));
    end
end
end

function value = history_value(history, field_name, index)
value = NaN;
if isfield(history, field_name)
    values = history.(field_name);
    if numel(values) >= index
        value = values(index);
    end
end
end

function value = get_optional_scalar(s, path_parts, default_value)
value = default_value;
try
    current = s;
    for k = 1:numel(path_parts)
        if isstruct(current) && isfield(current, path_parts{k})
            current = current.(path_parts{k});
        else
            return;
        end
    end
    if (isnumeric(current) || islogical(current)) && isscalar(current)
        value = current;
    end
catch
    value = default_value;
end
end

function text = get_optional_text(s, path_parts, default_text)
text = default_text;
try
    current = s;
    for k = 1:numel(path_parts)
        if isstruct(current) && isfield(current, path_parts{k})
            current = current.(path_parts{k});
        else
            return;
        end
    end
    if ischar(current)
        text = current;
    elseif isstring(current) && isscalar(current)
        text = char(current);
    elseif islogical(current) && isscalar(current)
        text = logical_to_string(current);
    elseif isnumeric(current) && isscalar(current)
        text = value_to_string(current);
    end
catch
    text = default_text;
end
end

function text = summarize_value(value)
if ischar(value)
    text = value;
elseif isstring(value) && isscalar(value)
    text = char(value);
elseif islogical(value)
    if isscalar(value)
        text = logical_to_string(value);
    else
        text = sprintf('logical %s, true_count=%d', size_to_string(size(value)), nnz(value));
    end
elseif isnumeric(value)
    if isscalar(value)
        text = value_to_string(value);
    elseif isempty(value)
        text = '[]';
    else
        text = sprintf('numeric %s, min=%.12g, max=%.12g', ...
            size_to_string(size(value)), min(value(:)), max(value(:)));
    end
elseif iscell(value)
    text = sprintf('cell %s', size_to_string(size(value)));
elseif isstruct(value)
    names = fieldnames(value);
    text = ['struct fields={' strjoin(names(:).', ', ') '}'];
else
    text = class(value);
end
end

function text = value_to_string(value)
if isnumeric(value) && isscalar(value)
    if isnan(value)
        text = 'not_recorded';
    else
        text = sprintf('%.12g', value);
    end
elseif islogical(value) && isscalar(value)
    text = logical_to_string(value);
else
    text = summarize_value(value);
end
end

function text = logical_to_string(value)
if value
    text = 'true';
else
    text = 'false';
end
end

function text = size_to_string(sz)
parts = arrayfun(@num2str, sz, 'UniformOutput', false);
text = ['[' strjoin(parts, 'x') ']'];
end

function text = get_os_description()
if ispc
    text = getenv('OS');
    extra = safe_system_text('ver');
    if ~isempty(extra)
        text = strtrim([text ' ' extra]);
    end
elseif ismac
    text = safe_system_text('sw_vers -productVersion');
    if isempty(text)
        text = 'macOS';
    else
        text = ['macOS ' text];
    end
elseif isunix
    text = safe_system_text('uname -a');
else
    text = 'unknown';
end
if isempty(text)
    text = 'unknown';
end
end

function text = get_cpu_description()
text = getenv('PROCESSOR_IDENTIFIER');
if isempty(text) && ispc
    text = safe_system_text('wmic cpu get name');
    text = strip_table_header(text, 'Name');
elseif isempty(text) && ismac
    text = safe_system_text('sysctl -n machdep.cpu.brand_string');
elseif isempty(text) && isunix
    text = safe_system_text('cat /proc/cpuinfo');
    text = first_cpu_model_line(text);
end
if isempty(text)
    text = 'unknown';
end
end

function text = get_ram_description()
text = '';
try
    [~, sys] = memory;
    if isfield(sys, 'PhysicalMemory') && isfield(sys.PhysicalMemory, 'Total')
        text = sprintf('%.3f GB', sys.PhysicalMemory.Total / 1024^3);
    end
catch
end
if isempty(text)
    text = 'not_available';
end
end

function text = safe_eval_string(fn)
try
    text = fn();
catch
    text = 'not_available';
end
if isempty(text)
    text = 'not_available';
end
end

function text = safe_system_text(command_text)
text = '';
try
    [status, output] = system(command_text);
    if status == 0
        text = strtrim(output);
    end
catch
    text = '';
end
end

function text = strip_table_header(text, header)
lines = regexp(text, '\r\n|\n|\r', 'split');
lines = strtrim(lines);
lines = lines(~cellfun('isempty', lines));
if ~isempty(lines) && strcmpi(lines{1}, header)
    lines = lines(2:end);
end
if isempty(lines)
    text = '';
else
    text = lines{1};
end
end

function text = first_cpu_model_line(text)
lines = regexp(text, '\r\n|\n|\r', 'split');
for k = 1:numel(lines)
    line = strtrim(lines{k});
    if startsWith(line, 'model name')
        parts = regexp(line, ':', 'split');
        if numel(parts) >= 2
            text = strtrim(parts{2});
            return;
        end
    end
end
text = '';
end
