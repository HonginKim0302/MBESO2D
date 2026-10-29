function [figures, checks] = reproduce_figure1_no_highlights(outputDir)
%REPRODUCE_FIGURE1_NO_HIGHLIGHTS Export b/c with only event circles removed.
% Uses the existing editable FIG files and verifies the retained plot against
% both the source FIG and data/plot_inputs.mat. No FE/optimization is rerun.
here=fileparts(mfilename('fullpath'));
if nargin<1 || isempty(outputDir),outputDir=fullfile(here,'exports','no_highlights');end
if ~isfolder(outputDir),mkdir(outputDir);end
oldPath=path;pathGuard=onCleanup(@()path(oldPath)); %#ok<NASGU>
addpath(here,'-begin');
addpath(fileparts(here),'-begin');
loaded=load(fullfile(here,'data','plot_inputs.mat'),'P');P=loaded.P;
figures=struct();checks=cell(0,4);
for panel={'b','c'}
    id=panel{1};source=fullfile(here,'exports',['figure1_panel_' id '.fig']);
    assert(isfile(source),'Missing original FIG: %s',source);
    fig=openfig(source,'new','invisible');drawnow;
    figures.(id)=fig;
    pattern=['^event_' id '_state[0-9]+$'];
    highlights=findall(fig,'Type','line','-regexp','Tag',pattern);
    expected=P.events(strcmp({P.events.panel},id));
    expectedTags=arrayfun(@(e)sprintf('event_%s_state%d',id,e.state_iteration), ...
        expected,'UniformOutput',false);
    actualTags=arrayfun(@(h)h.Tag,highlights,'UniformOutput',false);
    assert(isequal(sort(expectedTags(:)),sort(actualTags(:))), ...
        'Source highlight tags do not match saved event annotations.');
    for j=1:numel(highlights)
        h=highlights(j);
        assert(strcmp(h.Marker,'o') && numel(h.XData)==1 && ...
            isequal(h.Color,[.90 .40 .06]),'Unexpected event annotation style.');
    end
    originalObjects=findall(fig);
    retained=originalObjects(~ismember(originalObjects,highlights));
    before=capture_properties(retained);
    delete(highlights);drawnow;
    remaining=findall(fig);
    checks(end+1,:)={['panel_' id '_only_event_objects_removed'], ...
        double(~(numel(remaining)==numel(retained) && ...
        all(ismember(remaining,retained)) && all(isgraphics(retained)))),0,[]}; %#ok<AGROW>
    checks(end+1,:)={['panel_' id '_removed_expected_highlight_count'], ...
        abs(numel(originalObjects)-numel(remaining)-numel(expected)),0,[]}; %#ok<AGROW>
    checks(end+1,:)={['panel_' id '_event_objects_remaining'], ...
        numel(findall(fig,'-regexp','Tag',pattern)),0,[]}; %#ok<AGROW>
    checks=[checks;compare_properties(before,capture_properties(retained),id,'after_removal')]; %#ok<AGROW>
    checks=[checks;check_saved_arrays(fig,P,id)]; %#ok<AGROW>

    stem=fullfile(outputDir,['figure1_panel_' id '_no_highlights']);
    savefig(fig,[stem '.fig']);
    print(fig,[stem '.png'],'-dpng','-r600');
    meta=export_exact_tnr_pdf(fig,[stem '.pdf']);
    mbeso_export_emf(fig,[stem '.emf']);
    fid=fopen([stem '_pdf_metadata.json'],'w','n','UTF-8');assert(fid>=0);
    fprintf(fid,'%s',jsonencode(meta));fclose(fid);
    checks=[checks;compare_properties(before,capture_properties(retained),id,'after_export')]; %#ok<AGROW>

    % Check the delivered native FIG as well as the live export source.
    saved=openfig([stem '.fig'],'new','invisible');drawnow;
    savedGuard=onCleanup(@()close_if_valid(saved));
    checks=[checks;compare_properties(before,capture_properties(findall(saved)),id,'saved_fig')]; %#ok<AGROW>
    checks=[checks;check_saved_arrays(saved,P,[id '_saved'])]; %#ok<AGROW>
    checks(end+1,:)={['panel_' id '_saved_fig_event_objects_remaining'], ...
        numel(findall(saved,'-regexp','Tag',pattern)),0,[]}; %#ok<AGROW>
    clear savedGuard;
end
for j=1:size(checks,1),checks{j,4}=checks{j,2}<=checks{j,3};end
fid=fopen(fullfile(outputDir,'no_highlights_verification.csv'),'w','n','UTF-8');assert(fid>=0);
guard=onCleanup(@()fclose(fid));
fprintf(fid,'check_id,max_absolute_difference,tolerance,passed\n');
for j=1:size(checks,1),fprintf(fid,'%s,%.17g,%.17g,%d\n',checks{j,:});end
clear guard;
assert(all(cell2mat(checks(:,4))),'No-highlight verification failed; see CSV.');
fprintf('Figure 1(b,c) without highlight circles: %s\n',outputDir);
fprintf('All %d verification checks passed.\n',size(checks,1));
end

