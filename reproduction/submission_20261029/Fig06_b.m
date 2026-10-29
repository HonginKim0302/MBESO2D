% Reconstruct the submitted state-10 layout and first ten material assignments.
submittedFigureFolder=fileparts(mfilename('fullpath'));
addpath(submittedFigureFolder);
submittedAssignmentManifest=reproduce_submitted_assignment(true);
