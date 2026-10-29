% Quick interface checks; see README.md for complete paper-sized experiments.
% SPDX-License-Identifier: GPL-3.0-or-later
review_entry_folder = fileparts(mfilename('fullpath'));
review_previous_path = path;
review_restore_path = onCleanup(@()path(review_previous_path));
addpath(review_entry_folder);
review_validation_report = run_review_experiments('smoke');
clear review_restore_path review_previous_path review_entry_folder
