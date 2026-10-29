function manifest=reproduce_submitted_assignment(showWindows,dataOverride)
%REPRODUCE_SUBMITTED_ASSIGNMENT Export the optional native Fig.6(b) reconstruction.
if nargin<1,showWindows=false;end
if nargin<2,D=submitted_plot_data();else,D=dataOverride;end
here=fileparts(mfilename('fullpath'));
fig=render_submitted_assignment(D,showWindows);
rows=export_submitted_panel(fig,fullfile(here,'outputs'));
manifest=cell2table(rows,'VariableNames',{'panel','format','path','width_px','height_px','source_mode'});
writetable(manifest,fullfile(here,'assignment_artifacts.csv'));
folder=fullfile(here,'generated_inputs');if ~exist(folder,'dir'),mkdir(folder);end
writematrix(double(D.materialState10),fullfile(folder,'Fig06_b_material_state10.csv'));
writetable(array2table([D.local_update D.assignments'], ...
    'VariableNames',{'update','element974_phase','element5829_phase'}),fullfile(folder,'Fig06_b_assignments.csv'));
if ~showWindows,close(fig);end
end
