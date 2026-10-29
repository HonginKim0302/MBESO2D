function checks=refresh_material_palette_figures(regenerate)
%REFRESH_MATERIAL_PALETTE_FIGURES Check the current manuscript color convention.
if nargin<1,regenerate=true;end
here=fileparts(mfilename('fullpath'));
oldPath=path;guard=onCleanup(@()path(oldPath)); %#ok<NASGU>
addpath(here,'-begin');
if regenerate,reproduce_manuscript_figures(false);end
checks=verify_manuscript_outputs;
end
