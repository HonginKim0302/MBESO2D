% SPDX-License-Identifier: GPL-3.0-or-later
% Copyright (C) 2026 MBESO2D contributors
function fig = mbeso_plot_beso_evolution(result)
%MBESO_PLOT_BESO_EVOLUTION Plot BESO evolution history in the original fig.4 style.
%
%   fig = mbeso_plot_beso_evolution(result)
%
% The input result is the structure returned by mbeso.

history = result.history;
Vk_hist = history.Vk_hist(:).';
nk_hist = history.nk_hist(:).';
V1_hist = history.V1_hist(:).';
compliance_hist = history.compliance_hist(:).';
iterations = 1:numel(Vk_hist);

if isfield(history, 'initial_beso_state') && ~isempty(history.initial_beso_state)
    initial_state = history.initial_beso_state;
    iterations = 0:numel(Vk_hist);
    Vk_hist = [initial_state.Vk, Vk_hist];
    nk_hist = [initial_state.nk, nk_hist];
    V1_hist = [initial_state.V1, V1_hist];
    compliance_hist = [initial_state.compliance, compliance_hist];
end

fig = figure(4);
clf(fig);
set(fig, 'Color', 'w', 'Name', 'MBESO BESO evolution', 'NumberTitle', 'off');
set(fig, 'DefaultAxesFontName', 'Times New Roman', 'DefaultTextFontName', 'Times New Roman');

ax = axes('Parent', fig);
yyaxis(ax, 'left');
hold(ax, 'on');
p1 = plot(ax, iterations, Vk_hist, '-ok', ...
    'MarkerFaceColor', 'w', 'MarkerSize', 6, 'LineWidth', 1, 'DisplayName', 'V_k');
p2 = plot(ax, iterations, nk_hist, '-sk', ...
    'MarkerFaceColor', 'w', 'MarkerSize', 6, 'LineWidth', 1, 'DisplayName', 'n_k');
p3 = plot(ax, iterations, V1_hist, '-dk', ...
    'MarkerFaceColor', 'w', 'MarkerSize', 6, 'LineWidth', 1, 'DisplayName', 'V_1');
ylabel(ax, 'V_k / n_k / V_1', 'FontName', 'Times New Roman');
set(ax, 'YColor', 'k');

yyaxis(ax, 'right');
p4 = plot(ax, iterations, compliance_hist, '-hb', ...
    'MarkerFaceColor', 'w', 'MarkerSize', 6, 'LineWidth', 1, 'DisplayName', 'Compliance');
ylabel(ax, 'Compliance', 'FontName', 'Times New Roman');
set(ax, 'YColor', 'b');

xlabel(ax, 'iterations', 'FontName', 'Times New Roman');
set(ax, 'FontName', 'Times New Roman', 'FontSize', 12, 'LineWidth', 1.2, 'Box', 'on');
grid(ax, 'off');
legend(ax, [p1, p2, p3, p4], {'V_k', 'n_k', 'V_1', 'Compliance'}, ...
    'Location', 'southeast', ...
    'EdgeColor', 'k', ...
    'FontName', 'Times New Roman', ...
    'FontSize', 11);
drawnow;
end
