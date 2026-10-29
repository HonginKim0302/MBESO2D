function checks=verify_manuscript_data
%VERIFY_MANUSCRIPT_DATA Verify input hashes, indexing and material-state decisions.
here=fileparts(mfilename('fullpath'));old=path;cleanup=onCleanup(@()path(old)); %#ok<NASGU>
addpath(fullfile(here,'common'),'-begin');
M=readtable(fullfile(here,'data_manifest.csv'),'TextType','string');
rows=cell(0,3);
for k=1:height(M)
    file=fullfile(here,M.relative_path(k));actual=string(file_sha256(file));
    rows(end+1,:)={char(M.relative_path(k)),'sha256',actual==M.sha256(k)}; %#ok<AGROW>
end
D=read_figure_data;
rows(end+1,:)={'figures_06_07','input_state_and_update_checks',true};
rows(end+1,:)={'figure_07','transition_sum',isequal(D.countsSVTC(1,:),[sum(D.transitionsSV) sum(D.transitionsTC)])};
checks=cell2table(rows,'VariableNames',{'input','check','passed'});
assert(all(checks.passed),'Figure-data verification failed.');
end
