function manifest=reproduce_manuscript_figures(showWindows,panels)
%REPRODUCE_MANUSCRIPT_FIGURES Export the numerical panels of Figures 6 and 7.
% showWindows=true leaves editable MATLAB figures open. No FE solve is run.
if nargin<1,showWindows=false;end
here=fileparts(mfilename('fullpath'));old=path;cleanup=onCleanup(@()path(old)); %#ok<NASGU>
addpath(fullfile(here,'common'),'-begin');
if nargin<2,panels=figure_panel_ids;end
if ischar(panels)||isstring(panels),panels=cellstr(panels);end
assert(all(ismember(panels,[figure_panel_ids {'Fig06_b'}])),'Unknown manuscript panel.');
D=read_figure_data;output=fullfile(here,'outputs');
write_figure_inputs(D,fullfile(output,'data'));rows=cell(0,6);
for k=1:numel(panels)
    if strcmp(panels{k},'Fig06_b'),fig=render_material_assignment(D,showWindows);
    else,fig=render_figure_panel(panels{k},D,showWindows);end
    rows=[rows;export_figure_panel(fig,output)]; %#ok<AGROW>
    if ~showWindows,close(fig);end
end
manifest=cell2table(rows,'VariableNames',{'panel','format','path','width_px','height_px','source_mode'});
writetable(manifest,fullfile(output,'figure_manifest.csv'));
end
