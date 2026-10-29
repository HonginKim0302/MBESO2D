function checks = run_update_checks(output_dir)
% Hand-specified expected values exercise the actual solver-local kernels.
% No saved optimizer output is used as an oracle for these checks.
if nargin < 1, output_dir = ''; end
repo = fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(repo,'src'),'-begin');
rows = cell(0,5);
for solver_name = {'mbeso','mbeso_fixed_solid'}
    name = solver_name{1}; k = feval(name,'review_kernels');
    [H,Hs] = k.prepare_filter(3,2,1.5);
    actual = k.apply_filter(H,Hs,7*ones(2,3),2,3);
    record(name,'constant_field_filter',max(abs(actual(:)-7)),2e-14);
    f = reshape(1:6,2,3); actual = k.apply_filter(H,Hs,f,2,3);
    expected = (1.5*1 + .5*2 + .5*3 + (1.5-sqrt(2))*4) / (2.5+1.5-sqrt(2));
    record(name,'corner_distance_normalization',abs(actual(1)-expected),2e-14);
    f = zeros(2,3); f(1)=1; actual = k.apply_filter(H,Hs,f,2,3);
    expected = 1.5/(1.5+.5+.5+1.5-sqrt(2));
    record(name,'corner_impulse',abs(actual(1)-expected),2e-14);
    score = [3 2 2 1 0 0]; review = mbeso_review_options(struct());
    if strcmp(name,'mbeso')
        mask = k.select_keep_mask(score,true(1,6),.4,true(1,6),false,review);
        record(name,'exact_tie_index',nnz(mask ~= logical([1 1 0 0 0 0])),0);
        review.tie_policy = 'reverse';
        mask = k.select_keep_mask(score,true(1,6),.4,true(1,6),false,review);
        record(name,'exact_tie_reverse',nnz(mask ~= logical([1 0 1 0 0 0])),0);
        review.tie_policy = 'index';
        mask = k.select_keep_mask(score,logical([0 1 1 1 1 0]),.4,false(1,6),false,review);
        record(name,'forced_void_preserved',nnz(mask ~= logical([0 1 1 0 0 0])),0);
        for mode = {'floor','round','ceil'}
            review.volume_rounding=mode{1};
            [~,requested,~,effective] = k.select_keep_mask(score,true(1,6),.45,true(1,6),false,review);
            expected=2+~strcmp(mode{1},'floor');
            record(name,['volume_count_' mode{1}],max(abs([requested effective]-expected)),0);
        end
        review = mbeso_review_options(struct());
        [mask,~,~,effective] = k.select_keep_mask(reshape(1:8,2,4),true(2,4),.375,true(2,4),true,review);
        record(name,'legacy_even_count',abs(nnz(mask)-4)+abs(effective-4),0);
    else
        free = logical([1 1 1 1 0 0]); fixed = logical([0 0 0 0 0 1]);
        mask = k.select_keep_mask(score,free,fixed,.5,false,review);
        record(name,'fixed_and_forced_void',nnz(mask ~= logical([1 1 0 0 0 1])),0);
        [mask,requested,~,effective] = k.select_keep_mask(score,free,fixed,2/6,true,review);
        record(name,'even_free_count',abs(nnz(mask)-3)+abs(requested-2)+abs(effective-3),0);
        review.tie_policy='reverse';
        mask = k.select_keep_mask(score,free,fixed,.5,false,review);
        record(name,'exact_tie_reverse',nnz(mask ~= logical([1 0 1 0 0 1])),0);
        review.tie_policy='index';
        for mode = {'floor','round','ceil'}
            review.volume_rounding=mode{1};
            [~,requested,~,effective]=k.select_keep_mask(score,free,fixed,.45,false,review);
            expected=2+~strcmp(mode{1},'floor');
            record(name,['volume_count_' mode{1}],max(abs([requested effective]-expected)),0);
        end
    end
    [nk,eta] = k.update_utilization(250,50,[10 10 10],.01,.4,[1 -1 0],1,'with_nk',1);
    expected_nk = exp(log(5)*log(.99)/log(.4));
    record(name,'nk_increment',abs(nk-expected_nk),2e-15);
    record(name,'raw_sign_utilization',max(abs(eta-[.2/expected_nk .2 .2/expected_nk])),2e-15);
    [nk,eta] = k.update_utilization(250,50,sqrt(3)*10,.01,.4,0,0,'with_nk',5);
    record(name,'pure_shear_nonzero_vm_zero_trace',abs(eta-sqrt(3)*10/250)+abs(nk-5),2e-15);
    [nk,~] = k.update_utilization(250,50,1,.01,.4,1,100,'with_nk',4.999);
    record(name,'nk_upper_bound',abs(nk-5),0);
    [~,eta] = k.update_utilization(250,50,10,.01,.4,1,1,'without_nk',1);
    record(name,'without_nk_normalization',abs(eta-.04),2e-15);
    % Independent quadrature of stiffness checks the solver's closed form.
    D = 200/(1-.3^2)*[1 .3 0;.3 1 0;0 0 .35]; KE=zeros(8);
    for xi=[-1 1]/sqrt(3)
        for yi=[-1 1]/sqrt(3)
            gradients=[-(1-yi),1-yi,1+yi,-(1+yi);-(1-xi),-(1+xi),1+xi,1-xi]/2;
            B=zeros(3,8); B(1,1:2:end)=gradients(1,:); B(2,2:2:end)=gradients(2,:);
            B(3,1:2:end)=gradients(2,:); B(3,2:2:end)=gradients(1,:);
            KE=KE+B'*D*B/4;
        end
    end
    actual=k.lk(200,.3);
    record(name,'Q4_stiffness_independent_quadrature',norm(actual-KE,'fro')/norm(KE,'fro'),1e-13);
