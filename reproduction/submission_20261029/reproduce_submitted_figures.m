function manifest = reproduce_submitted_figures(showWindows,dataOverride)
%REPRODUCE_SUBMITTED_FIGURES Reproduce the submitted numerical panels and zooms.
% Optional dataOverride is a complete D structure using submitted_plot_data's
% field names; a fresh-history adapter can supply it without archived assertions.
if nargin<1,showWindows=false;end
if nargin<2,D=submitted_plot_data();else,D=dataOverride;end
here=fileparts(mfilename('fullpath'));
write_submitted_inputs(D,fullfile(here,'generated_inputs'));
ids=submitted_panel_ids();rows=cell(0,6);
for k=1:numel(ids)
    fig=render_submitted_panel(ids{k},D,showWindows);
    rows=[rows;export_submitted_panel(fig,fullfile(here,'outputs'))]; %#ok<AGROW>
    if ~showWindows,close(fig);end
end
manifest=cell2table(rows,'VariableNames',{'panel','format','path','width_px','height_px','source_mode'});
writetable(manifest,fullfile(here,'generated_artifacts.csv'));
end
