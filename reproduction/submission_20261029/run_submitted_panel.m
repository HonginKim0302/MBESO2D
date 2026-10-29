function fig=run_submitted_panel(panel,showWindows)
%RUN_SUBMITTED_PANEL Reproduce and export one panel without closing other figures.
if nargin<2,showWindows=true;end
here=fileparts(mfilename('fullpath'));D=submitted_plot_data();
fig=render_submitted_panel(panel,D,showWindows);
export_submitted_panel(fig,fullfile(here,'outputs'));
end
