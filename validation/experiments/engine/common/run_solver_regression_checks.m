function checks=run_solver_regression_checks(outputDir,productionSrc)
% Compare the public solver and verification engine on identical 20-update runs.
% Public src has no diagnostic callback: compare its complete scalar history
% and final fields, rather than claiming to inspect every intermediate map.
% SPDX-License-Identifier: GPL-3.0-or-later
assert(nargin==2 && isfile(fullfile(productionSrc,'mbeso.m')));
if ~isfolder(outputDir),mkdir(outputDir);end
engineRoot=fileparts(fileparts(mfilename('fullpath')));
engineSrc=fullfile(engineRoot,'src');oldPath=path;
cleanup=onCleanup(@()restore_path(oldPath)); %#ok<NASGU>
rows={};records=struct();
for id={'cantilever','bridge_3a','bridge_3b'}
    cfg=verification_case_config(id{1});o=cfg.options;
    o.max_iterations=20;o.force_iteration_limit=true;
    if ~strcmp(id{1},'cantilever')
        % Retain bridge physics on a smaller mesh for a quick regression.
        cfg.nelx=64;cfg.nely=16;o.r1_mm=3750;o.r2_mm=7500;
        o.design_mask=true(16,64);o.fixed_solid_mask=false(16,64);
        if strcmp(id{1},'bridge_3a'),o.fixed_solid_mask(end,:)=true;o.deck_load_node_row=16;
        else,o.fixed_solid_mask(1,:)=true;o.deck_load_node_row=1;end
    end
    results=cell(1,3);
    for mode=1:3
        if mode==1,addpath(productionSrc,'-begin');expected=productionSrc;
        else,addpath(engineSrc,'-begin');expected=engineSrc;o.diagnostic_fields=(mode==2);end
        clear mbeso mbeso_fixed_solid
        assert(strcmpi(which(cfg.solver),fullfile(expected,[cfg.solver '.m'])));
        results{mode}=feval(cfg.solver,cfg.nelx,cfg.nely,cfg.volfrac,cfg.er,o);
        assert(results{mode}.iterations==20,'Expected exactly 20 updates.');
    end
    a=results{1};
    for mode=2:3
        b=results{mode};labels={'final_density','final_material','final_U','final_center_VM', ...
            'initial_C','C_history','nk_history','scheduled_volume_history','solid_fraction_history','M1_fraction_history'};
        errors=[nnz(a.x~=b.x),nnz(a.mi_map~=b.mi_map),max(abs(a.response.U(:)-b.response.U(:))), ...
            max(abs(a.response.sigvm(:)-b.response.sigvm(:))), ...
            abs(a.history.initial_beso_state.compliance-b.history.initial_beso_state.compliance), ...
            max(abs(a.history.compliance_hist-b.history.compliance_hist)), ...
            max(abs(a.history.nk_hist-b.history.nk_hist)),max(abs(a.history.Vk_hist-b.history.Vk_hist)), ...
            max(abs(a.history.solid_fraction_hist-b.history.solid_fraction_hist)),max(abs(a.history.V1_hist-b.history.V1_hist))];
        for j=1:numel(labels)
            rows(end+1,:)={string(id{1}),mode==2,string(labels{j}),errors(j),0,errors(j)==0}; %#ok<AGROW>
        end
    end
    records.(id{1})=struct('cfg',cfg,'options',o,'results',{results});
end
checks=cell2table(rows,'VariableNames',{'case_id','diagnostic_fields','check','error','tolerance','passed'});
verification_write_table(checks,fullfile(outputDir,'solver_regression_checks.csv'));
save(fullfile(outputDir,'solver_regression_checks.mat'),'checks','records','-v7.3');
fprintf('Production/verification-engine regression: %d/%d exact checks passed.\n',nnz(checks.passed),height(checks));
assert(all(checks.passed),'Verification engine differs from production on the declared regression cases.');
end
function restore_path(p)
path(p);clear mbeso mbeso_fixed_solid
end
