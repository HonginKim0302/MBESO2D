function [figures, P] = reproduce_figure1(outputDir)
%REPRODUCE_FIGURE1 Portable figure reproduction from this folder's saved data.
% No external repository, FE solver, or optimization execution is required.
here=fileparts(mfilename('fullpath'));
originalPath=path;pathGuard=onCleanup(@()path(originalPath)); %#ok<NASGU>
addpath(fileparts(here),'-begin');
materialPalette=mbeso_reproduction_palette();
if nargin<1 || isempty(outputDir), outputDir=fullfile(here,'exports'); end
if ~isfolder(outputDir), mkdir(outputDir); end
loaded=load(fullfile(here,'data','plot_inputs.mat'),'P'); P=loaded.P;
P.material_palette=materialPalette;
P.material.colors=materialPalette.map;
assert(isequal(P.response.state_iteration,(0:214)'));
assert(isequal(P.local.state_iteration,(0:10)'));
assert(isequal(P.local.decision_update,P.local.state_iteration+1));
assert(isequal(size(P.material.phase),[60 100]));
figures=struct();
canvas=P.canvas_mm; rectPx=P.axes_rect_pixels_top_origin;
rects=zeros(4,4);
for j=1:4
    rects(j,:)=[rectPx(j,1)/893*canvas(1), ...
        (1003-rectPx(j,2)-rectPx(j,4))/1003*canvas(2), ...
        rectPx(j,3)/893*canvas(1),rectPx(j,4)/1003*canvas(2)];
end
figures.combined=new_figure(canvas,'Figure 1: saved cantilever data');
for j=1:4
    ax=new_axes(figures.combined,rects(j,:),P);
    draw_panel(ax,P.panel_names{j},P);
end
export_figure(figures.combined,fullfile(outputDir,'figure1_combined'));

% Fixed margins are added around the unchanged physical plot rectangle.
% The deliberately empty panel-d area is retained only in the combined page.
standaloneMargins=[17 17 18 5;17 17 5 5;17 17 5 5;3 3 3 8]; % left,bottom,right,top mm
dimensions=cell(0,10);
for j=1:4
    name=P.panel_names{j}; r=rects(j,:); margin=standaloneMargins(j,:);
    page=[margin(1)+r(3)+margin(3),margin(2)+r(4)+margin(4)];
    fig=new_figure(page,['Figure 1 panel ' name]);
    ax=new_axes(fig,[margin(1),margin(2),r(3),r(4)],P);
    draw_panel(ax,name,P);
    figures.(name)=fig;
    export_figure(fig,fullfile(outputDir,['figure1_panel_' name]));
    dimensions(end+1,:)={name,r(1),r(2),r(3),r(4),page(1),page(2),P.font_size_pt,P.label_font_size_pt,600}; %#ok<AGROW>
end
fid=fopen(fullfile(outputDir,'panel_dimensions.csv'),'w','n','UTF-8'); guard=onCleanup(@()fclose(fid));
fprintf(fid,'panel,combined_x_mm,combined_y_from_bottom_mm,axis_width_mm,axis_height_mm,standalone_page_width_mm,standalone_page_height_mm,font_pt,label_font_pt,png_dpi\n');
for j=1:size(dimensions,1), fprintf(fid,'%s,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%d\n',dimensions{j,:}); end
clear guard;
verify_rendered(figures,P,rects,outputDir);
mbeso_finalize_paper_exports(here);
fprintf('Figure1 reproduction complete: %s\n',outputDir);
end

function fig=new_figure(mm,name)
fig=figure('Visible','off','Color','white','Units','centimeters', ...
    'Position',[1 1 mm/10],'Name',name,'NumberTitle','off','Renderer','painters', ...
    'PaperUnits','centimeters','PaperSize',mm/10,'PaperPosition',[0 0 mm/10], ...
    'PaperPositionMode','manual','InvertHardcopy','off');
end
function ax=new_axes(fig,mm,P)
ax=axes('Parent',fig,'Units','centimeters','Position',mm/10,'PositionConstraint','innerposition', ...
    'FontName',P.font_name,'FontSize',P.font_size_pt,'LineWidth',0.65,'Box','off', ...
    'TickDir','out','TickLength',[0.018 0.018],'XColor',[0 0 0],'YColor',[0 0 0], ...
    'LabelFontSizeMultiplier',P.label_font_size_pt/P.font_size_pt,'TitleFontSizeMultiplier',1, ...
    'XGrid','off','YGrid','on','GridAlpha',0.13,'MinorGridAlpha',0.08);
hold(ax,'on');
end
function draw_panel(ax,name,P)
switch name
    case 'a', draw_a(ax,P);
    case 'b', draw_b(ax,P);
    case 'c', draw_c(ax,P);
case 'e', draw_e(ax,P);
end
ax.Tag=['panel_' name];
for j=1:numel(P.events)
    e=P.events(j);
    if strcmp(e.panel,name)
        plot(ax,e.decision_update,e.value,'o','Color',[0.90 0.40 0.06], ...
            'MarkerSize',8.5,'LineWidth',1.1,'HandleVisibility','off', ...
            'Tag',sprintf('event_%s_state%d',name,e.state_iteration));
    end
end
end
function draw_a(ax,P)
d=P.response; m=find(ismember(d.state_iteration,d.marked_states));
yyaxis(ax,'left');
% The shaded interval identifies the ten updates expanded in panels (b,c).
patch(ax,[0 10 10 0],[0 0 6 6],[.86 .86 .86], ...
    'EdgeColor',[.55 .55 .55],'LineWidth',.6,'HandleVisibility','off', ...
    'Tag','initial_ten_updates');
h(1)=plot(ax,d.state_iteration,d.Vk,'-o','Color',[0 0 0],'MarkerFaceColor','white','MarkerSize',3.5, ...
    'MarkerIndices',m,'LineWidth',0.85,'Tag','Vk','DisplayName','V_k');
h(2)=plot(ax,d.state_iteration,d.nk,'-s','Color',[0.53 0.53 0.53],'MarkerFaceColor','white','MarkerSize',3.5, ...
    'MarkerIndices',m,'LineWidth',0.85,'Tag','nk','DisplayName','n_k');
h(3)=plot(ax,d.state_iteration,d.V1,'-d','Color',P.material_palette.tensile,'MarkerFaceColor','white','MarkerSize',3.5, ...
    'MarkerIndices',m,'LineWidth',0.85,'Tag','V1','DisplayName','V_1');
ylim(ax,[0 6]); yticks(ax,0:1:6); ylabel(ax,'V_k, n_k, V_1');
ax.YAxis(1).Color=[0 0 0];
yyaxis(ax,'right');
h(4)=plot(ax,d.state_iteration,d.C_Nmm,'-^','Color',[0.08 0.27 0.65],'MarkerFaceColor','white','MarkerSize',3.5, ...
    'MarkerIndices',m,'LineWidth',0.85,'Tag','C_Nmm','DisplayName','C');
ylim(ax,[0 800]); yticks(ax,0:200:800); ylabel(ax,'C [N mm]'); ax.YAxis(2).Color=[0 0 0];
xlim(ax,[0 214]); xticks(ax,[0 50 100 150 214]); xlabel(ax,'Iteration');
lg=legend(ax,h,'Location','east','Orientation','vertical','NumColumns',1,'Box','off');
style_legend(lg,P); fix_legend(ax,lg,[0.80 0.18 0.19 0.45]);
end
function draw_b(ax,P)
notation=mbeso_plot_notation;
d=mbeso_figure1_update_data(P); x=d.decision_update;
h(1)=plot(ax,x,d.trace_raw_974_MPa,'-o','Color',[0.48 0.48 0.48],'LineWidth',0.9,'MarkerSize',3.3, ...
    'MarkerFaceColor','white','Tag','trace_raw_974_MPa','DisplayName',['974: ' notation.stress_raw ' (unfiltered)']);
h(2)=plot(ax,x,d.trace_filtered_974_MPa,'-s','Color',[0.10 0.30 0.70],'LineWidth',0.9,'MarkerSize',3.3, ...
    'MarkerFaceColor','white','Tag','trace_filtered_974_MPa','DisplayName',['974: ' notation.stress_filtered ' (filtered)']);
yline(ax,0,':','Color',[0.6 0.6 0.6],'HandleVisibility','off','Tag','zero_reference');
xlim(ax,[1 10]); xticks(ax,[1 2 4 6 8 10]); ylim(ax,[-2 10]); yticks(ax,-2:2:10);
xlabel(ax,'Iteration'); ylabel(ax,[notation.stress_raw ', ' notation.stress_filtered ' [MPa]']);
lg=legend(ax,h,'Location','northeast','Box','off'); style_legend(lg,P); fix_legend(ax,lg,[0.14 0.76 0.84 0.22]);
end
function draw_c(ax,P)
notation=mbeso_plot_notation;
d=mbeso_figure1_update_data(P); x=d.decision_update;
h(1)=plot(ax,x,d.eta_raw_974,'-o','Color',[0.48 0.48 0.48],'LineWidth',0.9,'MarkerSize',3.2,'MarkerFaceColor','white', ...
    'Tag','eta_raw_974','DisplayName',['974: ' notation.eta_raw ' (unfiltered)']);
h(2)=plot(ax,x,d.eta_spatial_974,'-s','Color',[0.10 0.30 0.70],'LineWidth',0.9,'MarkerSize',3.2,'MarkerFaceColor','white', ...
    'Tag','eta_spatial_974','DisplayName',['974: ' notation.eta_filtered ' (filtered)']);
h(3)=plot(ax,x,d.eta_temporal_974,'-d','Color',[0.12 0.52 0.25],'LineWidth',0.9,'MarkerSize',3.2,'MarkerFaceColor','white', ...
    'Tag','eta_temporal_974','DisplayName',['974: ' notation.eta_history ' (history averaged)']);
h(4)=plot(ax,x,d.selection_cutoff,'--','Color',[0 0 0],'LineWidth',1, ...
    'Tag','selection_cutoff','DisplayName','Retention threshold');
h(5)=plot(ax,x,d.eta_temporal_5829,':^','Color',[0.90 0.40 0.06],'LineWidth',1,'MarkerSize',3.2,'MarkerFaceColor','white', ...
    'Tag','eta_temporal_5829','DisplayName',['5829: ' notation.eta_history ' (history averaged)']);
xlim(ax,[1 10]); xticks(ax,[1 2 4 6 8 10]); ylim(ax,[0 .5]); yticks(ax,0:.1:.5); ytickformat(ax,'%.2f');
xlabel(ax,'Iteration'); ylabel(ax,[notation.eta_raw ', ' notation.eta_filtered ', ' notation.eta_history]); ax.YColor=[0 0 0];
% Group the three element-974 series, then element 5829 and the global cutoff.
pos=ax.Position;
lg=legend(ax,h([1 2 3 5 4]),'Location','northeast','NumColumns',1);
style_legend(lg,P);lg.FontSize=7.5;
tidy_legend(ax,lg,[.99 1.06]);ax.Position=pos;
ax.GridAlpha=.10;

end
function draw_e(ax,P)
d=P.material;
% Exact cell polygons keep the material map vector-based in the PDF.
for phaseID=1:2
    [row,column]=find(d.phase==phaseID);
    xx=[column'-0.5;column'+0.5;column'+0.5;column'-0.5];
    yy=[row'-0.5;row'-0.5;row'+0.5;row'+0.5];
    patch(ax,xx,yy,d.colors(phaseID+1,:),'EdgeColor','none', ...
        'Tag',sprintf('material_phase_%d',phaseID));
end
colormap(ax,d.colors); ax.UserData=struct('phase_state10',d.phase);
set(ax,'YDir','reverse','DataAspectRatio',[1 1 1]); xlim(ax,[0.5 100.5]); ylim(ax,[0.5 60.5]);
axis(ax,'off');
for j=1:2
    x=d.columns(j); y=d.rows(j);
    plot(ax,x,y,'o','Color',[0 0 0],'MarkerFaceColor','white','MarkerSize',3.2,'LineWidth',0.8, ...
        'Tag',sprintf('element_location_%d',d.element_ids(j)));
    if j==1, tx=30; else, tx=80; end
    plot(ax,[x x tx],[y -5 -5],'k-','LineWidth',0.65,'HandleVisibility','off','Clipping','off');
    text(ax,tx,-10,sprintf('%d',d.element_ids(j)),'FontName',P.font_name,'FontSize',P.font_size_pt, ...
        'Color',[0 0 0],'HorizontalAlignment','center','VerticalAlignment','middle','Clipping','off');
end
plot(ax,[0.5 100.5 100.5 0.5 0.5],[0.5 0.5 60.5 60.5 0.5],'k-','LineWidth',0.65,'HandleVisibility','off');
end
function style_legend(lg,P)
lg.FontName=P.font_name; lg.FontSize=P.font_size_pt; lg.Interpreter='tex'; lg.ItemTokenSize=[11 8];
end
function tidy_legend(ax,lg,anchor)
% Use the empty upper-right region without changing the physical plot area.
set(lg,'Box','on','Color','white','EdgeColor',[.84 .86 .88],'LineWidth',.45, ...
 'TextColor',[0 0 0],'AutoUpdate','off');
lg.ItemTokenSize=[11 7];drawnow;
lg.Units=ax.Units;p=ax.Position;r=lg.Position;
r(1:2)=p(1:2)+anchor.*p(3:4)-r(3:4);lg.Position=r;
setappdata(lg,'MBESO_TidyLegend',struct('axisTag','panel_c','anchor',anchor));
end
function fix_legend(ax,lg,relative)
% Legend placement does not resize the physical plot area.
pos=ax.Position; lg.Units=ax.Units; lg.Position=[pos(1)+relative(1)*pos(3),pos(2)+relative(2)*pos(4),relative(3)*pos(3),relative(4)*pos(4)];
ax.Position=pos;
end
function export_figure(fig,stem)
mbeso_black_text(fig);
set(findall(fig,'-property','FontName'),'FontName','Times New Roman');
drawnow; savefig(fig,[stem '.fig']); print(fig,[stem '.png'],'-dpng','-r600');
meta=export_exact_tnr_pdf(fig,[stem '.pdf']);
mbeso_export_emf(fig,[stem '.emf']);
fid=fopen([stem '_pdf_metadata.json'],'w','n','UTF-8');fprintf(fid,'%s',jsonencode(meta));fclose(fid);
end
function verify_rendered(figures,P,rects,outputDir)
checks=cell(0,4); f=figures.combined;
for j=1:4
    id=P.panel_names{j}; ax=findobj(f,'Type','axes','Tag',['panel_' id]);
    pos=ax.Position*10;
    checks(end+1,:)={['combined_panel_' id '_axis_rectangle_mm'],max(abs(pos-rects(j,:))),1e-9,[]}; %#ok<AGROW>
    sax=findobj(figures.(id),'Type','axes','Tag',['panel_' id]);
    checks(end+1,:)={['standalone_panel_' id '_axis_size_mm'],max(abs(sax.Position(3:4)*10-rects(j,3:4))),1e-9,[]}; %#ok<AGROW>
end
tagsA={'Vk','nk','V1','C_Nmm'};
for j=1:numel(tagsA)
    h=findobj(f,'Type','line','Tag',tagsA{j});
    checks(end+1,:)={['plotted_' tagsA{j} '_matches_saved_array'],max(abs(h.YData(:)-P.response.(tagsA{j})(:))),0,[]}; %#ok<AGROW>
    checks(end+1,:)={['plotted_' tagsA{j} '_marker_states_0_to210_every10'],double(~isequal(h.XData(h.MarkerIndices)',P.response.marked_states)),0,[]}; %#ok<AGROW>
end
d=mbeso_figure1_update_data(P);
tagsLocal={'trace_raw_974_MPa','trace_filtered_974_MPa','eta_raw_974','eta_spatial_974','eta_temporal_974','selection_cutoff','eta_temporal_5829'};
for j=1:numel(tagsLocal)
    h=findobj(f,'Type','line','Tag',tagsLocal{j});
    checks(end+1,:)={['plotted_' tagsLocal{j} '_matches_saved_array'],max(abs(h.YData(:)-d.(tagsLocal{j})(:))),0,[]}; %#ok<AGROW>
    checks(end+1,:)={['plotted_' tagsLocal{j} '_update_numbers_1_to10'],double(~isequal(h.XData(:),d.decision_update)),0,[]}; %#ok<AGROW>
end
ax=findobj(f,'Type','axes','Tag','panel_e');
for phaseID=1:2
    h=findobj(ax,'Type','patch','Tag',sprintf('material_phase_%d',phaseID));
    [row,column]=find(P.material.phase==phaseID);
    xx=[column'-0.5;column'+0.5;column'+0.5;column'-0.5];
    yy=[row'-0.5;row'-0.5;row'+0.5;row'+0.5];
    checks(end+1,:)={sprintf('plotted_material_%d_polygons_match_state10',phaseID), ...
        max(abs(h.XData-xx),[],'all')+max(abs(h.YData-yy),[],'all'),0,[]}; %#ok<AGROW>
end
checks(end+1,:)={'material_M1_blue_M2_red_void_white',double(~isequal(ax.Colormap,[1 1 1;0 0 1;1 0 0])),0,[]};
for j=1:numel(P.events)
    e=P.events(j); h=findall(f,'Type','line','Tag',sprintf('event_%s_state%d',e.panel,e.state_iteration));
    checks(end+1,:)={sprintf('event_%s_state%d_matches_saved_field',e.panel,e.state_iteration), ...
        abs(h.XData-e.decision_update)+abs(h.YData-P.local.(e.field)(e.state_iteration+1)),0,[]}; %#ok<AGROW>
end
for j=1:size(checks,1),checks{j,4}=checks{j,2}<=checks{j,3};end
fid=fopen(fullfile(outputDir,'render_verification_checks.csv'),'w','n','UTF-8');guard=onCleanup(@()fclose(fid));
fprintf(fid,'check_id,max_absolute_difference,tolerance,passed\n');
for j=1:size(checks,1),fprintf(fid,'%s,%.17g,%.17g,%d\n',checks{j,:});end
clear guard;
assert(all(cell2mat(checks(:,4))),'Rendered figure verification failed.');
end
