function fe = verification_independent_fe(result, cfg)
% Reassemble a frozen production layout using independent Gauss-integrated Q4s.
% Native units are N, mm, MPa. Displacements prescribed at supports are zero.
o = cfg.options; [ny,nx] = size(result.x); ne = nx*ny;
assert(cfg.nelx == nx && cfg.nely == ny,'Configuration and layout sizes differ.');
m = result.materials;
w = field(o,'structure_width',1000); h = field(o,'structure_height',600);
unit = field(o,'structure_dimension_unit','mm');
if strcmpi(unit,'m'), w=w*1000; h=h*1000; end
assert(any(strcmpi(unit,{'m','mm'})),'Unsupported geometry unit.');
hx = w/nx; hy = h/ny;
t = field(o,'out_of_plane_thickness_m',1e-3)*1000;
p = field(o,'penal',3);
kernels = {verification_q4_kernel(m.E1,m.nu1,t,hx,hy), ...
    verification_q4_kernel(m.E2,m.nu2,t,hx,hy), ...
    verification_q4_kernel(m.E2,m.nu3,t,hx,hy)};
[row,col] = ndgrid(1:ny,1:nx);
tl = row(:)+(col(:)-1)*(ny+1);
nodes = [tl,tl+(ny+1),tl+(ny+2),tl+1];
edof = zeros(ne,8); edof(:,1:2:8)=2*nodes-1; edof(:,2:2:8)=2*nodes;
ndof = 2*(nx+1)*(ny+1);
phase = result.mi_map(:); phase(phase==0)=3;
penalty = result.x(:).^p;
ke = zeros(64,ne);
for j=1:3, ids=phase==j; ke(:,ids)=kernels{j}.K(:)*penalty(ids)'; end
ii = zeros(64,ne); jj=ii;
for j=1:ne
    [ii_local,jj_local]=ndgrid(edof(j,:),edof(j,:));
    ii(:,j)=ii_local(:); jj(:,j)=jj_local(:);
end
K = sparse(ii(:),jj(:),ke(:),ndof,ndof);
K=(K+K')/2;
[node_y,node_x]=ndgrid((0:ny)*hy,(0:nx)*hx);
node_xy=[node_x(:),node_y(:)];
Fq=sparse(ndof,1); Fg=sparse(ndof,1);
bc=field(o,'bc_case','cantilever');
switch lower(bc)
    case 'cantilever'
        Fq(end)=field(o,'bc_load',1000);
        fixed=(1:2*(ny+1))';
    case {'run_case_3a','run_case_3b'}
        if strcmpi(bc,'run_case_3a'), supportrow=ny+1; else, supportrow=1; end
        loadrow=field(o,'deck_load_node_row',supportrow);
        if isempty(loadrow), loadrow=supportrow; end
        loadnodes=loadrow+(0:nx)*(ny+1);
        q=field(o,'deck_line_load_N_per_m',[]);
        if isempty(q)
            loads=field(o,'bc_load',1000)*ones(nx+1,1);
        else
            sgn=field(o,'deck_load_sign',1);
            distribution=field(o,'deck_load_distribution','consistent');
            if strcmpi(distribution,'equal_nodes')
                loads=sgn*q*(w/1000)/(nx+1)*ones(nx+1,1);
            elseif strcmpi(distribution,'consistent')
                loads=sgn*q*(hx/1000)*ones(nx+1,1); loads([1 end])=loads([1 end])/2;
            else, error('Unsupported deck distribution.'); end
        end
        Fq(2*loadnodes)=loads;
        left=supportrow; right=supportrow+nx*(ny+1);
        fixed=unique([2*left-1;2*left;2*right]);
    otherwise, error('Independent audit does not implement bc_case %s.',bc);
end
rho=zeros(ne,1);
rho(result.mi_map(:)==1)=field(m,'rho1',7800);
rho(result.mi_map(:)==2)=field(m,'rho2',2400);
element_mass_kg=rho*(hx*hy/1e6)*(t/1000);
mass_kg=sum(element_mass_kg);
if field(o,'include_self_weight',false)
    grav=field(o,'gravity',9.81);
    sign_g=field(o,'gravity_load_sign',field(o,'deck_load_sign',1));
    node_force=repmat(element_mass_kg*grav*sign_g/4,1,4);
    vertical=edof(:,2:2:8);
    Fg=sparse(vertical(:),ones(numel(vertical),1),node_force(:),ndof,1);
end
F=Fq+Fg;
free=setdiff((1:ndof)',fixed);
U=zeros(ndof,1); U(free)=K(free,free)\F(free);
Us=result.response.U;
assert(size(Us,2)==1,'This audit requires one load case per run.');
assert(numel(Us)==ndof,'Source displacement vector has wrong size.');
Ue=U(edof); Us_e=Us(edof);
element_energy=zeros(ne,1);
center=zeros(ne,3); source_center=center;
source_gauss=zeros(ne,3,4);
for j=1:3
    ids=phase==j; ker=kernels{j};
    element_energy(ids)=.5*sum((Ue(ids,:)*ker.K).*Ue(ids,:),2).*penalty(ids);
    center(ids,:)=(Ue(ids,:)*ker.B_center'*ker.D').*penalty(ids);
    source_center(ids,:)=(Us_e(ids,:)*ker.B_center'*ker.D').*penalty(ids);
    for q=1:4
        source_gauss(ids,:,q)=(Us_e(ids,:)*ker.B_gauss(:,:,q)'*ker.D').*penalty(ids);
    end
end
R=K*U-F;
Rs=K*Us-F;
fe=struct('case_id',cfg.case_id,'K',K,'Fq',Fq,'Fg',Fg,'F',F, ...
    'U',U,'U_source',Us,'reaction',R,'source_residual',Rs, ...
    'fixed_dofs',fixed,'free_dofs',free,'edof',edof,'nodes',nodes, ...
    'node_xy_mm',node_xy,'element_energy_Nmm',element_energy, ...
    'element_mass_kg',element_mass_kg,'mass_kg',mass_kg, ...
    'center_stress',center,'source_center_stress',source_center, ...
    'source_gauss_stress',source_gauss,'gauss_points',kernels{1}.gauss_points, ...
    'center_vm',reshape(vm(center),ny,nx), ...
    'hx_mm',hx,'hy_mm',hy,'thickness_mm',t,'x',result.x,'mi_map',result.mi_map);
end

function value=field(s,name,fallback)
if isfield(s,name), value=s.(name); else, value=fallback; end
end
function v=vm(s)
v=sqrt(max(0,s(:,1).^2-s(:,1).*s(:,2)+s(:,2).^2+3*s(:,3).^2));
end
