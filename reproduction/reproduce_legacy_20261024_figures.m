function manifest = reproduce_legacy_20261024_figures(showWindows)
%REPRODUCE_MANUSCRIPT_FIGURES Reproduce the numerical panels of the final paper.
% Plotting uses saved experiment arrays; it does not run a new optimization.
% Figure numbers refer to the manuscript revised on 20 October 2026.
if nargin<1,showWindows=false;end
here=fileparts(mfilename('fullpath'));
assert(~isfile(fullfile(here,'PREPARATION_INCOMPLETE.txt')), ...
    'This fresh-data bundle is incomplete.');
oldPath=path;guard=onCleanup(@()path(oldPath)); %#ok<NASGU>
addpath(here,'-begin');
mbeso_figure9_baseline_data(fullfile(here,'figure_09','data'),true);
verify_manuscript_data;
groups={'figure_06','figure_08','figure_09'};
for j=1:numel(groups)
    folder=fullfile(here,groups{j});addpath(folder,'-begin');
    previous=findall(groot,'Type','figure');
    switch groups{j}
        case 'figure_06',reproduce_figure4;
        case 'figure_08'
            reproduce_figure1;
            reproduce_figure1_no_highlights;
            reproduce_assignment_strip;
        case 'figure_09'
            reproduce_figure3;
            reproduce_figure9_baseline;
    end
    close(setdiff(findall(groot,'Type','figure'),previous));
    rmpath(folder);
end
% Internal renderer identifiers are retained for source provenance. Public
% filenames use only the final paper numbering; no Figure 10 is generated.
rows={
6,'c','figure_06/figures/Figure4_panel_c',true;
6,'d','figure_06/figures/Figure4_panel_d',true;
8,'a','figure_08/exports/figure1_panel_a',true;
8,'b','figure_08/exports/no_highlights/figure1_panel_b_no_highlights',true;
8,'c','figure_08/exports/no_highlights/figure1_panel_c_no_highlights',true;
9,'b','figure_09/panels/Figure3b',true;
9,'c','figure_09/panels/Figure3c',true;
9,'d','figure_09/panels/Figure3e',true;
9,'e','figure_09/exports/Fig09e',true;
9,'f_1','figure_09/exports/Fig09f_1',true;
9,'f_2','figure_09/exports/Fig09f_2',true;
8,'d','figure_08/exports/Fig08_panel_d',false;
8,'e','figure_08/exports/figure1_panel_e',false;
8,'b_highlights','figure_08/exports/figure1_panel_b',false;
8,'c_highlights','figure_08/exports/figure1_panel_c',false};
out=fullfile(here,'outputs');if ~isfolder(out),mkdir(out);end
optional=fullfile(out,'optional');if ~isfolder(optional),mkdir(optional);end
made=cell(size(rows,1),8);
for j=1:size(rows,1)
    destination=out;if ~rows{j,4},destination=optional;end
    stem=sprintf('Fig%02d_panel_%s',rows{j,1},rows{j,2});
    files=cell(1,4);extensions={'.fig','.png','.pdf','.emf'};
    if rows{j,4}
        export_manuscript_panel(fullfile(here,[rows{j,3} '.fig']), ...
            fullfile(destination,stem),rows{j,1},rows{j,2});
    end
    for k=1:4
        if k==4 && ~ispc,files{k}='';continue;end
        source=fullfile(here,[rows{j,3} extensions{k}]);
        assert(isfile(source),'Missing generated artifact: %s',source);
        target=fullfile(destination,[stem extensions{k}]);
        if ~rows{j,4},copyfile(source,target);end
        files{k}=strrep(erase(target,[here filesep]),filesep,'/');
    end
    made(j,:)=[rows(j,[1 2 4]),files,{rows{j,3}}];
    if showWindows && rows{j,4}
        f=openfig(fullfile(here,files{1}),'new','visible');
        set(f,'Resize','on','Name',sprintf('Manuscript Figure %d (%s)',rows{j,1},rows{j,2}), ...
            'NumberTitle','off');
    end
end
manifest=cell2table(made,'VariableNames', ...
    {'manuscript_figure','panel','numeric_panel','fig','png','pdf','emf','renderer_source'});
writetable(manifest,fullfile(here,'generated_artifacts.csv'));
fprintf('Final manuscript replay: 11 numerical panels and 4 optional illustrations/variants.\n');
end
