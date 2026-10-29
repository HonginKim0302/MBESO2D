function prepare_figure3_214_data()
%PREPARE_FIGURE3_214_DATA Reaggregate the archived 0--214 states, without FE.
% The portable source contains genuine material maps at every state. Thus
% state-214 differences are recalculated, not taken from state-264 bars.
root=fileparts(mfilename('fullpath')); out=fullfile(root,'data');
L=load(fullfile(out,'source_states_0_214.mat'),'S'); S=L.S;
assert(isequal(size(S.phase),[6000 215 5]));
assert(isequal(S.states,(0:214)') && isequal(S.updates,(1:214)'));
assert(all(ismember(S.phase(:),uint8([0 1 2]))));
assert(isequal(size(S.C_Nmm),[215 5]) && all(S.C_Nmm(:)>0));
TC=zeros(214,5); SV=TC; checks={};
counts=zeros(5,2); denominators=counts; final=S.phase(:,215,:);
final=reshape(final,6000,5); baseline=final(:,1);
for j=1:5
    before=S.phase(:,1:214,j); after=S.phase(:,2:215,j);
    TC(:,j)=sum(before>0 & after>0 & before~=after,1)';
    SV(:,j)=sum((before>0)~=(after>0),1)';
    check(S.run_ids{j},'C_vs_stored_state_csv',S.C_Nmm(:,j),S.reference_C_Nmm(:,j),0);
    check(S.run_ids{j},'TC_from_phase_vs_stored_state_csv',TC(:,j),S.reference_N_TC(:,j),0);
    check(S.run_ids{j},'SV_from_phase_vs_stored_state_csv',SV(:,j),S.reference_N_SV(:,j),0);
    check(S.run_ids{j},'TC_2_214_direct_vs_sum', ...
        nnz(before(:,2:214)>0 & after(:,2:214)>0 & before(:,2:214)~=after(:,2:214)),sum(TC(2:214,j)),0);
    check(S.run_ids{j},'SV_2_214_direct_vs_sum', ...
        nnz((before(:,2:214)>0)~=(after(:,2:214)>0)),sum(SV(2:214,j)),0);
    p=final(:,j); common=p>0 & baseline>0;
    counts(j,:)=[nnz((p>0)~=(baseline>0)),nnz(p(common)~=baseline(common))];
    denominators(j,:)=[6000 nnz(common)];
end
change=100*(S.C_Nmm./S.C_Nmm(:,1)-1);
check('all','initial_C_percent_zero',change(1,:),zeros(1,5),0);
check('all','baseline_C_percent_zero',change(:,1),zeros(215,1),0);
check('baseline','TC_2_214_known_archive',sum(TC(2:214,1)),3286,0);
P=struct('schema_version',2,'run_ids',{S.run_ids},'epsilon_MPa',S.epsilon_MPa, ...
    'labels',{{'0','0.005','0.05','0.5','5'}},'states',S.states,'updates',S.updates, ...
    'C_Nmm',S.C_Nmm,'C_change_same_state_percent',change,'N_TC',TC,'N_SV',SV, ...
    'counts_updates_2_214',[sum(TC(2:214,:),1)' sum(SV(2:214,:),1)'], ...
    'final_phase_214',final,'layout_difference_counts',counts, ...
    'layout_difference_denominators',denominators, ...
    'layout_difference_percent',100*counts./denominators,'first_stop',S.first_stop, ...
    'nelx',100,'nely',60,'full_domain_elements',6000,'comparison_state',214, ...
    'C_definition','Stored C in N mm; percentage = 100*(C_epsilon(k)/C_0(k)-1) at the same state k, 0 through 214.', ...
    'transition_definition','Update k compares states k-1 and k. TC counts changes between two solid materials; SV counts changes in occupancy.', ...
    'count_definition','Cumulative element-transition events over updates 2 through 214; update 1 is excluded. Counts are not unique elements.', ...
    'layout_definition','At state 214 against epsilon=0: occupancy mismatch divided by 6000; material mismatch divided by common solid elements.', ...
    'zero_definition','Baseline percentage and all initial percentages are exactly zero by definition and equal initial C.', ...
    'index_definition','MATLAB phase(:,k+1) and C(k+1) represent state k; state 0 precedes design updates.', ...
    'termination_definition','214 is the baseline first termination-criterion state. This is a common iteration window; other EPS cases first satisfy the criterion at different states.', ...
    'canvas_mm',[154.9 175.4]);
