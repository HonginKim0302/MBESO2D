function report = run_verification_experiments(mode, outputRoot)
%RUN_VERIFICATION_EXPERIMENTS Rerun the numerical verification experiments.
% Modes: smoke, regression, baselines, sensitivity, deadband_sweep,
% initial10, histories, bridge_energy, all.
% Histories use common states 0--214 and each condition's first termination.
% The instrumented engine is scoped to this call; public src remains separate.
% SPDX-License-Identifier: GPL-3.0-or-later
here = fileparts(mfilename('fullpath'));
repo = fileparts(fileparts(here));
engine = fullfile(here,'engine');
if nargin < 1, mode = 'smoke'; end
mode = validatestring(mode, {'smoke','regression','baselines','sensitivity','deadband_sweep', ...
    'initial10','histories','bridge_energy','all'});
if nargin < 2 || isempty(outputRoot)
    stamp = char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
    outputRoot = fullfile(repo,'results',['verification_' mode '_' stamp]);
end
outputRoot = char(java.io.File(char(outputRoot)).getCanonicalPath());
if ~isfolder(outputRoot), mkdir(outputRoot); end
oldPath = path; oldDirectory = pwd;
cleanup = onCleanup(@()restore_environment(oldPath,oldDirectory)); %#ok<NASGU>
% MATLAB's current folder takes precedence over its path; avoid accidentally
% resolving public src/ when this entry point was called from that directory.
cd(engine);
% Shared display palette lives in public src; instrumented solvers stay first.
addpath(fullfile(repo,'src'),'-end');
addpath(fullfile(engine,'src'),fullfile(engine,'common'),fullfile(engine,'histories'),'-begin');
clear mbeso mbeso_fixed_solid
assert(strcmpi(which('mbeso'),fullfile(engine,'src','mbeso.m')));
assert(strcmpi(which('mbeso_fixed_solid'),fullfile(engine,'src','mbeso_fixed_solid.m')));
report = struct('mode',mode,'output_root',outputRoot,'matlab_version',version, ...
    'engine','validation/experiments/engine','completed',false, ...
    'scope','Fresh computations; not a claim of source-author code identity or global convergence.');
save_json(report,fullfile(outputRoot,'execution_status.json'));
if strcmp(mode,'smoke')
    checkDir=fullfile(outputRoot,'checks');mkdir(checkDir);
    update=run_update_checks(checkDir);fe=run_fe_checks(checkDir);
    small=small_model_checks(fullfile(outputRoot,'small_models'));
    report.update_checks=height(update);report.update_passed=nnz(update.passed);
    report.FE_checks=height(fe);report.FE_passed=nnz(fe.passed);
    report.small_model_checks=small;
elseif strcmp(mode,'regression')
    checks=run_solver_regression_checks(fullfile(outputRoot,'checks'),fullfile(repo,'src'));
    report.production_regression_passed=all(checks.passed);
elseif any(strcmp(mode,{'histories','initial10'}))
    package=run_history_experiments(outputRoot,mode);
    report.history_package_completed=package.completed;
else
    cases=verification_suite_cases();
    groups=string(cellfun(@(c)c.group,cases,'UniformOutput',false));
    ids=string(cellfun(@(c)c.run_id,cases,'UniformOutput',false));
    switch mode
        case {'baselines','bridge_energy'}
            selected=find(groups=="baseline");
        case 'sensitivity'
            selected=find(ids=="cantilever" | groups=="sensitivity");
        case 'deadband_sweep'
            selected=find(ismember(ids,["cantilever","cantilever_eps_0p05", ...
                "cantilever_eps_0p5","cantilever_eps_5"]));
        case 'all'
            selected=find(ismember(groups,["baseline","sensitivity"]));
    end
    report.run_ids=ids(selected);
    save_json(report,fullfile(outputRoot,'execution_status.json'));
    rows=cell(numel(selected),1);
    for k=1:numel(selected)
        cfg=cases{selected(k)};
        rows{k}=verification_run_one(cfg,outputRoot);
    end
    summary=struct2table(vertcat(rows{:}));
    summary=add_material_maxima(summary,outputRoot);
    verification_write_table(summary,fullfile(outputRoot,'suite_summary.csv'));
    report.runs=height(summary);
    % Count iteration caps from the recorded termination reason.
    report.iteration_cap_runs=nnz(summary.termination_reason=="max_iterations");
    report.endpoint_response_flag_false_runs=nnz(~summary.converged);
    if any(strcmp(mode,{'bridge_energy','all'}))
        for id={'cantilever','bridge_3a','bridge_3b'}
            folder=fullfile(outputRoot,'runs',id{1});d=load(fullfile(folder,'result.mat'),'result','cfg');
            a=run_bridge_energy_audit(d.result,d.cfg,fullfile(folder,'audits'));
            run_stress_recovery_study(d.result,d.cfg,fullfile(folder,'audits'),a.fe);
        end
    end
    if strcmp(mode,'all')
        package=run_history_experiments(outputRoot,'histories');
        report.history_package_completed=package.completed;
    end
