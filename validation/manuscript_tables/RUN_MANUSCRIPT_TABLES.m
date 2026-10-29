% SPDX-License-Identifier: GPL-3.0-or-later
% Copyright (C) 2026 MBESO2D contributors
function [table8, table10] = RUN_MANUSCRIPT_TABLES(output_dir, fresh_runs_dir)
%RUN_MANUSCRIPT_TABLES Recompute Tables 8 and 10 from actual endpoint FE fields.
% Default: use the compact, archived final states bundled in data/.
% Optional fresh_runs_dir: directory containing runs/<run_id>/result.mat,
% or the runs directory itself. Run baselines and sensitivity there first.
% For the three added deadbands, a recorded full_history.mat in the same
% fresh root is also accepted; its first_stop state is used, not common state 214.
% No solver is called here. Utilization uses the assigned material strength.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
if nargin<1 || isempty(output_dir),output_dir=fullfile(repo,'results','manuscript_tables');end
if nargin<2,fresh_runs_dir='';end
if ~isfolder(output_dir),mkdir(output_dir);end
saved=load(fullfile(here,'data','tables_input.mat'),'cases');
if iscell(saved.cases),cases=[saved.cases{:}];else,cases=saved.cases;end
meta=readtable(fullfile(here,'data','sensitivity_archived.csv'),'TextType','string');
refs=readtable(fullfile(here,'data','reference_compliance.csv'),'TextType','string');
using_archive=isempty(fresh_runs_dir);
input_sources=struct('run_id',{},'relative_file',{},'sha256',{},'input_kind',{},'state',{});
if ~using_archive
    if isfolder(fullfile(fresh_runs_dir,'runs'))
        fresh_root=fresh_runs_dir;fresh_runs_dir=fullfile(fresh_root,'runs');
    else
        fresh_root=fileparts(char(fresh_runs_dir));
    end
    for k=1:numel(cases)
        input=fullfile(fresh_runs_dir,cases(k).run_id,'result.mat');
        history_input=fullfile(fresh_root,'zero_history',cases(k).run_id,'full_history.mat');
        if isfile(input)
            loaded=load(input,'result');r=loaded.result;
            if is_added_deadband(cases(k).run_id)
                assert(isfield(r,'convergence_iteration') && ...
                    r.iterations==r.convergence_iteration, ...
                    'Table 10 requires the first response stop, not a continuation endpoint: %s',input);
            end
            cases(k).C_Nmm=r.compliance;cases(k).iterations=r.iterations;
            cases(k).termination_reason=r.termination_reason;cases(k).converged=r.converged;
            cases(k).phase=uint8(r.mi_map);cases(k).x=r.x;
            cases(k).vm_center_MPa=r.response.sigvm;cases(k).xmin=r.settings.xmin;
            cases(k).sigma_m1_MPa=r.materials.sigma_m1;cases(k).sigma_m2_MPa=r.materials.sigma_m2;
            relative_file=fullfile('runs',cases(k).run_id,'result.mat');
            kind='run_endpoint';
        elseif is_added_deadband(cases(k).run_id) && isfile(history_input)
            input=history_input;
            cases(k)=from_first_stop_history(cases(k),input);
            relative_file=fullfile('zero_history',cases(k).run_id,'full_history.mat');
            kind='recorded_first_stop';
        else
            error('MBESO:MissingFreshTableInput', ...
                'Missing fresh run: %s. No archived numerical fallback is used.',input);
        end
        input_sources(k)=struct('run_id',cases(k).run_id, ...
            'relative_file',strrep(relative_file,'\','/'), ...
            'sha256',sha256_file(input),'input_kind',kind,'state',double(cases(k).iterations));
    end
end
% One fixed response under two reporting conventions, not two optimizations.
rows=cell(height(refs),8);
for k=1:height(refs)
    r=get_case(cases,refs.run_id(k));scale=refs.Nmm_per_display_unit(k);ref=refs.reference_C_Nmm(k);
    rows(k,:)={refs.case_label(k),refs.display_unit(k),ref/scale,r.C_Nmm/scale, ...
        2*r.C_Nmm/scale,100*(r.C_Nmm/ref-1),100*(2*r.C_Nmm/ref-1),refs.reference_definition_status(k)};
end
table8=cell2table(rows,'VariableNames',{'case_label','unit','reference_C','C_half_FtU','twice_C_FtU', ...
    'difference_C_percent','difference_twice_C_percent','reference_interpretation'});
baseline=get_case(cases,'cantilever');rows=cell(height(meta),12);
for k=1:height(meta)
    r=get_case(cases,meta.run_id(k));solid=r.x>r.xmin;
    m1=solid&r.phase==1;m2=solid&r.phase==2;
    assert(any(m1(:))&&any(m2(:)),'Both materials are expected in these manuscript cases.');
    vm=max(r.vm_center_MPa(solid));
    u1=100*max(r.vm_center_MPa(m1))/r.sigma_m1_MPa;
    u2=100*max(r.vm_center_MPa(m2))/r.sigma_m2_MPa;
    delta=100*(r.C_Nmm/baseline.C_Nmm-1);
    if r.converged,reason="response_criterion";else,reason=string(r.termination_reason);end
    if using_archive
        period2=meta.last20_exact_nonstationary_period2(k);
        actual=[r.C_Nmm,delta,vm,u1,u2,r.iterations];
        expected=[meta.C_Nmm(k),meta.C_change_percent(k),meta.full_vm_max_MPa(k), ...
            meta.full_M1_util_max_percent(k),meta.full_M2_util_max_percent(k),meta.iterations(k)];
        assert(max(abs(actual-expected))<1e-9,'Archived table mismatch: %s',r.run_id);
    else
        period2=NaN; % Fresh endpoint alone cannot prove a final two-cycle.
    end
    rows(k,:)={string(r.run_id),meta.factor_group(k),meta.changed_option(k),r.C_Nmm,delta,vm,u1,u2, ...
        r.iterations,reason,logical(r.converged),period2};
end
table10=cell2table(rows,'VariableNames',{'run_id','factor_group','setting','C_Nmm','C_change_percent', ...
    'max_centroidal_VM_MPa','M1_max_utilization_percent','M2_max_utilization_percent', ...
    'iterations','termination_reason','response_criterion_satisfied','last20_two_cycle_archived'});
write_csv17(fullfile(output_dir,'Table8_compliance_conventions.csv'),table8);
write_csv17(fullfile(output_dir,'Table10_one_factor_sensitivity.csv'),table10);
save(fullfile(output_dir,'manuscript_tables.mat'),'table8','table10');
fid=fopen(fullfile(output_dir,'Table8.md'),'w','n','UTF-8');g=onCleanup(@()fclose(fid));
fprintf(fid,'| Case | Unit | Reference C | C = 0.5 F''U | 2C | Difference C (%%) | Difference 2C (%%) |\n|---|---|---:|---:|---:|---:|---:|\n');
for k=1:height(table8)
    fprintf(fid,'| %s | %s | %.8g | %.8g | %.8g | %+.2f | %+.2f |\n',table8.case_label(k),table8.unit(k), ...
        table8.reference_C(k),table8.C_half_FtU(k),table8.twice_C_FtU(k),table8.difference_C_percent(k),table8.difference_twice_C_percent(k));
end
fprintf(fid,'\nThe reference compliance definition is unconfirmed; bridge units are interpreted as N m. This is a conditional convention comparison.\n');clear g;
fid=fopen(fullfile(output_dir,'Table10.md'),'w','n','UTF-8');g=onCleanup(@()fclose(fid));
fprintf(fid,'| Setting | Delta C (%%) | Maximum VM (MPa) | M1 maximum (%%) | M2 maximum (%%) | Updates | End |\n|---|---:|---:|---:|---:|---:|---|\n');
for k=1:height(table10)
    fprintf(fid,'| %s | %+.2f | %.2f | %.2f | %.2f | %d | %s |\n',table10.setting(k),table10.C_change_percent(k), ...
        table10.max_centroidal_VM_MPa(k),table10.M1_max_utilization_percent(k),table10.M2_max_utilization_percent(k), ...
        table10.iterations(k),table10.termination_reason(k));
end
fprintf(fid,'\nEach row uses its own stopping/cap endpoint. All stresses are centroidal and over the full solid domain. Utilization is nonnegative within each assigned-material subset; no 40 mm exclusion is used.\n');clear g;
status=struct('passed',true,'used_archived_fields',using_archive,'cases',numel(cases), ...
    'table8_rows',height(table8),'table10_rows',height(table10),'new_FE_executed',false, ...
    'utilization_definition','100 VM / assigned strength: M1=250 MPa, M2=50 MPa', ...
    'reference_convention_confirmed',false,'input_mat_sha256',sha256_file(fullfile(here,'data','tables_input.mat')));
status.input_mat_role='Bundled field archive and required run-ID list';
if ~using_archive
    status.input_mat_role='Run-ID list only; numerical fields read from fresh files';
end
status.fresh_input_sources=input_sources;
status.table10_endpoint_definition='Each variant uses its first analysis-termination criterion or iteration cap; added deadbands use first_stop, not common iteration 214.';
fid=fopen(fullfile(output_dir,'table_generation_status.json'),'w');g=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(status,'PrettyPrint',true));
disp(table8);disp(table10);fprintf('Tables saved to %s\n',output_dir);
end
function yes=is_added_deadband(id)
yes=any(strcmp(id,{'cantilever_eps_0p05','cantilever_eps_0p5','cantilever_eps_5'}));
end
function r=from_first_stop_history(r,input)
loaded=load(input,'data');d=loaded.data;k=double(d.first_stop);
assert(isfinite(k)&&k>=1&&k==floor(k)&&k<=d.n_updates, ...
    'A recorded first response stop is required: %s',input);
