function checks=verify_manuscript_data
%VERIFY_MANUSCRIPT_DATA Check stored plotting arrays and displayed derivations.
% These checks validate replay consistency. They do not replace FE tests or
% show that the reference article's unpublished implementation was reproduced.
root=fileparts(mfilename('fullpath'));rows={};
z=load(fullfile(root,'figure_06','data','plot_inputs.mat'),'P');p=z.P;
t=readtable(fullfile(root,'figure_06','data','panel_c_force_equilibrium.csv'));
record('Fig06_deck_force_CSV',p.external_MN,t.external_MN,0);
record('Fig06_selfweight_force_CSV',p.selfweight_MN,t.selfweight_MN,0);
record('Fig06_reaction_CSV',p.reaction_MN,t.reaction_MN,0);
t=readtable(fullfile(root,'figure_06','data','panel_d_energy_components.csv'));
record('Fig06_energy_components_CSV',p.energy_components_MNm, ...
    [t.energy_external_MNm,t.energy_cross_MNm,t.energy_selfweight_MNm],0);
record('Fig06_energy_sum',sum(p.energy_components_MNm,2),p.C_MNm,1e-11);

z=load(fullfile(root,'figure_08','data','plot_inputs.mat'),'P');p=z.P;
t=readtable(fullfile(root,'figure_08','data','panels_b_c_local_fields.csv'));
fields={'state_iteration','decision_update','trace_raw_974_MPa','trace_filtered_974_MPa', ...
    'eta_raw_974','eta_spatial_974','eta_temporal_974','selection_cutoff','eta_temporal_5829'};
