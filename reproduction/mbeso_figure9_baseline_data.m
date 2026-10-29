function P=mbeso_figure9_baseline_data(dataFolder,writeCSV)
%MBESO_FIGURE9_BASELINE_DATA Derive Fig. 9(e,f) from the recorded phase maps.
% The same extraction is used for archived and freshly prepared histories.
% No archived hash or numerical reference value is required for fresh data.
if nargin<1,dataFolder=fullfile(fileparts(mfilename('fullpath')),'figure_09','data');end
if nargin<2,writeCSV=false;end
L=load(fullfile(dataFolder,'source_states_0_214.mat'),'S');S=L.S;
baseline=find(S.epsilon_MPa==0);assert(isscalar(baseline));
phase=S.phase(:,:,baseline);N=size(phase,1);
assert(isequal(S.states,(0:214)') && isequal(size(phase),[6000 215]));
assert(all(ismember(phase(:),[0 1 2])));
P=struct('states',(0:214)','updates',(1:214)','epsilon_MPa',0,'domain_elements',N);
P.solid_count=sum(phase>0,1)';
P.tensile_count=sum(phase==1,1)';P.compressive_count=sum(phase==2,1)';
P.solid_fraction=P.solid_count/N;P.V1=P.tensile_count/N;P.V2=P.compressive_count/N;
before=phase(:,1:end-1);after=phase(:,2:end);
P.N_TC=sum(before>0 & after>0 & before~=after,1)';
P.N_SV=sum((before>0)~=(after>0),1)';
P.state_definition='State k is the material layout after update k; state 0 is initialization.';
P.transition_definition='Update k compares state k-1 with state k. TC changes material within common solids; SV changes occupancy.';
P.volume_definition='Counts divided by all 6000 domain elements; residual void stiffness or density is not counted as solid.';
P.source_file='figure_09/data/source_states_0_214.mat';
assert(isequal(P.solid_count,P.tensile_count+P.compressive_count));
assert(isequal(P.N_TC,double(S.reference_N_TC(:,baseline))));
assert(isequal(P.N_SV,double(S.reference_N_SV(:,baseline))));
B=load(fullfile(dataFolder,'plot_inputs_214.mat'),'P');
barBaseline=find(B.P.epsilon_MPa==0);assert(isscalar(barBaseline));
P.full_transition_totals=[sum(P.N_TC(2:214)) sum(P.N_SV(2:214))];
P.zoom_transition_totals=[sum(P.N_TC(195:214)) sum(P.N_SV(195:214))];
P.fig9c_baseline_totals=B.P.counts_updates_2_214(barBaseline,:);
assert(isequal(P.full_transition_totals,P.fig9c_baseline_totals), ...
    'Fig. 9(f) history sums must equal the Fig. 9(c) baseline bars.');
if ~writeCSV,return;end
stateRows=2:215;
T=table(P.states(stateRows),P.solid_count(stateRows),P.tensile_count(stateRows),P.compressive_count(stateRows), ...
    100*P.solid_fraction(stateRows),100*P.V1(stateRows),100*P.V2(stateRows), ...
    'VariableNames',{'iteration','solid_count','tensile_count','compressive_count', ...
    'actual_solid_percent','V1_tensile_percent','V2_compressive_percent'});
write17(T,fullfile(dataFolder,'Fig09e_volume_fractions_1_214.csv'));
T=table(P.updates,P.N_TC,P.N_SV,'VariableNames',{'iteration','material_transitions','solid_void_transitions'});
write17(T(2:214,:),fullfile(dataFolder,'Fig09f_1_transitions_2_214.csv'));
write17(T(195:214,:),fullfile(dataFolder,'Fig09f_2_transitions_195_214.csv'));
comparison=table([2;2],[214;214],[1;2],P.full_transition_totals',P.fig9c_baseline_totals', ...
    P.full_transition_totals'-P.fig9c_baseline_totals', ...
    'VariableNames',{'first_iteration','last_iteration','event_type_1_material_2_solid_void', ...
    'Fig09f_history_sum','Fig09c_baseline_bar','difference'});
write17(comparison,fullfile(dataFolder,'Fig09f_vs_Fig09c_totals.csv'));
end

function write17(T,file)
fid=fopen(file,'w','n','UTF-8');assert(fid>=0);guard=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',strjoin(T.Properties.VariableNames,','));
for k=1:height(T)
    values=arrayfun(@(x)sprintf('%.17g',double(x)),T{k,:},'UniformOutput',false);
    fprintf(fid,'%s\n',strjoin(values,','));
end
end
