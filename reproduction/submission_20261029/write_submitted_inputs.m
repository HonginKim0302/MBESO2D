function write_submitted_inputs(D,folder)
%WRITE_SUBMITTED_INPUTS Save the actual numerical inputs used in this run.
if ~exist(folder,'dir'),mkdir(folder);end
writetable(table(D.state,D.C,D.nk,'VariableNames',{'state','C_Nmm','nk'}),fullfile(folder,'Fig06_a.csv'));
writetable(table(D.local_update,D.rawStress,D.filteredStress, ...
    'VariableNames',{'decision_update','unfiltered_MPa','filtered_MPa'}),fullfile(folder,'Fig06_c.csv'));
writetable(table(D.local_update,D.score974,D.score5829,D.threshold, ...
    'VariableNames',{'decision_update','score974','score5829','threshold'}),fullfile(folder,'Fig06_d.csv'));
writetable(table(D.update,D.solid,D.tensile,D.compressive, ...
    'VariableNames',{'state','solid_percent','tensile_percent','compressive_percent'}),fullfile(folder,'Fig07_a.csv'));
writetable(table(D.update,D.transitionsSV,D.transitionsTC, ...
    'VariableNames',{'update','N_SV','N_TC'}),fullfile(folder,'Fig07_b.csv'));
T=array2table([D.state D.deadband],'VariableNames',{'state','epsilon_0','epsilon_0p005','epsilon_0p05','epsilon_0p5','epsilon_5'});
writetable(T,fullfile(folder,'Fig07_c.csv'));
writetable(array2table([D.epsilon_MPa D.countsSVTC],'VariableNames',{'epsilon_MPa','N_SV','N_TC'}),fullfile(folder,'Fig07_d.csv'));
writetable(array2table([D.epsilon_MPa D.layoutSVTC],'VariableNames',{'epsilon_MPa','solid_void_percent','tensile_compressive_percent'}),fullfile(folder,'Fig07_e.csv'));
save(fullfile(folder,'plotted_data.mat'),'D');
end
