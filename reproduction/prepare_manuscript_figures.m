function bundle=prepare_manuscript_figures(freshRoot,bundle)
%PREPARE_MANUSCRIPT_FIGURES Build a standalone figure bundle from actual histories.
% Run the verification histories first. All inputs are derived from those records;
% missing files cause an error rather than substitution of publication data.
here=fileparts(mfilename('fullpath'));
if nargin<1||isempty(freshRoot),error('Supply the output root of a verification-history run.');end
freshRoot=char(java.io.File(freshRoot).getCanonicalPath());
if nargin<2||isempty(bundle),bundle=fullfile(freshRoot,'manuscript_figures');end
bundle=char(java.io.File(bundle).getCanonicalPath());
assert(~strcmpi(bundle,here) && ~startsWith(lower(bundle),[lower(here) filesep]), ...
    'Create the bundle outside the source reproduction folder.');
assert(~isfolder(bundle),'Choose a new output folder; existing bundles are preserved.');
required={fullfile('initial10','cantilever','full_history.mat')};
ids={'cantilever_eps_0','cantilever_eps_0p005','cantilever_eps_0p05','cantilever_eps_0p5','cantilever_eps_5'};
for k=1:numel(ids)
    required=[required,{fullfile('zero_history',ids{k},'full_history.mat'), ...
        fullfile('zero_history',ids{k},'state_history.csv')}]; %#ok<AGROW>
end
missing=required(~cellfun(@(p)isfile(fullfile(freshRoot,p)),required));
assert(isempty(missing),'Required history records are missing: %s',strjoin(missing,', '));
mkdir(bundle);copySources(here,bundle);
marker=fullfile(bundle,'PREPARATION_INCOMPLETE.txt');fid=fopen(marker,'w');assert(fid>=0);
fprintf(fid,'Data preparation has not completed. Do not use this bundle.\n');fclose(fid);
palette=fullfile(fileparts(here),'src','mbeso_material_palette.m');
if ~isfile(palette),palette=fullfile(here,'support','mbeso_material_palette.m');end
assert(isfile(palette),'The shared material palette is missing.');
mkdir(fullfile(bundle,'support'));copyfile(palette,fullfile(bundle,'support','mbeso_material_palette.m'));
old=path;cleanup=onCleanup(@()path(old)); %#ok<NASGU>
addpath(fullfile(here,'common'),fullfile(here,'preparation'),'-begin');
prepare_figure_06_data(freshRoot,fullfile(bundle,'figure_06','data'));
prepare_figure_07_data(freshRoot,fullfile(bundle,'figure_07','data'));
write_data_manifest(bundle);
status=struct('source_mode','fresh_history','required_source_files',{required}, ...
    'description','Figure inputs derived from the supplied verification histories; no publication-data fallback.');
fid=fopen(fullfile(bundle,'data_source.json'),'w');assert(fid>=0);
fprintf(fid,'%s\n',jsonencode(status,'PrettyPrint',true));fclose(fid);
delete(marker);
fprintf('Figure inputs prepared: %s\n',bundle);
fprintf('Run the RUN_MANUSCRIPT_FIGURES.m in this bundle to plot its histories.\n');
end

function copySources(source,target)
items=dir(source);
for k=1:numel(items)
    item=items(k);if startsWith(item.name,'.'),continue;end
    input=fullfile(source,item.name);output=fullfile(target,item.name);
    if item.isdir
        if any(strcmp(item.name,{'outputs','support'})),continue;end
        mkdir(output);copySources(input,output);
    elseif endsWith(item.name,{'.m','.md'})
        copyfile(input,output);
    end
end
end
