function row=review_run_one(cfg,outputRoot)
%REVIEW_RUN_ONE Fresh optimization, or exact config + numerical-source cache.
repoRoot=fileparts(fileparts(mfilename('fullpath')));
expected=fullfile(repoRoot,'src',[cfg.solver '.m']);
assert(strcmpi(which(cfg.solver),expected),'Wrong solver resolved: %s',which(cfg.solver));
runDir=fullfile(outputRoot,'runs',cfg.run_id);
manifest=review_source_manifest(repoRoot); numerical=manifest(startsWith(manifest.relative_path,"src/"),:);
numerical_sha=review_sha256(jsonencode(table2struct(numerical)));
config_sha=review_sha256(jsonencode(cfg));
file=fullfile(runDir,'result.mat');
if exist(file,'file')
    old=load(file,'provenance','summary_row');
    assert(strcmp(old.provenance.numerical_sha,numerical_sha)&&strcmp(old.provenance.config_sha,config_sha), ...
        'Existing result has different source/config. Use a new output directory: %s',runDir);
    row=old.summary_row; fprintf('Verified cached run %s\n',cfg.run_id); return
end
if ~exist(runDir,'dir'),mkdir(runDir);end
[cb,finish]=collect_iteration_diagnostics(cfg);
options=cfg.options; options.iteration_callback=cb;
provenance=struct('started',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss Z')), ...
    'matlab_version',version,'release',version('-release'),'computer',computer, ...
    'solver_path',which(cfg.solver),'numerical_sha',numerical_sha,'config_sha',config_sha, ...
    'source_manifest',manifest,'cfg',cfg);
fid=fopen(fullfile(runDir,'config.json'),'w'); fprintf(fid,'%s',jsonencode(cfg,PrettyPrint=true)); fclose(fid);
fprintf('\nRUN %s (%s)\n',cfg.run_id,cfg.changed_option); timer=tic;
result=feval(cfg.solver,cfg.nelx,cfg.nely,cfg.volfrac,cfg.er,options);
provenance.elapsed_seconds=toc(timer);
diagnostics=finish();
assert(numel(diagnostics.iteration)==result.iterations+1,'Incomplete callback history');
assert(isequal(diagnostics.final_mi_map,result.mi_map),'Final layout mismatch');
assert(diagnostics.compliance(end)==result.compliance,'Final response mismatch');
assert(all(abs(diagnostics.V1+diagnostics.V2-diagnostics.solid_fraction)<1e-14));
if isfield(cfg.options,'fixed_solid_mask')
    keep=cfg.options.fixed_solid_mask;
    assert(all(reshape(diagnostics.phase_history(repmat(keep,1,1,size(diagnostics.phase_history,3)))>0,[],1)),'Retained-solid violation');
end
names=fieldnames(diagnostics); scalars={};
for k=1:numel(names)
    v=diagnostics.(names{k});
    if isnumeric(v)&&iscolumn(v)&&numel(v)==numel(diagnostics.iteration),scalars{end+1}=names{k};end %#ok<AGROW>
end
T=table();for k=1:numel(scalars),T.(scalars{k})=diagnostics.(scalars{k});end
review_write_table(T,fullfile(runDir,'iteration_history.csv'));
save(fullfile(runDir,'diagnostics.mat'),'diagnostics','-v7.3');
solid=result.x>cfg.options.xmin; vm=result.response.sigvm;
row=struct('run_id',string(cfg.run_id),'case_id',string(cfg.case_id),'group',string(cfg.group), ...
    'changed_option',string(cfg.changed_option),'iterations',result.iterations, ...
    'convergence_iteration',NaN,'termination_reason',string(result.termination_reason), ...
    'converged',logical(result.converged),'compliance_Nmm',result.compliance, ...
    'solid_fraction',nnz(solid)/numel(solid),'V1',nnz(solid & result.mi_map==1)/numel(solid), ...
    'V2',nnz(solid & result.mi_map==2)/numel(solid),'max_vm_MPa',max(vm(solid)), ...
    'topology_difference',NaN,'material_difference',NaN,'compliance_change_percent',NaN, ...
    'max_vm_change_percent',NaN,'archived_compliance_error_percent',100*(result.compliance/cfg.archived_compliance_Nmm-1), ...
    'reference_compliance_error_percent',100*(result.compliance/cfg.reference_compliance_Nmm-1), ...
    'reference_stress_error_percent',100*(max(vm(solid))/cfg.reference_max_vm_MPa-1), ...
    'last_N_SV',diagnostics.N_SV(end),'last_N_TC',diagnostics.N_TC(end), ...
    'max_last10_N_TC',max(diagnostics.N_TC(max(2,end-9):end)), ...
    'elapsed_seconds',provenance.elapsed_seconds);
if isfield(result,'convergence_iteration'),row.convergence_iteration=result.convergence_iteration;
elseif isfield(result.settings,'convergence_iteration'),row.convergence_iteration=result.settings.convergence_iteration;end
baselineFile=fullfile(outputRoot,'runs',cfg.case_id,'result.mat');
if strcmp(cfg.group,'baseline')
    row.topology_difference=0;row.material_difference=0;row.compliance_change_percent=0;row.max_vm_change_percent=0;
elseif exist(baselineFile,'file')
    base=load(baselineFile,'result'); bs=base.result.x>cfg.options.xmin;
    row.compliance_change_percent=100*(result.compliance/base.result.compliance-1);
    row.max_vm_change_percent=100*(max(vm(solid))/max(base.result.response.sigvm(bs))-1);
    if isequal(size(bs),size(solid))
        row.topology_difference=nnz(bs~=solid)/numel(solid);
        common=bs&solid; row.material_difference=nnz(common & base.result.mi_map~=result.mi_map)/max(1,nnz(common));
    end
end
summary_row=row;
save(file,'result','cfg','provenance','summary_row','-v7.3');
review_write_table(struct2table(row),fullfile(runDir,'summary.csv'));
review_write_table(table((1:numel(solid))',double(result.mi_map(:)),result.x(:),vm(:), ...
    'VariableNames',{'element_linear_index','material_id','density_variable','center_vm_MPa'}), ...
    fullfile(runDir,'final_elements.csv'));
fprintf('DONE %s: %d iterations; %s; C=%.12g N mm; VM=%.9g MPa; TC=%d\n', ...
    cfg.run_id,result.iterations,result.termination_reason,result.compliance,max(vm(solid)),diagnostics.N_TC(end));
end
