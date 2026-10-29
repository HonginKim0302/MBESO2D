function bundle=prepare_manuscript_figures(freshRoot,bundle)
%PREPARE_MANUSCRIPT_FIGURES Derive plot inputs from newly executed review runs.
% Call after validation/review/run_review_experiments('all',freshRoot).
% A separate replay bundle is created; archived public inputs are preserved.
% The current manuscript geometry uses common states 0--214 on a 100x60
% cantilever. The baseline must reach its first termination criterion at 214;
% bridge iteration labels are read from each newly computed result.
here=fileparts(mfilename('fullpath'));
if nargin<1||isempty(freshRoot),error('Supply the output root of a complete review rerun.');end
freshRoot=char(java.io.File(freshRoot).getCanonicalPath());
if nargin<2||isempty(bundle),bundle=fullfile(freshRoot,'manuscript_figures');end
bundle=char(java.io.File(bundle).getCanonicalPath());
assert(~strcmpi(bundle,here),'Fresh figures must not overwrite archived publication data.');
assert(~startsWith(lower(bundle),[lower(here) filesep]),'Create the fresh bundle outside the archived reproduction folder.');
assert(~isfolder(bundle),'Choose a new output directory; existing bundles are preserved.');
required={fullfile('initial10','cantilever','full_history.mat')};
ids={'cantilever_eps_0','cantilever_eps_0p005','cantilever_eps_0p05','cantilever_eps_0p5','cantilever_eps_5'};
for j=1:numel(ids)
    required=[required,{fullfile('zero_history',ids{j},'full_history.mat'), ...
        fullfile('zero_history',ids{j},'state_history.csv')}]; %#ok<AGROW>
end
for id={'bridge_3a','bridge_3b'}
    required=[required,{fullfile('runs',id{1},'result.mat'),fullfile('runs',id{1},'audits','energy_audit.csv'), ...
        fullfile('runs',id{1},'audits','energy_decomposition.csv')}]; %#ok<AGROW>
end
missing=required(~cellfun(@(p)isfile(fullfile(freshRoot,p)),required));
assert(isempty(missing),'Required fresh records are missing: %s',strjoin(missing,', '));
mkdir(bundle);
% Copy only reproducible sources and small data templates, never old exports.
copySources(here,bundle);
% Bundle the authoritative display helper, without adding production solvers.
paletteSource=fullfile(fileparts(here),'src','mbeso_material_palette.m');
assert(isfile(paletteSource),'Shared material palette is missing.');
supportDir=fullfile(bundle,'support');if ~isfolder(supportDir),mkdir(supportDir);end
copyfile(paletteSource,fullfile(supportDir,'mbeso_material_palette.m'));
guard=onCleanup(@()writeIncomplete(bundle)); %#ok<NASGU>
oldPath=path;restore=onCleanup(@()path(oldPath)); %#ok<NASGU>
addpath(fullfile(here,'preparation'),'-begin');
prepare_figure8_data(freshRoot,fullfile(bundle,'figure_08'));
prepare_figure9_data(freshRoot,fullfile(bundle,'figure_09'));
mbeso_figure9_baseline_data(fullfile(bundle,'figure_09','data'),true);
prepare_assignment_data(freshRoot,fullfile(bundle,'figure_08','data'));
prepare_bridge_data(freshRoot,fullfile(bundle,'figure_06','data'));
status=struct('kind','fresh_review_run','complete',true,'fresh_root',freshRoot, ...
    'note','All numerical plot inputs derived from this fresh run; archived fallback is forbidden.', ...
    'required_source_files',{required});
fid=fopen(fullfile(bundle,'fresh_source.json'),'w');fprintf(fid,'%s',jsonencode(status,'PrettyPrint',true));fclose(fid);
fprintf('Fresh plot inputs prepared: %s\n',bundle);
fprintf('Run the RUN_MANUSCRIPT_FIGURES.m inside this new bundle to plot THESE new inputs.\n');
end

function copySources(src,dst)
entries=dir(src);
for j=1:numel(entries)
    e=entries(j);if startsWith(e.name,'.'),continue;end
    in=fullfile(src,e.name);out=fullfile(dst,e.name);
    if e.isdir
        if any(strcmp(e.name,{'exports','figures','panels','zoom','outputs'})),continue;end
        mkdir(out);copySources(in,out);
    else
        [~,parentName]=fileparts(src);
        keep=endsWith(e.name,{'.m','.md'}) || ...
            (strcmp(parentName,'data')&&endsWith(e.name,{'.mat','.csv','.json'})) || ...
            (strcmp(parentName,'reference')&&endsWith(e.name,{'.json','.csv'})) || ...
            (strcmp(parentName,'original_plot')&&endsWith(e.name,'.txt')) || ...
            (strcmp(parentName,'manuscript_original')&&strcmp(e.name,'manifest.json')) || ...
            any(strcmp(e.name,{'paper_output_profile.csv','output_size_overrides.csv', ...
                'fig10_panel_layout.json','final_panel_profile.json', ...
                'manuscript_panel_geometry.csv'}));
        if keep,copyfile(in,out);end
    end
end
end
function writeIncomplete(bundle)
if ~isfile(fullfile(bundle,'fresh_source.json'))
    fid=fopen(fullfile(bundle,'PREPARATION_INCOMPLETE.txt'),'w');
    fprintf(fid,'Preparation failed. Do not run this incomplete bundle; it may contain old data templates.\n');fclose(fid);
