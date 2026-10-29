function checks=verify_submitted_figures()
%VERIFY_SUBMITTED_FIGURES Compare plotted native arrays with this run's inputs.
% Checks are valid for recorded and fresh-history reproduction bundles.
here=fileparts(mfilename('fullpath'));
L=load(fullfile(here,'generated_inputs','plotted_data.mat'),'D');D=L.D;
ids=submitted_panel_ids();rows=cell(0,4);
for k=1:numel(ids)
    panel=ids{k};stem=fullfile(here,'outputs',panel);
    formats={'fig','png','pdf'};if ispc,formats{end+1}='emf';end
    for j=1:numel(formats)
        info=dir([stem '.' formats{j}]);passed=~isempty(info) && info.bytes>0;
        rows(end+1,:)={panel,['file_' formats{j}],double(~passed),passed}; %#ok<AGROW>
    end
    fig=openfig([stem '.fig'],'invisible');cleaner=onCleanup(@()close(fig));
    specs=expectedLines(panel,D);
    for j=1:size(specs,1)
        h=findobj(fig,'Tag',specs{j,1});assert(isscalar(h),'Expected one tagged series.');
        actualX=double(h.XData(:)); actualY=double(h.YData(:));
        expectedX=double(specs{j,2}(:));expectedY=double(specs{j,3}(:));
        if ~isequal(size(actualX),size(expectedX)) || ~isequal(size(actualY),size(expectedY)),err=Inf;
        else,err=max([abs(actualX-expectedX);abs(actualY-expectedY)]);end
        rows(end+1,:)={panel,specs{j,1},err,err<1e-10}; %#ok<AGROW>
    end
    if any(strcmp(panel,{'Fig07_d','Fig07_e'}))
        if strcmp(panel,'Fig07_d'),expected=D.countsSVTC;else,expected=D.layoutSVTC;end
        for j=1:2
            h=findobj(fig,'Tag',sprintf('%s_series_%d',panel,j));
            err=max(abs(double(h.YData(:))-expected(:,j)));
            rows(end+1,:)={panel,sprintf('bar_series_%d',j),err,err<1e-10}; %#ok<AGROW>
        end
    end
    info=imfinfo([stem '.png']);expectedHeight=2500;
    if endsWith(panel,'_zoom'),expectedHeight=1875;end
    err=max(abs([info.Width info.Height]-[3500 expectedHeight]));
    rows(end+1,:)={panel,'png_600dpi_dimensions',err,err==0}; %#ok<AGROW>
    clear cleaner
end
err=max(abs(D.solid-D.tensile-D.compressive));
rows(end+1,:)={'inputs','phase_volume_sum',err,err<1e-10};
err=max(abs(D.countsSVTC(1,:)-[sum(D.transitionsSV),sum(D.transitionsTC)]));
rows(end+1,:)={'inputs','all_214_transition_updates',err,err==0};
rows(end+1,:)={'inputs','final_state_214',double(D.state(end)~=214),D.state(end)==214};
checks=cell2table(rows,'VariableNames',{'panel','check','maximum_absolute_error','passed'});
writetable(checks,fullfile(here,'verification_checks.csv'));
assert(all(checks.passed),'Submitted figure verification failed; see verification_checks.csv.');
end

function specs=expectedLines(panel,D)
specs=cell(0,3);
switch panel
    case 'Fig06_a'
        specs={'compliance',D.state,D.C;'normalization_coefficient',D.state,D.nk};
    case 'Fig06_c'
        specs={'unfiltered_stress',D.local_update,D.rawStress;'filtered_stress',D.local_update,D.filteredStress};
    case 'Fig06_d'
        specs={'history_score_974',D.local_update,D.score974;'history_score_5829',D.local_update,D.score5829; ...
            'retention_threshold',D.local_update,D.threshold};
    case 'Fig07_a'
        specs={'solid_volume_percent',D.update,D.solid;'tensile_volume_percent',D.update,D.tensile; ...
            'compressive_volume_percent',D.update,D.compressive};
    case {'Fig07_b','Fig07_b_zoom'}
        pick=true(size(D.update));if endsWith(panel,'_zoom'),pick=D.update>=195 & D.update<=214;end
        specs={'solid_void_transitions',D.update(pick),D.transitionsSV(pick); ...
            'tensile_compressive_transitions',D.update(pick),D.transitionsTC(pick)};
    case {'Fig07_c','Fig07_c_zoom'}
        pick=true(size(D.state));if endsWith(panel,'_zoom'),pick=D.state>=195 & D.state<=214;end
        for j=1:5,specs(end+1,:)={sprintf('deadband_case_%d',j),D.state(pick),D.deadband(pick,j)};end %#ok<AGROW>
end
end