end
report.completed=true;
save_json(report,fullfile(outputRoot,'execution_status.json'));
fprintf('Verification mode %s completed. Results: %s\n',mode,outputRoot);
end

function T=add_material_maxima(T,root)
T.M1_util_max_percent=nan(height(T),1);T.M2_util_max_percent=T.M1_util_max_percent;
for k=1:height(T)
    d=load(fullfile(root,'runs',char(T.run_id(k)),'result.mat'),'result');r=d.result;
    for phase=1:2
        values=r.response.sigvm(r.mi_map==phase);
        if isempty(values),value=NaN;else
            if phase==1,strength=r.materials.sigma_m1;else,strength=r.materials.sigma_m2;end
            value=100*max(values)/strength;
        end
        if phase==1,T.M1_util_max_percent(k)=value;else,T.M2_util_max_percent(k)=value;end
    end
end
end

function count=small_model_checks(root)
mkdir(root);cfg=verification_case_config('cantilever');cfg.nelx=10;cfg.nely=6;
cfg.options.max_iterations=3;cfg.options.force_iteration_limit=true;
cfg.options.r1_mm=200;cfg.options.r2_mm=300;
r=mbeso(cfg.nelx,cfg.nely,cfg.volfrac,cfg.er,cfg.options);
a=run_bridge_energy_audit(r,cfg,fullfile(root,'cantilever'));
s=run_stress_recovery_study(r,cfg,fullfile(root,'cantilever'),a.fe);
assert(height(s.extrema)==9,'Only full-domain extrema belong in verification output.');
assert(a.passed);count=height(a.checks);
for id={'bridge_3a','bridge_3b'}
    cfg=verification_case_config(id{1});cfg.nelx=8;cfg.nely=4;
    cfg.options.structure_width=4;cfg.options.structure_height=2;
    cfg.options.fixed_solid_mask=false(4,8);cfg.options.design_mask=true(4,8);
    cfg.options.r1_mm=750;cfg.options.r2_mm=1500;
    cfg.options.analysis_only=true;cfg.options.initial_mi_map=ones(4,8);
    cfg.options.initial_mi_map(:,5:end)=2;cfg.options.initial_mi_map(2:3,4)=0;
    if strcmp(id{1},'bridge_3a'),cfg.options.deck_load_node_row=4;else,cfg.options.deck_load_node_row=1;end
    r=mbeso_fixed_solid(cfg.nelx,cfg.nely,cfg.volfrac,cfg.er,cfg.options);
    a=run_bridge_energy_audit(r,cfg,fullfile(root,id{1}));assert(a.passed);
    run_stress_recovery_study(r,cfg,fullfile(root,id{1}),a.fe);
    count=count+height(a.checks);
end
end

function save_json(s,file)
f=fopen(file,'w','n','UTF-8');assert(f>=0);c=onCleanup(@()fclose(f)); %#ok<NASGU>
fprintf(f,'%s',jsonencode(s,'PrettyPrint',true));
end

function restore_environment(oldPath,oldDirectory)
path(oldPath);cd(oldDirectory);clear mbeso mbeso_fixed_solid
end
