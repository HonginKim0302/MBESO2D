function F6=prepare_figure_06_data(sourceRoot,outputDir)
%PREPARE_FIGURE_06_DATA Extract actual baseline responses and element decisions.
initialFile=fullfile(sourceRoot,'initial10','cantilever','full_history.mat');
historyFile=fullfile(sourceRoot,'zero_history','cantilever_eps_0','full_history.mat');
A=load(initialFile,'data');a=A.data;B=load(historyFile,'data');b=B.data;
assert(b.cfg.nelx==100 && b.cfg.nely==60 && b.n_updates>=214 && b.first_stop==214);
assert(isequal(a.phase(:,1:11),b.phase(:,1:11)));
fields={'trace_raw','trace_filtered','eta_raw','eta_spatial','eta_history','vm_center','sig1','sig2'};
for k=1:numel(fields)
    field=fields{k};assert(isequaln(a.(field)(:,1:10),b.(field)(:,1:10)), ...
        'Initial-history prefix differs: %s',field);
end
assert(isequal(a.C(1:11),b.C(1:11)));
assert(isequal(b.eta_history(:,1),b.eta_spatial(:,1)));
assert(max(abs(b.eta_history(:,2:10)-.5*(b.eta_spatial(:,1:9)+b.eta_spatial(:,2:10))),[],'all')==0);
assert(isnan(b.cutoff(1)),'The initialization cutoff must remain undefined.');
F6=struct('response_state',(0:214)','C_Nmm',reshape(b.C(1:215),[],1), ...
    'normalization_coefficient',reshape(b.nk(1:215),[],1),'decision_update',(1:10)', ...
    'element_ids',[974 5829], ...
    'unfiltered_indicator_MPa',reshape(b.trace_raw(974,1:10),[],1), ...
    'filtered_indicator_MPa',reshape(b.trace_filtered(974,1:10),[],1), ...
    'history_score',double(b.eta_history([974 5829],1:10))', ...
    'retention_threshold',reshape(b.cutoff(2:11),[],1), ...
    'material_assignment',uint8(b.phase([974 5829],2:11)), ...
    'material_state10',reshape(uint8(b.phase(:,11)),60,100),'mesh_size',[60 100]);
if ~isfolder(outputDir),mkdir(outputDir);end
save(fullfile(outputDir,'figure_data.mat'),'F6','-v7');
paths={'initial10/cantilever/full_history.mat';'zero_history/cantilever_eps_0/full_history.mat'};
hashes={file_sha256(initialFile);file_sha256(historyFile)};
writetable(table(paths,hashes,'VariableNames',{'source_relative_path','sha256'}),fullfile(outputDir,'source_manifest.csv'));
end
