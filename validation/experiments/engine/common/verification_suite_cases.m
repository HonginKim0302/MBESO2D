function cases=verification_suite_cases()
%REVIEW_SUITE_CASES Declared controls, fixed before inspecting results.
b=verification_case_config('cantilever'); cases={b,verification_case_config('bridge_3a'),verification_case_config('bridge_3b')};
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
% All endpoint variants use their own stopping criterion or iteration cap.
extra={ 'eps_0p05',0.05; 'eps_0p5',0.5; 'eps_5',5 };
for j=1:size(extra,1)
    c=b;c.group='sensitivity';c.run_id=['cantilever_' extra{j,1}];
    c.options.material_zero_tolerance=extra{j,2};
    c.changed_option=['material_zero_tolerance=' char(string(extra{j,2}))];
    cases{end+1}=c; %#ok<AGROW>
end
end
