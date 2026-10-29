function report=mbeso_finalize_paper_exports(folder)
%MBESO_FINALIZE_PAPER_EXPORTS Bake approved manuscript sizes into saved panels.
% Paper sizes come from Word drawing extents, not misleading EMF frame units.
% Each file is processed once; rerunning does not compound font/size changes.
root=fileparts(mfilename('fullpath'));
if nargin<1,folder=root;end
profile=readtable(fullfile(root,'paper_output_profile.csv'),'TextType','string');
oldPath=path;guard=onCleanup(@()path(oldPath)); %#ok<NASGU>
addpath(root,fullfile(root,'figure_08'),...
    fullfile(root,'figure_09'),fullfile(root,'figure_06'));
rows=cell(0,7);madePaper=false;
for j=1:height(profile)
    stem=fullfile(root,char(profile.artifact(j)));
    if ~startsWith(stem,[char(folder) filesep]) || ~isfile([stem '.fig']),continue;end
    f=openfig([stem '.fig'],'new','invisible');
    cleanup=onCleanup(@()close(f));
    % A previous uniform export is already complete. Fresh native builds do
    % not carry this flag and still pass through the manuscript profile first.
    if isappdata(f,'MBESO_OutputSizeMode') && strcmp(getappdata(f,'MBESO_OutputSizeMode'),'uniform')
        clear cleanup;continue;
    end
    target=mbeso_panel_output_size(profile.artifact(j),'manuscript');
    already=isappdata(f,'MBESO_PaperProfileVersion');
    titles=findall(f,'Type','legend');needsRefresh=false;
    needsRefresh=~isappdata(f,'MBESO_PaperLegendVersion');
    for k=1:numel(titles),needsRefresh=needsRefresh||contains(string(titles(k).Title.String),'[MPa]');end
    if ~isappdata(f,'MBESO_PaperProfileVersion')
        a=findall(f,'Type','axes');lg=findall(f,'Type','legend');
        for k=1:numel(a),a(k).Units='normalized';end
        for k=1:numel(lg),lg(k).Units='normalized';end
        aPos=cell(numel(a),1);lPos=cell(numel(lg),1);
        for k=1:numel(a),aPos{k}=a(k).Position;end
        for k=1:numel(lg),lPos{k}=lg(k).Position;end
        % Capture original font sizes before parent properties update labels.
        h=findall(f,'-property','FontSize');base=zeros(numel(h),1);depth=base;factors=base;
        for k=1:numel(h)
            base(k)=h(k).FontSize;p=h(k);isLegend=false;
            while isgraphics(p)&&~isequal(p,f)
                isLegend=isLegend||strcmp(p.Type,'legend');depth(k)=depth(k)+1;p=p.Parent;
            end
            if isLegend,factors(k)=profile.legend_scale(j);else,factors(k)=profile.label_scale(j);end
        end
        f.Units='centimeters';pos=f.Position;f.Position=[pos(1:2) target];
        [~,order]=sort(depth);
        for k=order(:)',h(k).FontSize=base(k)*factors(k);end
        for k=1:numel(a),a(k).Position=aPos{k};end
        for k=1:numel(lg),lg(k).Position=lPos{k};end
        % The shared style applies the equal Fig. 9 plot rectangles below.
        f.PaperUnits='centimeters';f.PaperSize=target;
        f.PaperPosition=[0 0 target];f.PaperPositionMode='manual';f.Resize='on';
        drawnow;
        % Preserve readable text and keep framed legends inside the final page.
        for k=1:numel(lg)
            lg(k).Units='centimeters';p=lg(k).Position;
            p(1:2)=max([.04 .04],min(p(1:2),target-p(3:4)-.04));
            lg(k).Position=p;
        end
        for k=1:numel(a),a(k).Units='centimeters';end
        setappdata(f,'MBESO_PaperProfileVersion','2026-10-19');
        setappdata(f,'MBESO_PaperProfileSource',char(profile.reference(j)));
        setappdata(f,'MBESO_PaperProfileTargetCM',target);
    end
    mbeso_apply_lab_style(f);
    mbeso_place_paper_legends(f);
    set(findall(f,'Type','text'),'Color','black');
    set(findall(f,'Type','legend'),'TextColor','black');
    drawnow;
    if ~already || needsRefresh
        madePaper=true;
        savefig(f,[stem '.fig']);print(f,[stem '.png'],'-dpng','-r600');
        meta=export_exact_tnr_pdf(f,[stem '.pdf']);mbeso_export_emf(f,[stem '.emf']);
        fid=fopen([stem '_pdf_metadata.json'],'w','n','UTF-8');fprintf(fid,'%s',jsonencode(meta));fclose(fid);
    end
    f.PaperUnits='centimeters';err=max(abs(10*f.PaperSize-10*target));
    assert(err<1e-8,'The paper profile changed unexpectedly.');
    rows(end+1,:)={char(profile.artifact(j)),target(1)*10,target(2)*10, ...
        profile.label_scale(j),profile.legend_scale(j),err,true}; %#ok<AGROW>
    clear cleanup;
end
% The post-214 inset and composite are excluded from this revision.
report=cell2table(rows,'VariableNames',{'artifact','width_mm','height_mm','label_scale', ...
    'legend_scale','size_error_mm','passed'});
if ~isempty(rows),writetable(report,fullfile(folder,'paper_output_checks.csv'));end
fprintf('Manuscript-size exports: %d panels.\n',height(report));
mbeso_apply_output_size_mode(folder);
end
