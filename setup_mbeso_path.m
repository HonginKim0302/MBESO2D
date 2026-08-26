% SPDX-License-Identifier: GPL-3.0-or-later
% Copyright (C) 2026 MBESO2D contributors
function setup_mbeso_path()
%SETUP_MBESO_PATH Add MBESO source and utility folders to the MATLAB path.

repo_root = fileparts(mfilename('fullpath'));
addpath(fullfile(repo_root, 'src'));
addpath(fullfile(repo_root, 'visualization'));
end