end
end
function prepare_assignment_data(root,out)
z=load(fullfile(root,'zero_history','cantilever_eps_0','full_history.mat'),'data');d=z.data;
A=zeros(20,9);row=0;
for element=[974 5829]
    for k=1:10
        row=row+1;score=d.eta_history(element,k);cutoff=d.cutoff(k+1);
        predicted=0;if score>=cutoff,predicted=2-double(d.trace_filtered(element,k)>=0);end
        actual=double(d.phase(element,k+1));
        A(row,:)=[element k-1 k d.trace_filtered(element,k) score cutoff predicted actual actual==predicted];
    end
end
T=array2table(A,'VariableNames',{'element','input_state','update','filtered_trace_MPa', ...
    'history_score','retention_threshold','predicted_material','actual_material_after_update','matches'});
write17(T,fullfile(out,'panel_d_assignment_inputs.csv'));
assert(all(T.matches),'The selected representative decisions no longer match the declared example; inspect fresh histories.');
end
function prepare_bridge_data(root,out)
z=load(fullfile(out,'plot_inputs.mat'),'P');P=z.P;
for j=1:2
    id=P.case_ids{j};folder=fullfile(root,'runs',id);
    r=load(fullfile(folder,'result.mat'),'result');
    A=readtable(fullfile(folder,'audits','energy_audit.csv'),'TextType','string');
    D=readtable(fullfile(folder,'audits','energy_decomposition.csv'),'TextType','string');
    value=@(name)A.value(A.metric==string(name));
    P.external_MN(j)=abs(value('external_vertical_load'))/1e6;
    P.selfweight_MN(j)=abs(value('self_weight_vertical_load'))/1e6;
    P.reaction_MN(j)=abs(value('total_vertical_load')-value('vertical_force_balance'))/1e6;
    names={'external_only','cross','self_weight_only'};
    for k=1:3,P.energy_components_MNm(j,k)=D.energy_Nmm(D.component==string(names{k}))/1e9;end
    % The total is independently evaluated as 0.5*F'*U, not a sum of bars.
    P.C_MNm(j)=value('energy_force')/1e9;
    assert(isscalar(P.C_MNm(j)) && isfinite(P.C_MNm(j)) && P.C_MNm(j)>0);
    decompositionError=abs(sum(P.energy_components_MNm(j,:))-P.C_MNm(j))/P.C_MNm(j);
    assert(decompositionError<=1e-7,'Fresh bridge energy decomposition failed: %s',id);
    P.C_production_MNm(j)=r.result.compliance/1e9;
    P.iteration(j)=r.result.iterations;
end
P.source_archive='Fresh run: runs/bridge_3a and runs/bridge_3b';
P.total_C_definition='Independent audit 0.5*F^T*U from energy_audit.csv, energy_force; not reconstructed from the plotted components.';
P.plotted_total_C_definition='Production result.compliance, retained separately as C_production_MNm and shown by the outlined total bar.';
save(fullfile(out,'plot_inputs.mat'),'P','-v7');
cases=string(P.case_ids(:));labels=string(P.cases(:));
T=table(cases,labels,P.iteration(:),P.external_MN(:),P.selfweight_MN(:),P.reaction_MN(:), ...
    1e6*(P.reaction_MN(:)-P.external_MN(:)-P.selfweight_MN(:)), ...
    'VariableNames',{'case_id','case_label','iteration','external_MN','selfweight_MN','reaction_MN','reaction_minus_load_N'});
write17(T,fullfile(out,'panel_c_force_equilibrium.csv'));
T=table(cases,labels,P.iteration(:),P.energy_components_MNm(:,1),P.energy_components_MNm(:,2), ...
    P.energy_components_MNm(:,3),P.C_MNm(:),P.C_production_MNm(:), ...
    'VariableNames',{'case_id','case_label','iteration','energy_external_MNm','energy_cross_MNm','energy_selfweight_MNm','C_MNm','C_production_MNm'});
write17(T,fullfile(out,'panel_d_energy_components.csv'));
write17(T,fullfile(out,'plot_inputs.csv'));
component_sum=sum(P.energy_components_MNm,2); total_C=P.C_MNm(:);
production_C=P.C_production_MNm(:);
T=table(cases,component_sum,total_C,production_C,component_sum-total_C, ...
    abs(component_sum-total_C)./abs(total_C), ...
    abs(component_sum-production_C)./abs(production_C), ...
    'VariableNames',{'case_id','component_sum_MNm','independent_total_C_MNm', ...
    'production_total_C_MNm','difference_MNm','relative_difference', ...
    'relative_difference_from_production'});
write17(T,fullfile(out,'total_C_comparison.csv'));
end
function write17(T,file)
fid=fopen(file,'w');assert(fid>=0);guard=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',strjoin(T.Properties.VariableNames,','));
for i=1:height(T)
    values=cell(1,width(T));
    for j=1:width(T)
        v=T{i,j};if iscell(v),v=v{1};end
        if isnumeric(v)||islogical(v),values{j}=sprintf('%.17g',v);
        else,values{j}=['"' strrep(char(string(v)),'"','""') '"'];end
    end
    fprintf(fid,'%s\n',strjoin(values,','));
end
end
