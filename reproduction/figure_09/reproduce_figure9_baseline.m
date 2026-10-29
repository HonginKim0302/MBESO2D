function figures=reproduce_figure9_baseline(showFigures)
%REPRODUCE_FIGURE9_BASELINE Restore pre-termination histories from phase maps.
% Fig. 9(e): actual domain fractions, states 1--214.
% Fig. 9(f-1): per-update transitions, updates 2--214.
% Fig. 9(f-2): the same unsmoothed counts, updates 195--214, smaller canvas.
% All three panels use the baseline case (delta_sigma = 0 MPa).
% No solver execution or post-214 continuation is required.
if nargin<1,showFigures=false;end
folder=fileparts(mfilename('fullpath'));root=fileparts(folder);
oldPath=path;guard=onCleanup(@()path(oldPath)); %#ok<NASGU>
addpath(root,folder,'-begin');
P=mbeso_figure9_baseline_data(fullfile(folder,'data'),true);
stateRows=2:215;
palette=mbeso_reproduction_palette;
output=fullfile(folder,'exports');if ~isfolder(output),mkdir(output);end
figures=gobjects(3,1);names={'Fig09e','Fig09f_1','Fig09f_2'};
referenceSizes=[8.3 6.4;8.3 6.4;6.2 4.8];
% Approved physical canvases; font point sizes are retained at every size.
sizes=[8.3 6.4;6.64 4.48;3.72 3.36];
layout=jsondecode(fileread(fullfile(root,'fig10_panel_layout.json')));
for j=1:3
    sz=sizes(j,:);fs=9;ls=9.5;lgs=8;
    box=layout.axes_cm(:)';
    if j==3,box=[1.18 1.00 4.67 3.43];fs=8;ls=8.5;lgs=7.5;end
    canvasScale=sz./referenceSizes(j,:);box=box.*[canvasScale canvasScale];
    f=figure('Visible','off','Color','white','Name',names{j},'NumberTitle','off', ...
        'Units','centimeters','Position',[2 2 sz],'Resize','on','Renderer','painters', ...
        'DefaultAxesFontName','Times New Roman','DefaultTextFontName','Times New Roman');
    figures(j)=f;
    set(f,'PaperUnits','centimeters','PaperSize',sz,'PaperPosition',[0 0 sz],'PaperPositionMode','manual','InvertHardcopy','off');
    a=axes(f,'Units','centimeters','Position',box,'Tag',names{j}, ...
        'FontName','Times New Roman','FontSize',fs,'LineWidth',.6, ...
        'PositionConstraint','innerposition','Color','white');hold(a,'on');
    xlabel(a,'Iteration','FontSize',ls);a.XLabel.FontName='Times New Roman';
    if j==1
        x=(1:214)';markers=unique([1 10:10:210 214]);
        h(1)=plot(a,x,100*P.solid_fraction(stateRows),'Color',[.48 .48 .48], ...
            'LineWidth',.9,'Marker','o','MarkerIndices',markers,'MarkerSize',2.8,'MarkerFaceColor','white','Tag','actual_solid');
        h(2)=plot(a,x,100*P.V1(stateRows),'Color',palette.tensile, ...
            'LineWidth',.9,'Marker','^','MarkerIndices',markers,'MarkerSize',2.8,'MarkerFaceColor','white','Tag','b_tensile');
        h(3)=plot(a,x,100*P.V2(stateRows),'Color',palette.compressive, ...
            'LineWidth',.9,'Marker','v','MarkerIndices',markers,'MarkerSize',2.8,'MarkerFaceColor','white','Tag','b_compressive');
        xlim(a,[1 214]);xticks(a,[1 50 100 150 214]);ylim(a,[0 100]);yticks(a,0:20:100);
        ylabel(a,'Domain fraction (%)','FontSize',ls);
        lg=legend(a,h,{'Actual solid','V_1 (tensile)','V_2 (compressive)'},'Location','northeast');
    else
        if j==2,x=(2:214)';else,x=(195:214)';end
        h=gobjects(2,1);
        h(1)=plot(a,x,P.N_TC(x),'Color',[.72 .47 .10],'LineWidth',.8,'Tag','material_transitions');
        h(2)=plot(a,x,P.N_SV(x),'Color',[.48 .48 .48],'LineWidth',.8,'Tag','solid_void_transitions');
        if j==2
            xlim(a,[2 214]);xticks(a,[2 50 100 150 195 214]);ylim(a,[0 1200]);yticks(a,0:300:1200);
        else
            set(h(1),'Marker','s','MarkerSize',3,'MarkerFaceColor','white');
            set(h(2),'Marker','o','MarkerSize',3,'MarkerFaceColor','white');
            xlim(a,[195 214]);xticks(a,[195 200 205 210 214]);ylim(a,[0 10]);yticks(a,0:2:10);
        end
        ylabel(a,'Changed elements','FontSize',ls);
        if j==2
            labels={sprintf('Material\n(total: %s)',commaInteger(P.full_transition_totals(1))), ...
                sprintf('Solid-void\n(total: %s)',commaInteger(P.full_transition_totals(2)))};
            lg=legend(a,h,labels,'Location','northeast','NumColumns',1);
            lg.Title.String='';
            lg.Title.FontSize=7.5;lg.Title.FontWeight='normal';
            setappdata(f,'MBESO_Fig9TotalsVersion','2-214-v3-wrapped');
        else
            lg=legend(a,h,{'Material','Solid-void'},'Location','northeast','NumColumns',2);
        end
    end
    lg.FontName='Times New Roman';lg.FontSize=lgs;lg.ItemTokenSize=[12 8];lg.LineWidth=.6;
    lg.Box='on';lg.EdgeColor='black';lg.TextColor='black';lg.Color='white';lg.AutoUpdate='off';
    if j==2,lg.Title.FontName='Times New Roman';lg.Title.FontSize=7.5;lg.Title.FontWeight='normal';lg.Title.Color='black';end
    if j==3,lg.ItemTokenSize=[9 7];end
    set(findall(f,'Type','text'),'FontName','Times New Roman','Color','black');
    mbeso_apply_lab_style(f);a.YTickLabel=compose('%d',a.YTick);a.Position=box;drawnow;
    if j==2,mbeso_mark_fig9_zoom_start(f);end
    if j==3,mbeso_layout_fig9_zoom(f);end
    % Freeze the approved legend rectangle before native popup placement.
    lg.Units='centimeters';legendBox=lg.Position;lg.Position=legendBox;drawnow;
    setappdata(f,'MBESO_PaperProfileVersion','2026-10-23');
    setappdata(f,'MBESO_PaperLegendVersion','2026-10-23');
    setappdata(f,'MBESO_PaperProfileTargetCM',sz);
    setappdata(f,'MBESO_BaselineHistoryProvenance',rmfield(P,{'solid_count','tensile_count','compressive_count', ...
        'solid_fraction','V1','V2','N_TC','N_SV','states','updates'}));
    stem=fullfile(output,names{j});savefig(f,[stem '.fig']);
    print(f,[stem '.png'],'-dpng','-r600');
    pdfmeta=export_exact_tnr_pdf(f,[stem '.pdf']);mbeso_export_emf(f,[stem '.emf']);
    writeJson(pdfmeta,[stem '_pdf_metadata.json']);
    clear h;