end
record('shared','temporal_first',abs(mbeso_review_update('temporal',1,99,1)-1),0);
record('shared','temporal_second',abs(mbeso_review_update('temporal',3,1,2)-2),0);
record('shared','temporal_third_uses_previous_spatial',abs(mbeso_review_update('temporal',9,3,3)-6),0);
phase=mbeso_review_update('classify',true(1,6),[1 -1 0 1e-5 -1e-5 0],[1 1 1 1 1 .001],[2 1 2 2 1 0],.001,0);
record('shared','zero_is_M1_default',nnz(phase ~= [1 2 1 1 2 1]),0);
phase=mbeso_review_update('classify',true(1,6),[1 -1 0 1e-5 -1e-5 0],[1 1 1 1 1 .001],[2 1 2 2 1 0],.001,1e-4);
record('shared','deadband_persistence_and_revival',nnz(phase ~= [1 2 2 2 1 1]),0);
review=mbeso_review_options(struct('tie_policy','fixed_random'));
score=[3;2;2;2+eps(2);0;0]; ids=(1:6)';
[v,a]=mbeso_review_update('sort',score,ids,6,review); [~,b]=mbeso_review_update('sort',score,ids,6,review);
record('shared','random_ties_reproducible',nnz(a~=b),0);
record('shared','random_ties_preserve_unequal_ranking',nnz(a(1:2)~=[1;4])+double(any(diff(v)>0)),0);
% Affine displacement patch: constant strain [0.001,0.004,-0.001].
fem=struct('nele',1,'nely',1,'nelx',1,'edofMat',1:8);
D=200/(1-.3^2)*[1 .3 0;.3 1 0;0 0 .35];
[vm,gp]=mbeso_review_gauss_vm([0;0;.01;-.03;.03;.01;.02;.04],1,1,fem,D,D,3,10,'gauss_mean_vm');
stress=D*[.001;.004;-.001]; expected=sqrt(stress(1)^2-stress(1)*stress(2)+stress(2)^2+3*stress(3)^2);
record('shared','Gauss_VM_affine_patch',max(abs([vm gp]-expected)),1e-14);
checks=cell2table(rows,'VariableNames',{'solver','check','error','tolerance','passed'});
if ~isempty(output_dir)
    if ~isfolder(output_dir), mkdir(output_dir); end
    writetable(checks,fullfile(output_dir,'update_checks.csv'));
    save(fullfile(output_dir,'update_checks.mat'),'checks');
end
fprintf('Update checks: %d/%d passed.\n',nnz(checks.passed),height(checks));
assert(all(checks.passed),'One or more independent update checks failed.');
    function record(solver,label,err,tol)
        rows(end+1,:)={solver,label,err,tol,isfinite(err)&&err<=tol};
    end
end