for j=1:numel(fields),record(['Fig08_' fields{j} '_CSV'],p.local.(fields{j}),t.(fields{j}),0);end
record('Fig08_input_to_update',p.local.decision_update,p.local.state_iteration+1,0);
record('Fig08_first_ten_update_positions',p.local.decision_update(1:10),(1:10)',0);
if ~isfile(fullfile(root,'fresh_source.json'))
    record('Fig08_update7_filtered_stress',p.local.trace_filtered_974_MPa(7),.20557675,5e-9);
    record('Fig08_update5_history_score',p.local.eta_temporal_974(5),.08168058,5e-9);
end
record('Fig08_first_history_equals_spatial',p.local.eta_temporal_974(1),p.local.eta_spatial_974(1),0);
record('Fig08_adjacent_spatial_mean',p.local.eta_temporal_974(2:10), ...
    (p.local.eta_spatial_974(1:9)+p.local.eta_spatial_974(2:10))/2,1e-15);
t=readtable(fullfile(root,'figure_08','data','panel_d_assignment_inputs.csv'));
record('Fig08_recorded_assignment_matches_independent_decision',t.actual_material_after_update,t.predicted_material,0);
for e=[974 5829]
    q=t(t.element==e,:);q=sortrows(q,'update');
    record(sprintf('Fig08_element%d_update_positions',e),q.update,(1:10)',0);
    record(sprintf('Fig08_element%d_input_states',e),q.input_state,(0:9)',0);
    if e==974
        record('Fig08_d_inputs_connect_to_b',q.filtered_trace_MPa,p.local.trace_filtered_974_MPa(1:10),0);
        record('Fig08_d_inputs_connect_to_c',q.history_score,p.local.eta_temporal_974(1:10),0);
    end
end

z=load(fullfile(root,'figure_09','data','plot_inputs_214.mat'),'P');p=z.P;
z=load(fullfile(root,'figure_09','data','source_states_0_214.mat'),'S');s=z.S;
t=readtable(fullfile(root,'figure_09','data','C_history_0_214_Nmm.csv'));
record('Fig09_history_CSV_full_precision',p.C_Nmm,t{:,2:end},1e-11);
record('Fig09_common_state_response_change',p.C_change_same_state_percent,100*(p.C_Nmm./p.C_Nmm(:,1)-1),0);
record('Fig09_transition_window_2_214',p.counts_updates_2_214, ...
    [sum(p.N_TC(2:214,:),1)',sum(p.N_SV(2:214,:),1)'],0);
record('Fig09_layout_difference_denominators',p.layout_difference_percent, ...
    100*p.layout_difference_counts./p.layout_difference_denominators,0);
record('Fig09_states_0_214',p.states,(0:214)',0);
record('Fig09_C_matches_recorded_source_states',p.C_Nmm,s.C_Nmm,0);
for j=1:5
    before=s.phase(:,1:214,j);after=s.phase(:,2:215,j);
    tc=sum(before>0 & after>0 & before~=after,1)';
    sv=sum((before>0)~=(after>0),1)';
    record(sprintf('Fig09_case%d_material_events_from_actual_phases',j),p.N_TC(:,j),tc,0);
    record(sprintf('Fig09_case%d_occupancy_events_from_actual_phases',j),p.N_SV(:,j),sv,0);
    record(sprintf('Fig09_case%d_state214_map',j),p.final_phase_214(:,j),s.phase(:,215,j),0);
end
% Independently extract baseline fractions and transition events for Fig. 9(e,f).
baseline=find(s.epsilon_MPa==0);assert(isscalar(baseline));
phase=s.phase(:,:,baseline);counts=zeros(215,3);tc=zeros(214,1);sv=tc;
for k=1:215
    counts(k,:)=[nnz(phase(:,k)>0),nnz(phase(:,k)==1),nnz(phase(:,k)==2)];
    if k>1
        old=phase(:,k-1);new=phase(:,k);
        tc(k-1)=nnz((old==1 & new==2) | (old==2 & new==1));
        sv(k-1)=nnz((old==0 & new~=0) | (old~=0 & new==0));
    end
end
fraction=100*(counts/size(phase,1));
record('Fig09e_solid_partition',counts(:,1),counts(:,2)+counts(:,3),0);
t=readtable(fullfile(root,'figure_09','data','Fig09e_volume_fractions_1_214.csv'));
record('Fig09e_CSV_states_1_214',t.iteration,(1:214)',0);
record('Fig09e_CSV_actual_element_counts',t{:,2:4},counts(2:215,:),0);
record('Fig09e_CSV_domain_fractions',t{:,5:7},fraction(2:215,:),3e-14);
t=readtable(fullfile(root,'figure_09','data','Fig09f_1_transitions_2_214.csv'));
record('Fig09f1_CSV_unsmoothed_updates',t{:,:},[(2:214)' tc(2:214) sv(2:214)],0);
t=readtable(fullfile(root,'figure_09','data','Fig09f_2_transitions_195_214.csv'));
record('Fig09f2_CSV_unsmoothed_updates',t{:,:},[(195:214)' tc(195:214) sv(195:214)],0);
totals=[sum(tc(2:214)) sum(sv(2:214))];
record('Fig09f_full_totals_match_Fig09c_baseline',totals,p.counts_updates_2_214(baseline,:),0);
t=readtable(fullfile(root,'figure_09','data','Fig09f_vs_Fig09c_totals.csv'));
record('Fig09f_vs_Fig09c_CSV',t{:,:},[2 214 1 totals(1) totals(1) 0;2 214 2 totals(2) totals(2) 0],0);
if ~isfile(fullfile(root,'fresh_source.json'))
    record('Fig09f_archived_full_totals',totals,[3286 5140],0);
    record('Fig09f_archived_zoom_totals',[sum(tc(195:214)) sum(sv(195:214))],[47 102],0);
    record('Fig09e_archived_final_partition',counts(end,:),[2400 549 1851],0);
end
checks=cell2table(rows,'VariableNames',{'check','max_absolute_error','tolerance','passed'});
writetable(checks,fullfile(root,'replay_data_checks.csv'));
assert(all(checks.passed),'Stored plot-data verification failed; inspect replay_data_checks.csv.');
fprintf('Stored plot data: %d checks passed.\n',height(checks));

    function record(name,a,b,tolerance)
        if numel(a)~=numel(b),err=Inf;else,err=max(abs(double(a(:))-double(b(:))));end
        rows(end+1,:)={name,err,tolerance,err<=tolerance}; %#ok<AGROW>
    end
end
