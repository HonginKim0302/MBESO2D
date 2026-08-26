% SPDX-License-Identifier: GPL-3.0-or-later
% Copyright (C) 2026 MBESO2D contributors
function fig = mbeso_plot_history(result)
%MBESO_PLOT_HISTORY Plot volume, material ratio, compliance, and change.
%
%   fig = mbeso_plot_history(result)
%
% The input result is the structure returned by mbeso.

history = result.history;
iters = (1:numel(history.compliance_hist)).';

fig = figure('Color', 'w', 'Name', 'MBESO convergence history', 'NumberTitle', 'off');
set_figure_font(fig);
tiledlayout(fig, 2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

ax1 = nexttile;
plot(ax1, iters, history.Vk_hist, '-ok', 'LineWidth', 1.2, 'MarkerSize', 4);
grid(ax1, 'on');
xlabel(ax1, 'Iteration', 'FontName', 'Times New Roman');
ylabel(ax1, 'Volume ratio', 'FontName', 'Times New Roman');
title(ax1, 'Solid volume', 'FontName', 'Times New Roman', 'FontWeight', 'normal');

ax2 = nexttile;
plot(ax2, iters, history.V1_hist, '-ob', 'LineWidth', 1.2, 'MarkerSize', 4);
grid(ax2, 'on');
xlabel(ax2, 'Iteration', 'FontName', 'Times New Roman');
ylabel(ax2, 'Material 1 ratio', 'FontName', 'Times New Roman');
title(ax2, 'Tension material ratio', 'FontName', 'Times New Roman', 'FontWeight', 'normal');

ax3 = nexttile;
plot(ax3, iters, history.compliance_hist, '-or', 'LineWidth', 1.2, 'MarkerSize', 4);
grid(ax3, 'on');
xlabel(ax3, 'Iteration', 'FontName', 'Times New Roman');
ylabel(ax3, 'Compliance', 'FontName', 'Times New Roman');
title(ax3, 'Compliance', 'FontName', 'Times New Roman', 'FontWeight', 'normal');

ax4 = nexttile;
semilogy(ax4, iters, history.change_hist, '-om', 'LineWidth', 1.2, 'MarkerSize', 4);
grid(ax4, 'on');
xlabel(ax4, 'Iteration', 'FontName', 'Times New Roman');
ylabel(ax4, 'Relative change', 'FontName', 'Times New Roman');
title(ax4, 'Convergence', 'FontName', 'Times New Roman', 'FontWeight', 'normal');
set([ax1 ax2 ax3 ax4], 'FontName', 'Times New Roman', 'FontSize', 11);
end

function set_figure_font(fig)
set(fig, 'DefaultAxesFontName', 'Times New Roman', 'DefaultTextFontName', 'Times New Roman');
end
