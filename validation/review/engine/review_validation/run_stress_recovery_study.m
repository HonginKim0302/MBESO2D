function study = run_stress_recovery_study(result,cfg,outDir,fe)
% Compare stress evaluation on exactly the same layout and displacement field.
% Gauss mean means mean(von Mises), not von Mises(mean(stress tensor)).
if ~exist(outDir,'dir'),mkdir(outDir);end
if nargin<4 || isempty(fe),fe=review_independent_fe(result,cfg);end
[ny,nx]=size(result.x); ne=nx*ny;
s=fe.source_center_stress; sg=fe.source_gauss_stress;
center_vm=vm(s);
gauss_vm=zeros(ne,4); gauss_trace=zeros(ne,4);
for q=1:4
    gauss_vm(:,q)=vm(sg(:,:,q));
    gauss_trace(:,q)=sg(:,1,q)+sg(:,2,q);
end
mean_vm=mean(gauss_vm,2); [max_vm,max_q]=max(gauss_vm,[],2);
center_trace=s(:,1)+s(:,2);
max_trace=gauss_trace(sub2ind([ne,4],(1:ne)',max_q));
vms=[center_vm,mean_vm,max_vm];
traces=[center_trace,mean(gauss_trace,2),max_trace];
[row,col]=ndgrid(1:ny,1:nx);
cx=(col(:)-.5)*fe.hx_mm;cy=(row(:)-.5)*fe.hy_mm;
hotspot_x=[cx,cx,cx+fe.gauss_points(max_q,1)*fe.hx_mm/2];
hotspot_y=[cy,cy,cy+fe.gauss_points(max_q,2)*fe.hy_mm/2];
phase=result.mi_map(:); solid=phase~=0;
m=result.materials;
% Cross-check the actual optimizer's Gauss recovery against independent B/J.
if exist('mbeso_review_gauss_vm','file')==2
    fem=struct('edofMat',fe.edof,'nele',ne,'nely',ny,'nelx',nx);
    k1=review_q4_kernel(m.E1,m.nu1,fe.thickness_mm,fe.hx_mm,fe.hy_mm);
    k2=review_q4_kernel(m.E2,m.nu2,fe.thickness_mm,fe.hx_mm,fe.hy_mm);
    assert(abs(fe.hx_mm-fe.hy_mm)<1e-10,'Production Gauss helper assumes square elements.');
    penal=3;if isfield(cfg.options,'penal'),penal=cfg.options.penal;end
    [pm,pg]=mbeso_review_gauss_vm(result.response.U,result.x,result.mi_map,fem, ...
        k1.D,k2.D,penal,fe.hx_mm,'gauss_mean_vm');
    px=mbeso_review_gauss_vm(result.response.U,result.x,result.mi_map,fem, ...
        k1.D,k2.D,penal,fe.hx_mm,'gauss_max_vm');
    % Solid stresses are compared: historical void nu3 can differ from nu2.
    gauss_errors=[norm(pg(solid,:)-gauss_vm(solid,:),'fro')/max(norm(gauss_vm(solid,:),'fro'),eps); ...
        norm(pm(solid)-mean_vm(solid))/max(norm(mean_vm(solid)),eps); ...
        norm(px(solid)-max_vm(solid))/max(norm(max_vm(solid)),eps)];
    gauss_checks=table({'gauss_points';'gauss_vm_mean';'gauss_vm_max'},gauss_errors, ...
        repmat(1e-12,3,1),gauss_errors<=1e-12, ...
        'VariableNames',{'check','relative_error','tolerance','passed'});
    review_write_table(gauss_checks,fullfile(outDir,'gauss_recovery_checks.csv'));
    assert(all(gauss_checks.passed),'Production Gauss recovery differs from independent integration.');
end
assigned_allowable=nan(ne,1); assigned_allowable(phase==1)=m.sigma_m1;
assigned_allowable(phase==2)=m.sigma_m2;
assigned_util=vms./assigned_allowable;
nk=1;
if isfield(result,'history') && isfield(result.history,'nk_hist') && ~isempty(result.history.nk_hist)
    nk=result.history.nk_hist(end);
end
if isfield(result,'settings') && isfield(result.settings,'nk'),nk=result.settings.nk;end
if isfield(cfg.options,'tension_eta_mode') && strcmpi(cfg.options.tension_eta_mode,'without_nk')
    tensile_denominator=m.sigma_m1;
else
    tensile_denominator=nk*m.sigma_m2;
end
signed_util=vms/tensile_denominator;
negative=traces<0;signed_util(negative)=-vms(negative)/m.sigma_m2;
methods={'center','gauss_vm_mean','gauss_vm_max'};
region_names={'full'};requested=0;actual_x=0;actual_y=0;masks={false(ny,nx)};
if strcmpi(cfg.options.bc_case,'cantilever') && isfield(cfg,'consistency_exclusion_widths_mm')
    for width=cfg.consistency_exclusion_widths_mm
        nr=min(ny,ceil(width/fe.hy_mm));nc=min(nx,ceil(width/fe.hx_mm));
        mask=false(ny,nx);
        mask(1:nr,1:nc)=true;
        mask(end-nr+1:end,1:nc)=true;
        mask(end-nr+1:end,end-nc+1:end)=true;
        region_names{end+1}=sprintf('exclude_%dmm',width); %#ok<AGROW>
        requested(end+1)=width;actual_x(end+1)=nc*fe.hx_mm;actual_y(end+1)=nr*fe.hy_mm; %#ok<AGROW>
        masks{end+1}=mask; %#ok<AGROW>
    end
end
rows=cell(0,21);
groups={'all_solid','material_1','material_2'};
for j=1:3
    for r=1:numel(masks)
        for g=1:3
            eligible=solid & ~masks{r}(:);
            if g>1,eligible=eligible & phase==g-1;end
            ids=find(eligible);
            if isempty(ids)
                values=nan(1,13);count=0;
            else
                [value,idx]=max(vms(ids,j));hot=ids(idx);
                [assignedmax,ai]=max(assigned_util(ids,j));
                values=[value,hot,row(hot),col(hot),hotspot_x(hot,j),hotspot_y(hot,j), ...
                    phase(hot),assignedmax,min(signed_util(ids,j)),max(signed_util(ids,j)), ...
                    ids(ai),cx(ids(ai)),cy(ids(ai))];
                count=numel(ids);
            end
            rows(end+1,:)=[{methods{j},region_names{r},groups{g},requested(r), ...
                actual_x(r),actual_y(r),count,nnz(masks{r})},num2cell(values)]; %#ok<AGROW>
        end
    end
end
extrema=cell2table(rows,'VariableNames',{'method','region','material_group', ...
    'exclusion_requested_mm','exclusion_actual_mm','exclusion_actual_y_mm', ...
    'evaluated_solid_elements','excluded_elements','max_vm_MPa', ...
    'hotspot_element','hotspot_row','hotspot_column','hotspot_x_mm','hotspot_y_mm', ...
    'hotspot_material','max_assigned_utilization','min_signed_utilization', ...
    'max_signed_utilization','assigned_utilization_hotspot_element', ...
    'assigned_utilization_hotspot_center_x_mm','assigned_utilization_hotspot_center_y_mm'});
review_write_table(extrema,fullfile(outDir,'stress_extrema.csv'));
element_data=table((1:ne)',row(:),col(:),cx,cy,phase,result.x(:),center_vm,mean_vm,max_vm, ...
    center_trace,max_q,assigned_util(:,1),assigned_util(:,2),assigned_util(:,3), ...
    signed_util(:,1),signed_util(:,2),signed_util(:,3), ...
    'VariableNames',{'element','row','column','center_x_mm','center_y_mm','material','density', ...
    'center_vm_MPa','gauss_mean_vm_MPa','gauss_max_vm_MPa','center_trace_MPa', ...
    'max_vm_gauss_point','center_assigned_utilization','gauss_mean_assigned_utilization', ...
    'gauss_max_assigned_utilization','center_signed_utilization', ...
    'gauss_mean_signed_utilization','gauss_max_signed_utilization'});
review_write_table(element_data,fullfile(outDir,'stress_element_data.csv'));
mean_tensor=mean(sg,3);
study=struct('case_id',cfg.case_id,'center_vm',reshape(center_vm,ny,nx), ...
    'gauss_mean_vm',reshape(mean_vm,ny,nx),'gauss_max_vm',reshape(max_vm,ny,nx), ...
    'center_stress',s,'gauss_stress',sg,'gauss_vm',gauss_vm,'max_vm_gauss_point',max_q, ...
    'gauss_mean_tensor',mean_tensor,'gauss_mean_tensor_vm',reshape(vm(mean_tensor),ny,nx), ...
    'relative_mean_tensor_center_difference',norm(mean_tensor-s,'fro')/max(norm(s,'fro'),eps), ...
    'mi_map',result.mi_map,'x',result.x,'x_mm',reshape(cx,ny,nx),'y_mm',reshape(cy,ny,nx), ...
    'exclusion_masks',{masks},'region_names',{region_names},'extrema',extrema, ...
    'nk',nk,'assigned_utilization',assigned_util,'signed_utilization',signed_util, ...
    'methods',{methods},'notes',['Frozen layout and production displacements. Solid elements only in extrema. ' ...
    'Center and Gauss-VM-mean sign: corresponding trace. Gauss-VM-max sign: trace at maximizing Gauss point. ' ...
    'Assigned utilization uses the allowable of the assigned material; signed utilization uses stress-sign classification. ' ...
    'The mean of VM scalars differs from VM of the mean tensor. Exclusions affect evaluation only.']);
save(fullfile(outDir,'stress_recovery.mat'),'study','cfg','-v7.3');
end

function value=vm(s)
value=sqrt(max(0,s(:,1).^2-s(:,1).*s(:,2)+s(:,2).^2+3*s(:,3).^2));
end
