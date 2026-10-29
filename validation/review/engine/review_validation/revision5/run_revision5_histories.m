function package=run_revision5_histories(outputRoot,mode)
% Fresh deadband paths and all-element initial-ten observations.
% manuscript_histories: common states 0--214 plus each own first termination.
% histories: optional historical common-264 and stop-plus-50 investigation.
% No production solver file or numerical update rule is modified.
here=fileparts(mfilename('fullpath'));rv=fileparts(here);repo=fileparts(rv);
addpath(here,rv,fullfile(rv,'revision3'),fullfile(repo,'src'));
if nargin<2,mode='manuscript_histories';end
mode=validatestring(mode,{'manuscript_histories','histories','initial10'});
commonHorizon=214;extraUpdates=0;
if strcmp(mode,'histories'),commonHorizon=264;extraUpdates=50;end
if nargin<1,outputRoot=fullfile(repo,'results','review_revision5_20261012');end
zeroRoot=fullfile(outputRoot,'zero_history');initialRoot=fullfile(outputRoot,'initial10');
if ~isfolder(zeroRoot),mkdir(zeroRoot);end
if ~isfolder(initialRoot),mkdir(initialRoot);end
assert(~isfile(fullfile(zeroRoot,'case_summary.csv')),'Use a fresh output folder.');
spec={'cantilever_eps_0',0;'cantilever_eps_0p005',.005;'cantilever_eps_0p05',.05;'cantilever_eps_0p5',.5;'cantilever_eps_5',5};
if strcmp(mode,'initial10'),spec=cell(0,2);end
caseRows={};pilotRows={};base=[];baselineRepresentative=[];
for q=1:size(spec,1)
    cfg=review_case_config('cantilever');cfg.run_id=spec{q,1};cfg.options.material_zero_tolerance=spec{q,2};
    cfg.options.plotting=false;cfg.options.verbose=false;cfg.options.max_iterations=1000;
    cfg.options.continue_after_convergence=0;cfg.options.force_iteration_limit=false;
    cfg.options.iteration_callback=[];cfg.options.update_snapshot_callback=[];
    assert(strcmpi(which(cfg.solver),fullfile(repo,'src',[cfg.solver '.m'])),'Wrong solver.');
    fprintf('REV5 PILOT %s epsilon %.9g\n',cfg.run_id,spec{q,2});t=tic;
    pilot=feval(cfg.solver,cfg.nelx,cfg.nely,cfg.volfrac,cfg.er,cfg.options);pilotTime=toc(t);
    first=pilot.convergence_iteration;
    if isfinite(first)
        cfg.options.continue_after_convergence=max(extraUpdates,commonHorizon-first);
        cfg.options.max_iterations=max(1000,first+extraUpdates);
    else
        cfg.options.max_iterations=1000;
    end
    caseDir=fullfile(zeroRoot,cfg.run_id);mkdir(caseDir);
    [data,result,snapshots,replays]=observe(cfg,caseDir);
    prefix=pilot.iterations;
    checks={ 'observer_first_stop',double(~isequaln(result.convergence_iteration,first)),0; ...
        'observer_prefix_C',max(abs(result.history.compliance_hist(1:prefix)-pilot.history.compliance_hist)),0; ...
        'observer_prefix_phase',nnz(double(data.phase(:,prefix+1))~=pilot.mi_map(:)),0; ...
        'observer_prefix_center_VM',max(abs(data.state_vm(:,prefix+1)-pilot.response.sigvm(:))),0};
    expected=1000;if isfinite(first),expected=max(commonHorizon,first+extraUpdates);end
    checks(end+1,:)={'planned_horizon',abs(data.n_updates-expected),0};
    checks(end+1,:)={'same_state_VM',max(abs(data.vm_center(:)-reshape(data.state_vm(:,1:data.n_updates),[],1))),0};
    checks(end+1,:)={'same_state_trace',max(abs(data.trace_raw(:)-reshape(data.state_trace(:,1:data.n_updates),[],1))),0};
    checks(end+1,:)={'all_independent_update_checks',nnz(~replays.passed),0};
    % Portable export omits comparisons against unpublished local archive files.
    % Observer/pilot identity and independent update replay above remain mandatory.
    T=cell2table(checks,'VariableNames',{'check','error','tolerance'});T.passed=T.error<=T.tolerance;
    review_write_table(T,fullfile(caseDir,'observer_checks.csv'));assert(all(T.passed),'Observer prefix changed.');
    data.first_stop=first;data.pilot_runtime_seconds=pilotTime;data.solver_runtime_seconds=result.settings.run_time_seconds;
    save(fullfile(caseDir,'full_history.mat'),'data','-v7.3');
    save(fullfile(caseDir,'result.mat'),'result','cfg','-v7.3');
    save(fullfile(caseDir,'initial10_snapshots.mat'),'snapshots','-v7.3');
    if q==1,base=struct('phase',data.phase(:,1:commonHorizon+1),'C',data.C(1:commonHorizon+1));end
    [summary,representative]=analyze_history(data,caseDir,base,baselineRepresentative,commonHorizon,extraUpdates);
    if q==1,baselineRepresentative=representative;end
    caseRows{end+1,1}=summary;
    pilotRows{end+1,1}=struct('run_id',string(cfg.run_id),'epsilon_MPa',spec{q,2},'pilot_updates',pilot.iterations,'pilot_first_stop',first, ...
        'pilot_seconds',pilotTime,'observer_updates',result.iterations,'observer_seconds',result.settings.run_time_seconds,'observer_passed',all(T.passed));
    fprintf('REV5 DONE %s first %.0f final %d\n',cfg.run_id,first,data.n_updates);
    clear data result snapshots pilot;
