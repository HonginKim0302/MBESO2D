function manifest = reproduce_manuscript_figures(showWindows)
%REPRODUCE_MANUSCRIPT_FIGURES Replay Figures 6 and 7 of the 29 October submission.
% This entry point redraws saved data; it performs no FE or optimization solve.
if nargin<1,showWindows=false;end
here=fileparts(mfilename('fullpath'));
assert(~isfile(fullfile(here,'PREPARATION_INCOMPLETE.txt')), ...
    'This fresh-data bundle is incomplete.');
oldPath=path;cleanup=onCleanup(@()path(oldPath)); %#ok<NASGU>
addpath(fullfile(here,'submission_20261029'),'-begin');
manifest=reproduce_submitted_figures(showWindows);
end
