function checks = run_fe_checks(outDir)
% Affine patch, analytic boundary tractions, and rigid-motion checks.
if nargin<1, outDir=pwd; end
if ~exist(outDir,'dir'),mkdir(outDir);end
k=review_q4_kernel(200000,.3,2,10,6);
xy=k.coordinates_mm;
u=zeros(8,1);
u(1:2:8)=.001*xy(:,1)+.00015*xy(:,2)+.12;
u(2:2:8)=.00025*xy(:,1)-.0002*xy(:,2)-.08;
expected_strain=[.001;-.0002;.0004];
expected_stress=[206.5934065934066;21.97802197802198;30.76923076923077];
expected_energy=12.87032967032967;
strain_error=norm(k.B_center*u-expected_strain,Inf);
stress_error=norm(k.D*k.B_center*u-expected_stress,Inf);
gauss_error=0;
for q=1:4
    gauss_error=max(gauss_error,norm(k.D*k.B_gauss(:,:,q)*u-expected_stress,Inf));
end
energy_error=abs(.5*u'*k.K*u-expected_energy);
sx=expected_stress(1);sy=expected_stress(2);tau=expected_stress(3);
% Each uniform boundary traction integrates to half its edge resultant/node.
traction=[-sx*6-tau*10;-tau*6-sy*10; ...
    sx*6-tau*10;tau*6-sy*10; ...
    sx*6+tau*10;tau*6+sy*10; ...
    -sx*6+tau*10;-tau*6+sy*10];
traction_error=norm(k.K*u-traction,Inf);
rigid=[ones(4,1),zeros(4,1),-xy(:,2);zeros(4,1),ones(4,1),xy(:,1)];
rigid=rigid([1 5 2 6 3 7 4 8],:);
rigid_error=norm(k.K*rigid,Inf);
symmetry_error=norm(k.K-k.K',Inf);
names={'affine_center_strain';'affine_center_stress';'affine_gauss_stress'; ...
    'analytic_strain_energy';'analytic_edge_tractions';'rigid_modes';'stiffness_symmetry'};
errors=[strain_error;stress_error;gauss_error;energy_error;traction_error;rigid_error;symmetry_error];
tolerance=[1e-12;1e-8;1e-8;1e-8;1e-7;1e-7;1e-8];
checks=table(names,errors,tolerance,errors<=tolerance, ...
    'VariableNames',{'check','absolute_error','tolerance','passed'});
review_write_table(checks,fullfile(outDir,'fe_patch_checks.csv'));
save(fullfile(outDir,'fe_patch_checks.mat'),'checks','expected_strain','expected_stress','expected_energy','traction','u');
assert(all(checks.passed),'Independent FE patch checks failed.');
end
