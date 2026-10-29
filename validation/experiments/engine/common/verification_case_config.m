function cfg = verification_case_config(case_id)
%REVIEW_CASE_CONFIG Explicit manuscript inputs. All fractions use full domain.
% SPDX-License-Identifier: GPL-3.0-or-later
cfg = struct('case_id',case_id,'nelx',100,'nely',60,'volfrac',0.4, ...
    'er',0.01,'solver','mbeso','group','baseline','run_id',case_id, ...
    'changed_option','manuscript baseline');
m = struct('E1',200000,'nu1',0.3,'sigma_m1',250, ...
    'E2',20000,'nu2',0.3,'sigma_m2',50,'nu3',0.3, ...
    'rho1',7800,'rho2',2400,'rho0',0);
o = struct('materials',m,'penal',3,'xmin',0.001,'tau',1e-5, ...
    'bc_case','cantilever','bc_load',1000,'verbose',false,'plotting',false, ...
    'r1_mm',20,'r2_mm',30,'even_keep_count',false, ...
    'structure_width',1000,'structure_height',600,'structure_dimension_unit','mm', ...
    'out_of_plane_thickness_m',0.001,'tension_eta_mode','with_nk', ...
    'write_run_report',false,'save_result',false,'max_iterations',1000, ...
    'force_iteration_limit',false,'continue_after_convergence',0, ...
    'diagnostic_fields',true,'stress_measure','center','volume_rounding','floor', ...
    'tie_policy','index','tie_seed',1729,'material_zero_tolerance',0);
cfg.archived_compliance_Nmm=574.783605811;
cfg.reference_compliance_Nmm=614.16;
cfg.reference_max_vm_MPa=53.32;
cfg.exclusion_size_mm=40;
switch case_id
    case 'cantilever'
        cfg.archived_iterations=214;
    case {'bridge_3a','bridge_3b'}
        cfg.nelx=320; cfg.nely=80; cfg.solver='mbeso_fixed_solid';
        o.tau=1e-3; o.r1_mm=750; o.r2_mm=1500; o.even_keep_count=true;
        o.structure_width=160; o.structure_height=40; o.structure_dimension_unit='m';
        o.out_of_plane_thickness_m=1; o.deck_line_load_N_per_m=1e5;
        o.deck_load_distribution='equal_nodes'; o.include_self_weight=true; o.gravity=9.81;
        o.fixed_solid_mask=false(80,320); o.design_mask=true(80,320);
        if strcmp(case_id,'bridge_3a')
            o.bc_case='run_case_3a'; o.fixed_solid_mask(78:80,:)=true; o.deck_load_node_row=78;
            cfg.archived_compliance_Nmm=2552153826.2; cfg.archived_iterations=95;
            cfg.reference_compliance_Nmm=7.82e9; cfg.reference_max_vm_MPa=139.52;
        else
            o.bc_case='run_case_3b'; o.fixed_solid_mask(1:3,:)=true; o.deck_load_node_row=1;
            cfg.archived_compliance_Nmm=1675156216.16; cfg.archived_iterations=93;
            cfg.reference_compliance_Nmm=5e9; cfg.reference_max_vm_MPa=133.06;
        end
        cfg.exclusion_size_mm=NaN;
    otherwise
        error('Unknown review case: %s',case_id);
end
cfg.options=o;
cfg.reporting_convention='C = 0.5 F^T U; native N mm; bridge figures divide by 1000';
cfg.material_convention='0 void (white); 1 tensile material (blue); 2 compressive material (red)';
cfg.input_provenance='Manuscript geometry/material/load; archived reports for tau, parity and nodal distribution';
end
