% Open all panels of manuscript Figure 7.
reproductionRoot=fileparts(fileparts(mfilename('fullpath')));
addpath(reproductionRoot);
reproduce_manuscript_figures(true,{'Fig07_a','Fig07_b','Fig07_b_zoom','Fig07_c','Fig07_c_zoom','Fig07_d','Fig07_e'});
