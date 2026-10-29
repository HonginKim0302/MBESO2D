function [table8,table9] = RUN_SUBMISSION_TABLES(outputRoot,freshRoot)
%RUN_SUBMISSION_TABLES Write Tables 8 and 9 of the 29 October 2026 submission.
% Table 8 is the supplied rounded Abaqus comparison, not a new external FE run.
% Table 9 is calculated from the assigned-material endpoint fields.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
if nargin<1||isempty(outputRoot),outputRoot=fullfile(repo,'results','submission_tables');end
if nargin<2,freshRoot='';end
if ~isfolder(outputRoot),mkdir(outputRoot);end
table8=readtable(fullfile(repo,'validation','abaqus_crosscheck.csv'),'TextType','string');
% Retain the previous reporting-convention output under an explicit legacy name.
[~,table9]=RUN_MANUSCRIPT_TABLES(fullfile(outputRoot,'legacy_reporting'),freshRoot);
table9.M2_signed_utilization_percent=-table9.M2_max_utilization_percent;
writetable(table8,fullfile(outputRoot,'Table08_Abaqus_comparison.csv'));
writetable(table9,fullfile(outputRoot,'Table09_one_factor_sensitivity.csv'));
save(fullfile(outputRoot,'submitted_tables.mat'),'table8','table9');
fid=fopen(fullfile(outputRoot,'Table08.md'),'w','n','UTF-8');assert(fid>=0);
fprintf(fid,'# Table 8. Reported fixed-layout FE comparison\n\n');
fprintf(fid,'These are rounded values supplied with the submitted manuscript. The reported <0.01%% bound is not recalculated from rounded values. Abaqus jobs are not included.\n\n');
fprintf(fid,'| Benchmark | Response | MBESO2D | Abaqus | Unit | Reported difference |\n|---|---|---:|---:|---|---|\n');
for k=1:height(table8)
    fprintf(fid,'| %s | %s | %.8g | %.8g | %s | %s |\n',table8.benchmark(k),table8.response(k), ...
        table8.mbeso2d_value(k),table8.abaqus_value(k),table8.unit(k),table8.reported_relative_difference(k));
end
fclose(fid);
fid=fopen(fullfile(outputRoot,'Table09.md'),'w','n','UTF-8');assert(fid>=0);
fprintf(fid,'# Table 9. One-factor endpoint sensitivity\n\n');
fprintf(fid,'Each row uses its own termination or iteration cap. Signed compression utilization is the negative of the maximum magnitude within assigned M2.\n\n');
fprintf(fid,'| Setting | C change (%%) | Peak VM (MPa) | M1 (%%) | Signed M2 (%%) | Iterations | Termination |\n|---|---:|---:|---:|---:|---:|---|\n');
for k=1:height(table9)
    fprintf(fid,'| %s | %+.2f | %.2f | %.2f | %.2f | %d | %s |\n',table9.setting(k), ...
        table9.C_change_percent(k),table9.max_centroidal_VM_MPa(k), ...
        table9.M1_max_utilization_percent(k),table9.M2_signed_utilization_percent(k), ...
        table9.iterations(k),table9.termination_reason(k));
end
fclose(fid);
status=struct('manuscript_date','2026-10-29','table8_rows',height(table8),'table9_rows',height(table9), ...
    'table8_origin','Submitted rounded comparison; no new Abaqus run.', ...
    'table9_fresh_inputs',~isempty(freshRoot),'no_archived_fallback_for_fresh_table9',true);
fid=fopen(fullfile(outputRoot,'submission_table_status.json'),'w');assert(fid>=0);
fprintf(fid,'%s',jsonencode(status));fclose(fid);
fprintf('Submitted tables: %d Abaqus comparison rows and %d sensitivity rows.\n',height(table8),height(table9));
end