end
cases=table();
if ~isempty(caseRows)
    cases=struct2table(vertcat(caseRows{:}));review_write_table(cases,fullfile(zeroRoot,'case_summary.csv'));
    review_write_table(struct2table(vertcat(pilotRows{:})),fullfile(zeroRoot,'execution_manifest.csv'));
    parts={};for q=1:size(spec,1),parts{q}=readtable(fullfile(zeroRoot,spec{q,1},'comparison_stages.csv'),'TextType','string');end
    review_write_table(vertcat(parts{:}),fullfile(zeroRoot,'matched_horizon_comparison.csv'));
end
initialRows={};
for id={'cantilever','bridge_3a','bridge_3b'}
    cfg=review_case_config(id{1});cfg.options.max_iterations=10;cfg.options.force_iteration_limit=true;
    cfg.options.continue_after_convergence=0;cfg.options.verbose=false;cfg.options.plotting=false;
    caseDir=fullfile(initialRoot,id{1});mkdir(caseDir);
    [data,result,snapshots,replays]=observe(cfg,caseDir);
    % The development-only archive comparison is not rerun in this portable package.
    mismatch=NaN;cError=NaN;
    save(fullfile(caseDir,'full_history.mat'),'data','-v7.3');save(fullfile(caseDir,'snapshots.mat'),'snapshots','-v7.3');
    initial=initial_tables(data,snapshots,caseDir);
    initial.phase_prefix_mismatches=mismatch;initial.C_prefix_max_absolute_error_Nmm=cError;
    initial.independent_updates=height(replays);initial.independent_updates_passed=nnz(replays.passed);
    initialRows{end+1,1}=initial;
    fprintf('INITIAL10 DONE %s\n',id{1});
end
initial=struct2table(vertcat(initialRows{:}));review_write_table(initial,fullfile(initialRoot,'initial10_summary.csv'));
package=struct('completed',true,'production_solver_changed',false,'case_summary',cases,'initial10',initial, ...
    'common_horizon',commonHorizon,'additional_updates_after_own_termination',extraUpdates,'mode',mode);
save(fullfile(outputRoot,'history_package.mat'),'package');
observed=0;if ~isempty(cases),observed=sum(cases.final_update);end
write_json(struct('completed',true,'archived_prefix_check','not_run_local_archives_not_bundled','new_deadband_paths',height(cases),'observed_updates',observed, ...
    'common_horizon',commonHorizon,'additional_updates_after_own_termination',extraUpdates,'mode',mode, ...
    'all_observer_checks_passed',true,'initial10_cases',3,'initial10_updates',30,'scope','Independent update replay shares the production FE input; no source-author identity or global convergence claim.'),fullfile(zeroRoot,'status.json'));
end

