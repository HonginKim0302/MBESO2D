% Run the small numerical verification suite.
here=fileparts(mfilename('fullpath'));
addpath(here);
verification_report=run_verification_experiments('smoke');
