% Open every submitted numerical panel and write FIG, PNG, PDF and Windows EMF.
submittedFigureFolder=fileparts(mfilename('fullpath'));
addpath(submittedFigureFolder);
submittedFigureManifest=reproduce_submitted_figures(true);
disp(submittedFigureManifest);