save(fullfile(out,'plot_inputs_214.mat'),'P','-v7');
names={'epsilon_0','epsilon_0p005','epsilon_0p05','epsilon_0p5','epsilon_5'};
write17(array2table([double(S.states) S.C_Nmm],'VariableNames',[{'state'} names]),fullfile(out,'C_history_0_214_Nmm.csv'));
write17(array2table([double(S.states) change],'VariableNames',[{'state'} names]),fullfile(out,'C_change_same_state_0_214_percent.csv'));
write17(table(repelem(string(S.run_ids(:)),214),repelem(S.epsilon_MPa(:),214), ...
    repmat(S.updates,5,1),TC(:),SV(:),'VariableNames',{'run_id','epsilon_MPa','update','N_TC','N_SV'}), ...
    fullfile(out,'transition_events_updates_1_214.csv'));
write17(table(string(S.run_ids(:)),S.epsilon_MPa(:),P.counts_updates_2_214(:,1),P.counts_updates_2_214(:,2), ...
    'VariableNames',{'run_id','epsilon_MPa','TC_updates_2_214','SV_updates_2_214'}),fullfile(out,'transition_window_counts_2_214.csv'));
write17(table(string(S.run_ids(:)),S.epsilon_MPa(:),counts(:,1),denominators(:,1),P.layout_difference_percent(:,1), ...
    counts(:,2),denominators(:,2),P.layout_difference_percent(:,2), ...
    'VariableNames',{'run_id','epsilon_MPa','occupancy_mismatch_count','all_domain_denominator','occupancy_difference_percent', ...
    'material_mismatch_count','common_solid_denominator','material_difference_percent'}),fullfile(out,'layout_difference_214.csv'));
write17(array2table([(1:6000)' double(final)],'VariableNames',[{'element_id_MATLAB_column_major'} names]), ...
    fullfile(out,'final_material_maps_214.csv'));
write17(table(string(S.run_ids(:)),S.epsilon_MPa(:),S.first_stop(:),P.C_Nmm(end,:)',change(end,:)', ...
    'VariableNames',{'run_id','epsilon_MPa','first_termination_criterion_state','C_at_214_Nmm','C_change_at_214_percent'}), ...
    fullfile(out,'comparison_state_214.csv'));
V=cell2table(checks,'VariableNames',{'run_id','check','maximum_absolute_error','tolerance','passed'});
write17(V,fullfile(out,'source_array_checks_214.csv')); assert(all(V.passed));
fprintf('Figure 3 state-214 data: %d checks passed; no optimization performed.\n',height(V));

    function check(id,name,actual,expected,tolerance)
        assert(isequal(size(actual),size(expected)));
        err=max(abs(double(actual(:))-double(expected(:))));
        checks(end+1,:)={id,name,err,tolerance,isfinite(err)&&err<=tolerance};
    end
end

function write17(T,file)
fid=fopen(file,'w','n','UTF-8'); assert(fid>=0); guard=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',strjoin(T.Properties.VariableNames,','));
for i=1:height(T)
    items=cell(1,width(T));
    for j=1:width(T)
        v=T{i,j}; if iscell(v),v=v{1};end
        if isnumeric(v)||islogical(v),items{j}=sprintf('%.17g',double(v));
        else,items{j}=['"' strrep(char(string(v)),'"','""') '"'];end
    end
    fprintf(fid,'%s\n',strjoin(items,','));
end
end
