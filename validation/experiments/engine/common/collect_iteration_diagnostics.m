function [callback, finish] = collect_iteration_diagnostics(cfg)
%COLLECT_ITERATION_DIAGNOSTICS Read-only observer; iteration 0 is recorded.
% Driving stresses refer to the OLD layout; response and maps to NEW layout.
% SPDX-License-Identifier: GPL-3.0-or-later
n=cfg.options.max_iterations+1; sz=[cfg.nely cfg.nelx];
names={'iteration','compliance','Vk','solid_fraction','V1','V2','nk','change', ...
    'N_SV','N_TC','N_TtoC','N_CtoT','near_zero_count','near_zero_1e8_count', ...
    'near_zero_1e6_count','sign_disagreement_count','two_cycle_count', ...
    'exact_cutoff_ties','keep_count','target_keep','effective_keep','cutoff', ...
    'raw_trace_min_abs','filtered_trace_min_abs'};
d=struct(); for j=1:numel(names), d.(names{j})=nan(n,1); end
phases=zeros([sz n],'uint8');
d.cumulative_TC_map=zeros(sz); d.cumulative_SV_map=zeros(sz);
d.cumulative_two_cycle_map=zeros(sz); d.cumulative_near_zero_map=zeros(sz);
last=[]; before=[]; used=0; lastDriving=struct();
callback=@observe; finish=@finalize;
    function observe(s)
        used=used+1; k=used; phase=uint8(s.mi_map); phase(s.x<=cfg.options.xmin)=0;
        phases(:,:,k)=phase;
        direct={'iteration','compliance','Vk','solid_fraction','V1','nk','change', ...
            'keep_count','target_keep','effective_keep','cutoff'};
        for q=1:numel(direct), key=direct{q}; if isfield(s,key), d.(key)(k)=s.(key); end, end
        d.V2(k)=s.solid_fraction-s.V1;
        sv=false(sz); tc=sv; cy=sv;
        if ~isempty(last)
            sv=(phase>0)~=(last>0);
            common=phase>0 & last>0;
            tc=common & phase~=last;
            d.N_TtoC(k)=nnz(common & last==1 & phase==2);
            d.N_CtoT(k)=nnz(common & last==2 & phase==1);
            if ~isempty(before), cy=(phase==before)&(phase~=last)&phase>0&last>0; end
        else
            d.N_TtoC(k)=0; d.N_CtoT(k)=0;
        end
        d.N_SV(k)=nnz(sv); d.N_TC(k)=nnz(tc); d.two_cycle_count(k)=nnz(cy);
        d.cumulative_TC_map=d.cumulative_TC_map+tc;
        d.cumulative_SV_map=d.cumulative_SV_map+sv;
        d.cumulative_two_cycle_map=d.cumulative_two_cycle_map+cy;
        if isfield(s,'driving_sigma_filtered')
            raw=s.driving_sigma_raw; filt=s.driving_sigma_filtered;
            active=last>0; % field evaluated in the previous (driving) solid layout
            near=active & abs(filt)<=50e-4;
            d.near_zero_count(k)=nnz(near);
            d.near_zero_1e8_count(k)=nnz(active & abs(filt)<=50e-8);
            d.near_zero_1e6_count(k)=nnz(active & abs(filt)<=50e-6);
            d.sign_disagreement_count(k)=nnz(active & ((raw>=0)~=(filt>=0)));
            d.raw_trace_min_abs(k)=min(abs(raw(active)),[],'all');
            d.filtered_trace_min_abs(k)=min(abs(filt(active)),[],'all');
            d.cumulative_near_zero_map=d.cumulative_near_zero_map+near;
            free=true(sz);
            if isfield(cfg.options,'design_mask'), free=free & cfg.options.design_mask; end
            if isfield(cfg.options,'fixed_solid_mask'), free=free & ~cfg.options.fixed_solid_mask; end
            d.exact_cutoff_ties(k)=nnz(free & s.driving_eta_history==s.cutoff);
            fields={'driving_sigma_raw','driving_sigma_filtered','driving_eta_raw', ...
                'driving_eta_spatial','driving_eta_history','previous_x','previous_mi_map', ...
                'post_sigma_raw','post_sigvm_center'};
            for q=1:numel(fields), if isfield(s,fields{q}), lastDriving.(fields{q})=s.(fields{q}); end, end
        end
        before=last; last=phase;
        if s.iteration>0 && mod(s.iteration,100)==0
            fprintf('  %s iteration %d: C=%.12g, SV=%d, TC=%d\n',cfg.run_id,s.iteration,s.compliance,nnz(sv),nnz(tc));
        end
    end
    function diagnostics=finalize()
        diagnostics=d;
        for q=1:numel(names), diagnostics.(names{q})=d.(names{q})(1:used); end
        diagnostics.phase_history=phases(:,:,1:used);
        diagnostics.final_mi_map=double(last);
        diagnostics.last_driving_state=lastDriving;
        diagnostics.near_zero_diagnostic_epsilon_MPa=50e-4;
        diagnostics.near_zero_denominator='previous-layout solid elements; filtered driving trace';
        diagnostics.transition_definition='TC: both iterations solid; SV: occupancy differs; two_cycle: solid A-B-A';
        diagnostics.iteration_alignment='maps and compliance are post-update; driving fields are pre-update';
    end
end
