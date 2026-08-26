% SPDX-License-Identifier: GPL-3.0-or-later
% Copyright (C) 2026 MBESO2D contributors
function validation = run_all_validation(include_long_studies)
%RUN_ALL_VALIDATION Run release checks and the optional mesh study.

if nargin < 1 || isempty(include_long_studies)
    include_long_studies = false;
end
if ~isscalar(include_long_studies) || ...
        ~(islogical(include_long_studies) || isnumeric(include_long_studies))
    error('include_long_studies must be a logical or numeric scalar.');
end
include_long_studies = logical(include_long_studies);

validation_root = fileparts(mfilename('fullpath'));
addpath(validation_root);

validation = struct();
validation.regression = run_regression_checks();
validation.mesh_independence = table();

if include_long_studies
    validation.mesh_independence = run_mesh_independence();
end
end
