function figures=reproduce_figure4
%REPRODUCE_FIGURE4 Native plots from archived bridge FE arrays, not image values.
here=fileparts(mfilename('fullpath'));s=load(fullfile(here,'data','plot_inputs.mat'),'P');P=s.P;
oldPath=path;pathGuard=onCleanup(@()path(oldPath)); %#ok<NASGU>
addpath(fileparts(here),'-begin');
L=jsondecode(fileread(fullfile(here,'reference','layout.json')));
out=fullfile(here,'figures');if ~isfolder(out),mkdir(out);end
rect=L.panel_rect_pixels_xyxy;
rect=[rect(:,1)/L.reference_pixels(1)*L.canvas_mm(1), ...
 (L.reference_pixels(2)-rect(:,4))/L.reference_pixels(2)*L.canvas_mm(2), ...
 (rect(:,3)-rect(:,1))/L.reference_pixels(1)*L.canvas_mm(1), ...
 (rect(:,4)-rect(:,2))/L.reference_pixels(2)*L.canvas_mm(2)];
figures=struct;checks={};dims={};ids={'c','d'};
figures.combined=newFigure(L.canvas_mm(:)','Figure 4 | Bridge load and energy');
for j=1:2
 drawPanel(figures.combined,ids{j},rect(j,:),P);
end
savePlot(figures.combined,fullfile(out,'Figure4_bridge'));
for j=1:2
 margin=[16 26 4 5];r=rect(j,:);page=[r(3)+margin(1)+margin(3),r(4)+margin(2)+margin(4)];
 f=newFigure(page,['Figure 4(' ids{j} ')']);figures.(ids{j})=f;
 drawPanel(f,ids{j},[margin(1:2) r(3:4)],P);
 savePlot(f,fullfile(out,['Figure4_panel_' ids{j}]));
end
names=fieldnames(figures);
for j=1:numel(names)
 f=figures.(names{j});aa=findall(f,'Type','axes');
 for k=1:numel(aa)
  a=aa(k);a.Units='centimeters';id=a.Tag(end);ii=find(strcmp(ids,id));
  err=max(abs(10*a.Position(3:4)-rect(ii,3:4)));
  checks(end+1,:)={names{j},[id '_original_axis_dimensions_mm'],err,1e-9,err<1e-9}; %#ok<AGROW>
  dims(end+1,:)={names{j},id,10*f.PaperSize(1),10*f.PaperSize(2),10*a.Position(1),10*a.Position(2),10*a.Position(3),10*a.Position(4)}; %#ok<AGROW>
  assert(isempty(a.Title.String));
  if id=='c'
   tags={'deck_force','selfweight_force','support_reaction'};
   values={P.external_MN,P.selfweight_MN,P.reaction_MN};
  else
   tags={'deck_energy','cross_energy','selfweight_energy','total_compliance'};
   values={P.energy_components_MNm(:,1),P.energy_components_MNm(:,2),P.energy_components_MNm(:,3),P.C_production_MNm};
  end
  for q=1:numel(tags)
   h=findobj(a,'Tag',tags{q});err=max(abs(h.YData(:)-values{q}(:)));
   checks(end+1,:)={names{j},tags{q},err,0,err==0}; %#ok<AGROW>
  end
  if id=='d'
   err=max(abs(sum(P.energy_components_MNm,2)-P.C_MNm(:))./abs(P.C_MNm(:)));
   checks(end+1,:)={names{j},'component_sum_vs_independent_total_C',err,1e-12,err<=1e-12}; %#ok<AGROW>
   err=max(abs(sum(P.energy_components_MNm,2)-P.C_production_MNm(:))./abs(P.C_production_MNm(:)));
   checks(end+1,:)={names{j},'component_sum_vs_baseline_C',err,1e-8,err<=1e-8}; %#ok<AGROW>
  end
  for q=1:2
   label=findobj(a,'Tag',sprintf('case_caption_%d',q));
   actual=join(string(label.String),newline);
   actual=erase(erase(regexprep(actual,'\\(?:it|rm|bf)\s*',''),'{'),'}');
   if id=='c',detail=sprintf('Iteration %d',P.iteration(q));
   else,detail=sprintf('C = %.3f',P.C_MNm(q));end
   expectedCase=sprintf('Case III(%c)','a'+q-1);
   ok=contains(actual,expectedCase)&&contains(actual,detail);
   checks(end+1,:)={names{j},sprintf('%s_case_caption_%d',id,q),double(~ok),0,ok}; %#ok<AGROW>
  end
 end
 textObjects=findall(f,'-property','FontName');assert(all(arrayfun(@(h)strcmp(h.FontName,'Times New Roman'),textObjects)));
end
T=cell2table(checks,'VariableNames',{'artifact','check','absolute_error','tolerance','passed'});
writetable(T,fullfile(here,'render_checks.csv'));assert(all(T.passed));
D=cell2table(dims,'VariableNames',{'artifact','panel','canvas_width_mm','canvas_height_mm','axis_left_mm','axis_bottom_mm','axis_width_mm','axis_height_mm'});
writetable(D,fullfile(here,'panel_dimensions.csv'));
mbeso_finalize_paper_exports(here);
fprintf('Figure 4: %d plotted-array / physical-size checks passed.\n',height(T));
end

function f=newFigure(mm,name)
f=figure('Visible','off','Name',name,'NumberTitle','off','Color','white', ...
 'Units','centimeters','Position',[1 1 mm/10],'Renderer','painters', ...
 'PaperUnits','centimeters','PaperSize',mm/10,'PaperPosition',[0 0 mm/10], ...
 'PaperPositionMode','manual','InvertHardcopy','off','Resize','on');
end
function a=drawPanel(f,id,mm,P)
a=axes('Parent',f,'Units','centimeters','Position',mm/10,'PositionConstraint','innerposition', ...
 'Tag',['Figure4_' id],'FontName','Times New Roman','FontSize',9,'LineWidth',.65, ...
 'Box','off','TickDir','out','XColor','k','YColor','k','Color','white', ...
 'YGrid','on','XGrid','off','GridColor',[.70 .70 .70],'GridAlpha',.25,'Layer','top');
hold(a,'on');x=1:2;
deck=[.52 .68 .82];self=[.73 .73 .73];cross=[.77 .55 .28];
if id=='c'
 h=bar(a,x,[P.external_MN(:),P.selfweight_MN(:)],.48,'stacked');
 for k=1:2,h(k).EdgeColor=[.25 .25 .25];h(k).LineWidth=.6;end
 h(1).FaceColor=deck;h(1).Tag='deck_force';h(2).FaceColor=self;h(2).Tag='selfweight_force';
 r=plot(a,x,P.reaction_MN(:)','d','Color','k','MarkerFaceColor','white', ...
  'MarkerSize',4.5,'LineStyle','none','LineWidth',.8,'Tag','support_reaction');
 for k=1:2
  number(a,k,P.external_MN(k)/2,P.external_MN(k),'middle');
  number(a,k,P.external_MN(k)+P.selfweight_MN(k)/2,P.selfweight_MN(k),'middle');
  number(a,k,P.reaction_MN(k)+3,P.reaction_MN(k),'bottom');
 end
 ylim(a,[0 120]);a.YTick=0:30:120;ylabel(a,'Vertical load [MN]','FontSize',9.5);
 labels={sprintf('Case III(a)\nIteration %d',P.iteration(1)),sprintf('Case III(b)\nIteration %d',P.iteration(2))};
 lg=legend(a,[h(1),h(2),r],{'Deck load','Self-weight','Support reaction'}, ...
  'NumColumns',3,'Orientation','horizontal','Location','south');
else
 % Each case pairs the sum of its three components with the independently
 % stored baseline C = 0.5 F' U. Stacking exposes the agreement of heights.
 h=bar(a,x-.16,P.energy_components_MNm,.25,'stacked');
 colors=[deck;cross;self];tags={'deck_energy','cross_energy','selfweight_energy'};
 for j=1:3
  h(j).FaceColor=colors(j,:);h(j).EdgeColor=[.25 .25 .25];h(j).LineWidth=.6;h(j).Tag=tags{j};
 end
 total=bar(a,x+.16,P.C_production_MNm(:)',.25,'FaceColor','white', ...
     'EdgeColor','black','LineWidth',1,'Tag','total_compliance');
 drawnow;
 for k=1:2
  base=0;
  for j=1:3
   value=P.energy_components_MNm(k,j);
   if j==1
    % The deck-only segment is too short for an internal label at print size.
    labelY=max(.14,base+value/2);
    text(a,x(k)-.31,labelY,sprintf('%.3f',value),'Color','black', ...
        'FontName','Times New Roman','FontSize',8,'HorizontalAlignment','right', ...
        'VerticalAlignment','middle','Tag','numeric_bar_label');
    plot(a,[x(k)-.295 x(k)-.16],[labelY base+value/2],'k-', ...
        'LineWidth',.5,'HandleVisibility','off','Tag',sprintf('deck_label_leader_%d',k));
   else
    number(a,x(k)-.16,base+value/2,value,'middle');
   end
   base=base+value;
  end
  number(a,x(k)+.16,P.C_production_MNm(k)+.055,P.C_production_MNm(k),'bottom');
  plot(a,[x(k)-.285 x(k)+.285],[base base],'k--','LineWidth',.6, ...
      'HandleVisibility','off','Tag',sprintf('energy_equality_level_%d',k));
 end
 ylim(a,[0 3]);a.YTick=0:.5:3;ytickformat(a,'%.1f');
 ylabel(a,['Strain energy [MN' char(183) 'm]'],'FontSize',9.5);
 labels={sprintf('Case III(a)\nC = %.3f',P.C_production_MNm(1)),sprintf('Case III(b)\nC = %.3f',P.C_production_MNm(2))};
 lg=legend(a,[h(:);total],{'Deck load','Cross term','Self-weight','Compliance'}, ...
     'NumColumns',4,'Orientation','horizontal','Location','south');
 setappdata(f,'MBESO_TotalComplianceBarVersion','2026-10-19');
end
if id=='d',xlim(a,[.4 2.6]);else,xlim(a,[.5 2.5]);end
a.XTick=x;a.XTickLabel={};
% Native tick labels split newline strings into extra ticks; use true
% multiline text objects so both case names retain their own second line.
for k=1:2
 text(a,k,-.04*diff(a.YLim),strsplit(labels{k},sprintf('\n')), ...
  'HorizontalAlignment','center','VerticalAlignment','top','Clipping','off', ...
  'FontName','Times New Roman','FontSize',9,'Color','black','Interpreter','none', ...
  'Tag',sprintf('case_caption_%d',k));
end
set(lg,'FontName','Times New Roman','FontSize',7.5,'TextColor','k', ...
 'Box','on','Color','white','EdgeColor',[.84 .86 .88],'LineWidth',.45,'AutoUpdate','off');
lg.ItemTokenSize=[10 7];setappdata(lg,'MBESO_Figure4BottomLegend',a.Tag);
a.Position=mm/10;
set(findall(f,'-property','FontName'),'FontName','Times New Roman');
mbeso_place_figure4_legends(f);
end
function number(a,x,y,v,align)
text(a,x,y,sprintf('%.3f',v),'Color','black','FontName','Times New Roman','FontSize',8, ...
 'HorizontalAlignment','center','VerticalAlignment',align,'Tag','numeric_bar_label');
end
function savePlot(f,stem)
mbeso_black_text(f);mbeso_place_figure4_legends(f);drawnow;
savefig(f,[stem '.fig']);print(f,[stem '.png'],'-dpng','-r600');
meta=export_exact_tnr_pdf(f,[stem '.pdf']);
mbeso_export_emf(f,[stem '.emf']);
fid=fopen([stem '_pdf_metadata.json'],'w','n','UTF-8');fprintf(fid,'%s',jsonencode(meta));fclose(fid);
end
