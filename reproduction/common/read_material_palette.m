function palette=read_material_palette
%READ_MATERIAL_PALETTE Resolve the repository's categorical material colors.
root=fileparts(fileparts(mfilename('fullpath')));
helper=fullfile(fileparts(root),'src','mbeso_material_palette.m');
if ~isfile(helper),helper=fullfile(root,'support','mbeso_material_palette.m');end
assert(isfile(helper),'The shared material palette is missing.');
old=path;cleanup=onCleanup(@()path(old)); %#ok<NASGU>
addpath(fileparts(helper),'-begin');
assert(strcmp(which('mbeso_material_palette'),helper),'Unexpected palette on the MATLAB path.');
palette=mbeso_material_palette;
end
