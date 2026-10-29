function palette = mbeso_reproduction_palette
%MBESO_REPRODUCTION_PALETTE Read the release material convention without FE paths.
% Fresh standalone replay bundles carry a snapshot of this one source helper.
here = fileparts(mfilename('fullpath'));
helper = fullfile(fileparts(here),'src','mbeso_material_palette.m');
if ~isfile(helper)
    helper = fullfile(here,'support','mbeso_material_palette.m');
end
assert(isfile(helper),'The shared material palette is missing from this replay bundle.');
oldPath = path;
restore = onCleanup(@()path(oldPath)); %#ok<NASGU>
addpath(fileparts(helper),'-begin');
assert(strcmp(which('mbeso_material_palette'),helper),'Unexpected material palette on the MATLAB path.');
palette = mbeso_material_palette;
end