function [d,result,snapshots,replays]=observe(cfg,caseDir)
ne=cfg.nelx*cfg.nely;cap=cfg.options.max_iterations;n=0;prototype=[];rows={};snapshots=cell(10,1);
updateFields={'trace_raw','trace_filtered','vm_center','sig1','sig2','eta_raw','eta_spatial','eta_history'};d=struct();
for z=1:numel(updateFields),d.(updateFields{z})=zeros(ne,cap);end
for key={'state_vm','state_trace','state_material_utilization_percent'},d.(key{1})=nan(ne,cap+1);end
d.phase=zeros(ne,cap+1,'uint8');
scalar={'C','scheduled_volume','solid_fraction','V1','V2','nk','change','cutoff','target_keep','effective_keep','rank_margin','exact_cutoff_ties'};
for z=1:numel(scalar),d.(scalar{z})=nan(cap+1,1);end
o=cfg.options;o.diagnostic_fields=true;o.update_snapshot_callback=@onUpdate;o.iteration_callback=@onState;
result=feval(cfg.solver,cfg.nelx,cfg.nely,cfg.volfrac,cfg.er,o);
for z=1:numel(updateFields),d.(updateFields{z})=d.(updateFields{z})(:,1:n);end
for key={'phase','state_vm','state_trace','state_material_utilization_percent'},d.(key{1})=d.(key{1})(:,1:n+1);end
for z=1:numel(scalar),d.(scalar{z})=d.(scalar{z})(1:n+1);end
d.cfg=cfg;d.prototype_inputs=prototype;d.run_id=cfg.run_id;d.n_updates=n;d.first_stop=result.convergence_iteration;
d.termination_reason=result.termination_reason;d.stress_bands_MPa=[5e-7 5e-5 .005];
d.material_utilization_definition='Nonnegative 100*center_VM / actually assigned material strength (M1=250 MPa,M2=50 MPa); undefined for void. No n_k or raw-trace branch.';
d.update_index_definition='update k consumes FE state k-1 and yields phase/state k';
d.source_environment=struct('matlab',version,'computer',computer);
replays=struct2table(vertcat(rows{:}));review_write_table(replays,fullfile(caseDir,'update_replay_checks.csv'));
assert(all(replays.passed),'Independent replay has mismatches.');
    function onUpdate(s)
        k=s.iteration;n=k;a=s.inputs;p=s.production;
        if isempty(prototype)
            prototype=a;vary={'x','mi_map','U','sig1','sig2','sigma_raw','center_vm','utilization_vm','previous_eta_spatial','previous_nk','previous_volume','previous_keep_mask'};
            prototype=rmfield(prototype,vary);d.state_vm(:,1)=a.center_vm(:);d.state_trace(:,1)=a.sigma_raw(:);
            d.state_material_utilization_percent(:,1)=material_u(a.center_vm,a.mi_map,a.materials);
        end
        d.trace_raw(:,k)=a.sigma_raw(:);d.vm_center(:,k)=a.center_vm(:);d.sig1(:,k)=a.sig1(:);d.sig2(:,k)=a.sig2(:);
        d.trace_filtered(:,k)=p.sigma_filtered(:);d.eta_raw(:,k)=p.eta_raw(:);d.eta_spatial(:,k)=p.eta_spatial(:);d.eta_history(:,k)=p.eta_history(:);
        predicted=review_independent_update(rmfield(s,'production'));rows{end+1,1}=update_replay_compare(s,predicted,cfg.run_id);
        d.rank_margin(k+1)=predicted.rank_margin;d.exact_cutoff_ties(k+1)=predicted.exact_cutoff_ties;
        if k<=10,snapshots{k}=s;end
    end
    function onState(s)
        j=s.iteration+1;d.phase(:,j)=uint8(s.mi_map(:));d.C(j)=s.compliance;d.scheduled_volume(j)=s.Vk;
        d.solid_fraction(j)=s.solid_fraction;d.V1(j)=s.V1;d.V2(j)=s.solid_fraction-s.V1;d.nk(j)=s.nk;
        d.change(j)=s.change;d.cutoff(j)=s.cutoff;d.target_keep(j)=s.target_keep;d.effective_keep(j)=s.effective_keep;
        if s.iteration>0,d.state_vm(:,j)=s.post_sigvm_center(:);d.state_trace(:,j)=s.post_sigma_raw(:);d.state_material_utilization_percent(:,j)=material_u(s.post_sigvm_center,s.mi_map,cfg.options.materials);end
    end
end