function snapshots=capture_properties(objects)
% Use handle-free records so the saved/reopened FIG can also be compared.
groups={ ...
    'data',{'XData','YData','ZData','Value'}; ...
    'geometry',{'Units','Position','InnerPosition','OuterPosition', ...
        'PositionConstraint','XLim','YLim','ZLim','XTick','YTick','ZTick', ...
        'XScale','YScale','ZScale','XDir','YDir','ZDir','DataAspectRatio', ...
        'PlotBoxAspectRatio','Location','Orientation','NumColumns','ItemTokenSize'}; ...
    'paper',{'PaperUnits','PaperSize','PaperPosition','PaperPositionMode','PaperType'}; ...
    'fonts',{'FontName','FontSize','FontUnits','FontWeight','FontAngle', ...
        'Interpreter','TickLabelInterpreter'}; ...
    'style',{'Color','TextColor','XColor','YColor','ZColor','LineStyle','LineWidth', ...
        'Marker','MarkerSize','MarkerIndices','MarkerFaceColor','MarkerEdgeColor', ...
        'String','DisplayName','HandleVisibility','Box','EdgeColor','TickDir', ...
        'TickLength','GridColor','GridAlpha','XGrid','YGrid','ZGrid'}};
snapshots=struct();
for g=1:size(groups,1)
    records=cell(0,1);properties=groups{g,2};
    for k=1:numel(objects)
        h=objects(k);record=struct('class',class(h),'Tag',h.Tag);included=false;
        for p=1:numel(properties)
            key=properties{p};
            if isprop(h,key)
                record.(key)=get(h,key);included=true;
            end
        end
        if included,records{end+1,1}=jsonencode(record);end %#ok<AGROW>
    end
    snapshots.(groups{g,1})=sort(records);
end
end

function checks=compare_properties(before,after,id,stage)
groups=fieldnames(before);checks=cell(numel(groups),4);
for j=1:numel(groups)
    name=groups{j};tolerance=0;
    % MATLAB's PDF export can round the OS window frame by ~1e-15 cm.
    % Canvas/axes/legend geometry is checked to 1e-12; data stays exact.
    if strcmp(name,'geometry'),tolerance=1e-12;end
    checks(j,:)={['panel_' id '_' stage '_' name '_identical'], ...
        property_difference(before.(name),after.(name)),tolerance,[]};
end
end

function delta=property_difference(before,after)
delta=0;
if numel(before)~=numel(after),delta=Inf;return;end
for k=1:numel(before)
    a=jsondecode(before{k});b=jsondecode(after{k});keys=fieldnames(a);
    if ~isequal(keys,fieldnames(b)),delta=Inf;return;end
    for p=1:numel(keys)
        x=a.(keys{p});y=b.(keys{p});
        if isequaln(x,y),continue;end
        if isnumeric(x) && isnumeric(y) && isequal(size(x),size(y)) && ...
                all(isfinite(x),'all') && all(isfinite(y),'all')
            delta=max(delta,max(abs(x-y),[],'all'));
        else
            delta=Inf;return;
        end
    end
end
end

function checks=check_saved_arrays(fig,P,id)
d=mbeso_figure1_update_data(P);
if startsWith(id,'b')
    tags={'trace_raw_974_MPa','trace_filtered_974_MPa'};
else
    tags={'eta_raw_974','eta_spatial_974','eta_temporal_974', ...
        'selection_cutoff','eta_temporal_5829'};
end
checks=cell(0,4);
for j=1:numel(tags)
    h=findall(fig,'Type','line','Tag',tags{j});
    assert(isscalar(h),'Expected one saved data curve: %s',tags{j});
    checks(end+1,:)={['panel_' id '_' tags{j} '_XData_matches_plot_inputs'], ...
        double(~isequaln(h.XData(:),d.decision_update(:))),0,[]}; %#ok<AGROW>
    checks(end+1,:)={['panel_' id '_' tags{j} '_YData_matches_plot_inputs'], ...
        double(~isequaln(h.YData(:),d.(tags{j})(:))),0,[]}; %#ok<AGROW>
end
raw=findall(fig,'Type','line','Tag',tags{1});
checks(end+1,:)={['panel_' id '_normal_circular_curve_markers_preserved'], ...
    double(~strcmp(raw.Marker,'o')),0,[]};
end

function close_if_valid(fig)
if isgraphics(fig),close(fig);end
end
