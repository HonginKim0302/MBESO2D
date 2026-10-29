function cases=review_suite_cases()
%REVIEW_SUITE_CASES Declared controls, fixed before inspecting results.
b=review_case_config('cantilever'); cases={b,review_case_config('bridge_3a'),review_case_config('bridge_3b')};
spec={ 'vm_mean','stress_measure','gauss_mean_vm'; 'vm_max','stress_measure','gauss_max_vm'; ...
    'r1_15','r1_mm',15;'r1_25','r1_mm',25;'r2_20','r2_mm',20;'r2_40','r2_mm',40; ...
    'zero_1e8','material_zero_tolerance',50e-8;'zero_1e6','material_zero_tolerance',50e-6; ...
    'zero_1e4','material_zero_tolerance',50e-4;'round','volume_rounding','round'; ...
    'ceil','volume_rounding','ceil';'ties_reverse','tie_policy','reverse'; ...
    'ties_random','tie_policy','fixed_random'};
for j=1:size(spec,1)
    c=b;c.group='sensitivity';c.run_id=['cantilever_' spec{j,1}];
    c.options.(spec{j,2})=spec{j,3};c.changed_option=[spec{j,2} '=' char(string(spec{j,3}))];
    cases{end+1}=c; %#ok<AGROW>
end
for j=1:3
    c=cases{j};c.group='continuation';c.run_id=[c.case_id '_continuation'];
    c.options.continue_after_convergence=50;c.changed_option='50 additional updates after first stopping criterion';
    cases{end+1}=c; %#ok<AGROW>
end
for mesh=[50 100 200]
    c=b;c.nelx=mesh;c.nely=round(mesh*0.6);c.group='mesh';
    c.run_id=sprintf('cantilever_mesh_%dx%d_iter214',c.nelx,c.nely);
    c.options.force_iteration_limit=true;c.options.max_iterations=214;c.changed_option='fixed iteration 214, common physical radii';
    cases{end+1}=c; %#ok<AGROW>
end
for mesh=[50 200]
    c=b;c.nelx=mesh;c.nely=round(mesh*0.6);c.group='mesh_convergence';
    c.run_id=sprintf('cantilever_mesh_%dx%d_converged',c.nelx,c.nely);
    c.changed_option='individual stopping criterion, common physical radii';cases{end+1}=c; %#ok<AGROW>
end
for j=2:3
    c=cases{j};c.group='bridge_sensitivity';c.run_id=[c.case_id '_consistent'];
    c.options.deck_load_distribution='consistent';c.changed_option='consistent deck nodal load';cases{end+1}=c; %#ok<AGROW>
    c=cases{j};c.group='bridge_sensitivity';c.run_id=[c.case_id '_no_gravity'];
    c.options.include_self_weight=false;c.changed_option='self-weight disabled';cases{end+1}=c; %#ok<AGROW>
end
c=b;c.group='input_reconciliation';c.run_id='cantilever_legacy_nu3_0';c.options.materials.nu3=0;
c.changed_option='historical example void nu3=0 (not manuscript baseline)';cases{end+1}=c;
% Two prespecified combinations; interpret as interactions, not source-code inference.
c=b;c.group='interaction';c.run_id='cantilever_vmmax_r2_40';
c.options.stress_measure='gauss_max_vm';c.options.r2_mm=40;c.changed_option='gauss_max_vm + r2=40 mm';cases{end+1}=c;
c=b;c.group='interaction';c.run_id='cantilever_r1_15_r2_20';
c.options.r1_mm=15;c.options.r2_mm=20;c.changed_option='r1=15 mm + r2=20 mm';cases{end+1}=c;
% Table 10 extension: direct first-stop endpoints, not the common comparison state.
% Append these declarations so historical case indices remain unchanged.
extra={ 'eps_0p05',0.05; 'eps_0p5',0.5; 'eps_5',5 };
for j=1:size(extra,1)
    c=b;c.group='sensitivity';c.run_id=['cantilever_' extra{j,1}];
    c.options.material_zero_tolerance=extra{j,2};
    c.changed_option=['material_zero_tolerance=' char(string(extra{j,2}))];
    cases{end+1}=c; %#ok<AGROW>
end
end