function [summary,rep]=analyze_history(d,folder,baseline,baselineRep,commonHorizon,extraUpdates)
n=d.n_updates;ne=size(d.phase,1);first=d.first_stop;epsValue=d.cfg.options.material_zero_tolerance;
before=d.phase(:,1:n);after=d.phase(:,2:n+1);sv=(before>0)~=(after>0);persistentSolid=before>0&after>0;tc=persistentSolid&before~=after;
band=after>0&abs(d.trace_filtered)<=epsValue&epsValue>0;
noBand=uint8(2*ones(ne,n));noBand(d.trace_filtered>=0)=1;noBand(after==0)=0;
hold=band&persistentSolid&noBand~=before;revivedBand=band&before==0;
expected=noBand;expected(band&persistentSolid)=before(band&persistentSolid);expected(revivedBand)=1;
assert(isequal(expected,after),'Material-band reconstruction mismatch.');
last20=max(1,n-19):n;stationary=all(all(after(:,last20)==before(:,last20)));
period2=false;if n>=21,period2=all(all(d.phase(:,end-19:end)==d.phase(:,end-21:end-2)))&&~stationary;end
maxvm=nan(n+1,1);u1=maxvm;u2=maxvm;
for j=1:n+1
    p=d.phase(:,j);maxvm(j)=max(d.state_vm(p>0,j));u1(j)=max_or_nan(d.state_material_utilization_percent(p==1,j));u2(j)=max_or_nan(d.state_material_utilization_percent(p==2,j));
end
T=table(repmat(string(d.run_id),n,1),(1:n)',(0:n-1)',(1:n)',d.C(2:end),d.scheduled_volume(2:end),d.solid_fraction(2:end),d.V1(2:end),d.V2(2:end), ...
    sum(sv,1)',sum(tc,1)',sum(tc&before==1,1)',sum(tc&before==2,1)',sum(band,1)',sum(hold,1)',sum(revivedBand,1)',sum(persistentSolid,1)', ...
    maxvm(2:end),u1(2:end),u2(2:end),d.cutoff(2:end),d.target_keep(2:end),d.effective_keep(2:end),d.change(2:end), ...
    'VariableNames',{'run_id','update','input_state','output_state','C_Nmm','scheduled_volume','solid_fraction','M1_fraction','M2_fraction', ...
    'N_SV','N_TC','N_TtoC','N_CtoT','active_band_count','deadband_hold_count','restored_in_band_count','persistent_solid_count', ...
    'max_vm_MPa','M1_util_max_percent','M2_util_max_percent','cutoff','target_keep','effective_keep','relative_C_change'});
if extraUpdates>0
    T.is_stop_plus50_window=false(n,1);
    if isfinite(first),T.is_stop_plus50_window(first+1:first+extraUpdates)=true;end
end
review_write_table(T,fullfile(folder,'iteration_history.csv'));
stateT=table(repmat(string(d.run_id),n+1,1),(0:n)',d.C,d.scheduled_volume,d.solid_fraction,d.V1,d.V2,d.nk,d.change,[0;sum(sv,1)'],[0;sum(tc,1)'],maxvm,u1,u2, ...
    'VariableNames',{'run_id','state','C_Nmm','scheduled_volume','solid_fraction','M1_fraction','M2_fraction','nk','relative_C_change','N_SV','N_TC','max_vm_MPa','M1_util_max_percent','M2_util_max_percent'});
review_write_table(stateT,fullfile(folder,'state_history.csv'));
[~,rep]=max(sum(tc(:,2:commonHorizon),2));repIDs=rep;
rules="own most TC in common updates2:"+string(commonHorizon)+"; lowest ID tie";
if ~isempty(baselineRep),repIDs(end+1)=baselineRep;rules(end+1)="baseline most TC, same fixed element across conditions";end
repIDs(end+1)=ne;rules(end+1)="load-adjacent corner element";
export_trajectories(d,unique(repIDs,'stable'),repIDs,rules,folder);
parts={};stages={sprintf('common%d',commonHorizon),commonHorizon};
if isfinite(first)
    stages=[{'first_stop',first};stages];
    if extraUpdates>0,stages=[stages;{'stop_plus50',first+extraUpdates}];end
