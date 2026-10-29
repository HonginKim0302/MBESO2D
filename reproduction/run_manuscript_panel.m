function fig=run_manuscript_panel(panel,showWindows)
%RUN_MANUSCRIPT_PANEL Open and export one editable figure without closing others.
if nargin<2,showWindows=true;end
here=fileparts(mfilename('fullpath'));old=path;cleanup=onCleanup(@()path(old)); %#ok<NASGU>
addpath(fullfile(here,'common'),'-begin');D=read_figure_data;
if strcmp(panel,'Fig06_b'),fig=render_material_assignment(D,showWindows);
else,fig=render_figure_panel(panel,D,showWindows);end
export_figure_panel(fig,fullfile(here,'outputs'));
write_figure_inputs(D,fullfile(here,'outputs','data'));
end
