function target=mbeso_panel_output_size(artifact,mode)
%MBESO_PANEL_OUTPUT_SIZE Physical canvas size, including explicit exceptions.
% Per-panel overrides apply in both size presets; they do not scale fonts.
root=fileparts(mfilename('fullpath'));
if nargin<2,mode=mbeso_output_size_mode;end
artifact=strrep(char(artifact),'\','/');
if strcmp(mode,'uniform')
    target=[8.3 6.4];
else
    profile=readtable(fullfile(root,'paper_output_profile.csv'),'TextType','string');
    row=find(strcmp(profile.artifact,artifact));assert(isscalar(row));
    target=[profile.width_mm(row) profile.height_mm(row)]/10;
end
file=fullfile(root,'output_size_overrides.csv');
if isfile(file)
    overrides=readtable(file,'TextType','string');
    row=find(strcmp(overrides.artifact,artifact));
    assert(numel(row)<=1,'Duplicate size override.');
    if ~isempty(row),target=[overrides.width_cm(row) overrides.height_cm(row)];end
end
end