end
for j=1:size(stages,1)
    k=stages{j,2};p=d.phase(:,k+1);baseIndex=min(k,commonHorizon);bp=baseline.phase(:,baseIndex+1);
    topo=NaN;mat=NaN;deltaC=NaN;if k<=commonHorizon,common=p>0&bp>0;topo=nnz((p>0)~=(bp>0))/ne;mat=nnz(p(common)~=bp(common))/max(nnz(common),1);deltaC=100*(d.C(k+1)/baseline.C(k+1)-1);end
    parts{end+1,1}=struct('run_id',string(d.run_id),'epsilon_MPa',epsValue,'stage',string(stages{j,1}),'update',k,'first_stop',first, ...
        'C_Nmm',d.C(k+1),'max_vm_MPa',maxvm(k+1),'M1_util_max_percent',u1(k+1),'M2_util_max_percent',u2(k+1), ...
        'solid_fraction',d.solid_fraction(k+1),'M1_fraction',d.V1(k+1),'M2_fraction',d.V2(k+1), ...
        'C_change_vs_baseline_same_update_percent',deltaC,'topology_difference_same_update',topo,'material_difference_common_solids_same_update',mat, ...
        'TC_updates2_to_stage',nnz(tc(:,2:k)),'SV_updates2_to_stage',nnz(sv(:,2:k)), ...
        'TC_per_persistent_solid_opportunity',nnz(tc(:,2:k))/max(nnz(persistentSolid(:,2:k)),1),'actual_band_holds_updates2_to_stage',nnz(hold(:,2:k)));
end
review_write_table(struct2table(vertcat(parts{:})),fullfile(folder,'comparison_stages.csv'));
atStop=NaN;reason="max_iterations";
if isfinite(first)
    atStop=d.C(first+1);reason="first_termination_and_common_horizon_completed";
end
summary=struct('run_id',string(d.run_id),'epsilon_MPa',epsValue,'first_stop',first,'final_update',n,'stop_reason',reason, ...
    'C_at_first_stop_Nmm',atStop,'C_final_Nmm',d.C(end), ...
    'final_last20_stationary',stationary,'final_last20_nonstationary_period2',period2,'last_N_TC',nnz(tc(:,end)),'last_N_SV',nnz(sv(:,end)), ...
    'representative_element',rep,'independent_updates',n,'independent_updates_passed',n);
summary.(sprintf('C_at_%d_Nmm',commonHorizon))=d.C(commonHorizon+1);
summary.(sprintf('TC_common2_%d',commonHorizon))=nnz(tc(:,2:commonHorizon));
summary.(sprintf('SV_common2_%d',commonHorizon))=nnz(sv(:,2:commonHorizon));
summary.(sprintf('deadband_holds_common2_%d',commonHorizon))=nnz(hold(:,2:commonHorizon));
summary.(sprintf('active_band_visits_common2_%d',commonHorizon))=nnz(band(:,2:commonHorizon));
summary.(sprintf('persistent_opportunities_common2_%d',commonHorizon))=nnz(persistentSolid(:,2:commonHorizon));
if extraUpdates>0
    at50=NaN;change50=NaN;dev50=NaN;range50=NaN;tc50=NaN;sv50=NaN;
    if isfinite(first)
        at50=d.C(first+extraUpdates+1);change50=100*(at50/atStop-1);interval=d.C(first+2:first+extraUpdates+1);
        dev50=100*max(abs(interval-atStop))/abs(atStop);range50=100*(max(interval)-min(interval))/abs(atStop);
        tc50=nnz(tc(:,first+1:first+extraUpdates));sv50=nnz(sv(:,first+1:first+extraUpdates));
        summary.stop_reason="first_response_stop_plus50_and_common_horizon_completed";
    end
    summary.C_at_stop_plus50_Nmm=at50;summary.C_stop_plus50_change_percent=change50;
    summary.C_stop_plus50_max_deviation_percent=dev50;summary.C_stop_plus50_range_percent=range50;
    summary.TC_stop_plus50=tc50;summary.SV_stop_plus50=sv50;
    summary.TC_common_last20=nnz(tc(:,commonHorizon-19:commonHorizon));
    summary.SV_common_last20=nnz(sv(:,commonHorizon-19:commonHorizon));
end
end