end
summary=struct('baseline_epsilon_MPa',0,'source_file',P.source_file, ...
    'volume_state_range',[1 214],'full_transition_update_range',[2 214], ...
    'zoom_update_range',[195 214],'TC_full',sum(P.N_TC(2:214)),'SV_full',sum(P.N_SV(2:214)), ...
    'TC_zoom',sum(P.N_TC(195:214)),'SV_zoom',sum(P.N_SV(195:214)), ...
    'final_actual_solid_percent',100*P.solid_fraction(end), ...
    'final_V1_percent',100*P.V1(end),'final_V2_percent',100*P.V2(end), ...
    'smoothing',false,'post_214_included',false,'canvas_cm',sizes);
writeJson(summary,fullfile(folder,'data','baseline_summary.json'));
if showFigures,set(figures,'Visible','on');else,close(figures);figures=gobjects(0);end
fprintf('Fig. 9(e,f): three native MATLAB panels exported; full transition totals TC=%d, SV=%d.\n',P.full_transition_totals);
end

function text=commaInteger(value)
% Display totals computed from records; no manually typed figure numbers.
text=sprintf('%d',value);
for k=numel(text)-3:-3:1,text=[text(1:k) ',' text(k+1:end)];end
end
function writeJson(value,file)
fid=fopen(file,'w','n','UTF-8');assert(fid>=0);guard=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s',jsonencode(value,'PrettyPrint',true));
end
