% Table 10: recompute the baseline and three additional deadband endpoints.
% Half-widths are 0, 0.05, 0.5 and 5 MPa; each uses its own response stop.
% This does not substitute Figure 9's common-iteration-214 responses.
% SPDX-License-Identifier: GPL-3.0-or-later
review_entry_folder = fileparts(mfilename('fullpath'));
review_previous_path = path;
review_restore_path = onCleanup(@()path(review_previous_path));
addpath(review_entry_folder);
review_deadband_report = run_review_experiments('deadband_extension');
clear review_restore_path review_previous_path review_entry_folder