function summary=initial_tables(d,snapshots,folder)
ne=size(d.phase,1);n=d.n_updates;before=d.phase(:,1:n);after=d.phase(:,2:n+1);tc=before>0&after>0&before~=after;
sv=(before>0)~=(after>0);counts=sum(tc(:,2:end),2);[~,busy]=max(counts);
margin=abs(d.eta_history-d.cutoff(2:end)');[~,ix]=min(margin(:));[boundary,~]=ind2sub(size(margin),ix);
stable=find(~any(tc|sv,2)&all(d.phase>0,2),1);if isempty(stable),stable=1;end
ids=unique([busy boundary stable],'stable');why=["most TC in updates2:10; lowest ID tie","nearest selection cutoff; earliest update then lowest ID tie","no transitions in updates1:10 and solid; lowest ID"];
export_trajectories(d,ids,[busy boundary stable],why,folder);
checks={};sigmaParts={};
for k=1:n
    a=snapshots{k}.inputs;ker=feval(d.cfg.solver,'review_kernels');
    ny=d.cfg.nely;nx=d.cfg.nelx;h=a.element_size_mm;
    nodes=reshape(1:(nx+1)*(ny+1),ny+1,nx+1);n1=reshape(nodes(1:end-1,1:end-1),[],1);n2=reshape(nodes(1:end-1,2:end),[],1);
    edof=[2*n1-1 2*n1 2*n2-1 2*n2 2*n2+1 2*n2+2 2*n1+1 2*n1+2];
    B=1/(2*h)*[-1 0 1 0 1 0 -1 0;0 -1 0 -1 0 1 0 1;-1 -1 -1 1 1 1 1 -1];
    strain=a.U(edof)*B';sigma=zeros(ne,3);m=a.materials;p=a.mi_map(:);xp=a.x(:).^d.cfg.options.penal;
    for phase=1:2
        if phase==1,mask=p==1;D=ker.D(m.E1,m.nu1);else,mask=p~=1;D=ker.D(m.E2,m.nu2);end
        sigma(mask,:)=(strain(mask,:)*D').*xp(mask);
    end
    tr=sigma(:,1)+sigma(:,2);v=sqrt(sigma(:,1).^2-sigma(:,1).*sigma(:,2)+sigma(:,2).^2+3*sigma(:,3).^2);
    avg=tr/2;rad=sqrt(((sigma(:,1)-sigma(:,2))/2).^2+sigma(:,3).^2);
    errors=[max(abs(tr-a.sigma_raw(:))),max(abs(v-a.center_vm(:))),max(abs(avg+rad-a.sig1(:))),max(abs(avg-rad-a.sig2(:)))];
    tol=1e-9+1e-12*max(abs([a.center_vm(:);a.sig1(:);a.sig2(:)]));
    checks(end+1,:)={string(d.run_id),k,errors(1),errors(2),errors(3),errors(4),tol,all(errors<=tol)};
    [rr,cc]=ind2sub([ny nx],(1:ne)');
    sigmaParts{k}=table(repmat(string(d.run_id),ne,1),repmat(k,ne,1),repmat(k-1,ne,1),(1:ne)',rr,cc,(cc-.5)*h,(rr-.5)*h, ...
        sigma(:,1),sigma(:,2),sigma(:,3),a.sig1(:),a.sig2(:),a.sigma_raw(:),a.center_vm(:), ...
        'VariableNames',{'case_id','update','driving_state','element','row','column','x_mm','y_mm','sigma_xx_MPa','sigma_yy_MPa','tau_xy_MPa','sig1_MPa','sig2_MPa','raw_trace_MPa','center_VM_MPa'});
end
checkT=cell2table(checks,'VariableNames',{'case_id','update','trace_max_abs_error_MPa','VM_max_abs_error_MPa','sig1_max_abs_error_MPa','sig2_max_abs_error_MPa','tolerance_MPa','passed'});
review_write_table(checkT,fullfile(folder,'initial_stage_checks.csv'));assert(all(checkT.passed),'Stress component reconstruction mismatch.');
review_write_table(vertcat(sigmaParts{:}),fullfile(folder,'all_elements_driving_stress.csv'));
keepT=table((1:n)',(0:n-1)',(1:n)',d.target_keep(2:end),d.effective_keep(2:end),sum(after>0,1)',d.cutoff(2:end),d.C(2:end),sum(sv,1)',sum(tc,1)', ...
    'VariableNames',{'update','input_state','output_state','target_keep','effective_keep','actual_keep','cutoff','C_Nmm','N_SV','N_TC'});
review_write_table(keepT,fullfile(folder,'keep_count_history.csv'));
% Actual neighbour contributions for one declared element and update2.
target=busy;k=2;[r,c]=ind2sub([d.cfg.nely d.cfg.nelx],target);a=snapshots{k}.inputs;rows={};
for f=1:2
    if f==1,rad=a.r1_elements;values=a.sigma_raw;name="stress_sum";expected=snapshots{k}.production.sigma_filtered(target);unit="MPa";
    else,rad=a.r2_elements;values=snapshots{k}.production.eta_raw;name="selection_score";expected=snapshots{k}.production.eta_spatial(target);unit="dimensionless";end
    [rr,cc]=ndgrid(1:d.cfg.nely,1:d.cfg.nelx);dist=hypot(rr-r,cc-c);w=max(0,rad-dist);den=sum(w(:));indices=find(w>0);calc=sum(w(:).*values(:))/den;
    assert(abs(calc-expected)<=1e-9+1e-12*abs(expected),'Neighbour sum mismatch.');
    for ii=indices'
        rows{end+1,1}=struct('case_id',string(d.run_id),'filter',name,'units',unit,'update',k,'driving_state',k-1,'target_element',target,'neighbour_element',ii, ...
            'target_x_mm',(c-.5)*a.element_size_mm,'target_y_mm',(r-.5)*a.element_size_mm,'neighbour_x_mm',(cc(ii)-.5)*a.element_size_mm,'neighbour_y_mm',(rr(ii)-.5)*a.element_size_mm, ...
            'distance_mm',dist(ii)*a.element_size_mm,'radius_mm',rad*a.element_size_mm,'weight_element_units',w(ii),'denominator',den,'normalized_weight',w(ii)/den, ...
            'raw_value',values(ii),'weighted_contribution',w(ii)*values(ii)/den,'independent_average',calc,'production_average',expected);
    end
end
review_write_table(struct2table(vertcat(rows{:})),fullfile(folder,'filter_neighbour_example.csv'));
summary=struct('case_id',string(d.run_id),'updates',n,'elements',ne,'early_TC_element',busy,'boundary_element',boundary,'stable_element',stable, ...
    'component_checks_passed',nnz(checkT.passed),'component_max_absolute_error_MPa',max(max(checkT{:,3:6})));
end

function export_trajectories(d,ids,ruleIDs,rules,folder)
n=d.n_updates;parts={};repRows={};
for id=ids
    [rr,cc]=ind2sub([d.cfg.nely d.cfg.nelx],id);h=d.prototype_inputs.element_size_mm;why=strjoin(rules(ruleIDs==id),'; ');
    repRows{end+1,1}=struct('run_id',string(d.run_id),'element',id,'row',rr,'column',cc,'x_mm',(cc-.5)*h,'y_mm',(rr-.5)*h,'selection_rule',why);
    T=table(repmat(string(d.run_id),n+1,1),repmat(why,n+1,1),(0:n)',repmat(id,n+1,1),double(d.phase(id,:))',d.state_vm(id,:)',d.state_trace(id,:)', ...
        [d.trace_raw(id,:)';NaN],[d.trace_filtered(id,:)';NaN],[d.eta_raw(id,:)';NaN],[d.eta_spatial(id,:)';NaN], ...
        [NaN;d.eta_spatial(id,1:n-1)';NaN],[d.eta_history(id,:)';NaN],[d.cutoff(2:end);NaN],d.C, ...
        'VariableNames',{'run_id','selection_rule','state','element','phase','state_center_VM_MPa','state_raw_trace_MPa','outgoing_raw_trace_MPa','outgoing_filtered_trace_MPa', ...
        'outgoing_eta_raw','outgoing_eta_spatial','previous_eta_spatial','outgoing_eta_history','outgoing_cutoff','C_Nmm'});
    parts{end+1}=T;
end
review_write_table(struct2table(vertcat(repRows{:})),fullfile(folder,'representative_elements.csv'));
review_write_table(vertcat(parts{:}),fullfile(folder,'representative_trajectories.csv'));
end
function u=material_u(vm,p,m)
u=nan(numel(vm),1);p=p(:);vm=vm(:);u(p==1)=100*vm(p==1)/m.sigma_m1;u(p==2)=100*vm(p==2)/m.sigma_m2;
end
function x=max_or_nan(v),if isempty(v),x=NaN;else,x=max(v);end,end
function write_json(x,file),f=fopen(file,'w','n','UTF-8');assert(f>=0);c=onCleanup(@()fclose(f));fprintf(f,'%s',jsonencode(x,'PrettyPrint',true));end