assert(strcmp(d.run_id,r.run_id),'Unexpected history run ID: %s',input);
shape=[d.cfg.nely,d.cfg.nelx];
assert(size(d.phase,1)==prod(shape)&&size(d.phase,2)>=k+1);
r.C_Nmm=d.C(k+1);r.iterations=k;r.termination_reason='response_criterion';r.converged=true;
r.phase=reshape(uint8(d.phase(:,k+1)),shape);
r.vm_center_MPa=reshape(d.state_vm(:,k+1),shape);
r.xmin=d.cfg.options.xmin;r.x=ones(shape);r.x(r.phase==0)=r.xmin;
r.sigma_m1_MPa=d.cfg.options.materials.sigma_m1;
r.sigma_m2_MPa=d.cfg.options.materials.sigma_m2;
end
function r=get_case(cases,id)
idx=find(strcmp({cases.run_id},char(id)));assert(isscalar(idx),'Expected one case %s.',id);r=cases(idx);
r.iterations=double(r.iterations); % Keep concatenated comparison rows in double precision.
end
function write_csv17(path,T)
fid=fopen(path,'w','n','UTF-8');guard=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',strjoin(T.Properties.VariableNames,','));
for k=1:height(T)
    for j=1:width(T)
        if j>1,fprintf(fid,',');end
        value=T{k,j};if iscell(value),value=value{1};end
        if isnumeric(value)||islogical(value),fprintf(fid,'%.17g',value);
        else,fprintf(fid,'"%s"',strrep(char(string(value)),'"','""'));end
    end
    fprintf(fid,'\n');
end
end
function hash=sha256_file(path)
fid=fopen(path,'rb');g=onCleanup(@()fclose(fid));b=fread(fid,Inf,'*uint8');
md=java.security.MessageDigest.getInstance('SHA-256');md.update(b);
hash=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
