% Open all panels of manuscript Figure 6.
reproductionRoot=fileparts(fileparts(mfilename('fullpath')));
addpath(reproductionRoot);
reproduce_manuscript_figures(true,{'Fig06_a','Fig06_b','Fig06_c','Fig06_d'});
