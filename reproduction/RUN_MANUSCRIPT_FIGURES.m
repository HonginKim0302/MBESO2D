% Reproduce the numerical graphs of submitted Figures 6 and 7 (29 October 2026).
% Reads stored experimental data; no FE analysis or optimization is rerun.
showWindows=true;
reproductionRoot=fileparts(mfilename('fullpath'));
addpath(reproductionRoot);
reproduce_manuscript_figures(showWindows);
