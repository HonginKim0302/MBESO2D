function fig = render_submitted_panel(panel,D,showWindows)
%RENDER_SUBMITTED_PANEL Native editable plots in the submitted professor style.
% D is the canonical input structure from submitted_plot_data or a fresh adapter.
if nargin<3, showWindows=false; end
panel=char(panel); assert(any(strcmp(panel,submitted_panel_ids())),'Unknown submitted panel.');
isZoom=endsWith(panel,'_zoom');
height=400; fontSize=18; if isZoom, height=300; fontSize=24; end
fig=figure('Visible','off','Name',panel,'NumberTitle','off','Color','w', ...
    'WindowStyle','normal','Units','pixels','Position',[100 100 560 height], ...
    'Renderer','painters','Tag',panel,'InvertHardcopy','off');
fig.UserData=struct('panel',panel,'source_mode',D.source_mode,'data_end',214);
ax=axes('Parent',fig,'Tag',[panel '_axes']); hold(ax,'on');
set(ax,'FontName','Times New Roman','FontSize',fontSize, ...
    'XColor','k','YColor','k','Color','w','Box','off','LineWidth',.5);
grid(ax,'on'); xlabel(ax,'Iteration');
switch panel
    case 'Fig06_a'
        yyaxis(ax,'left');
        linePlot(ax,D.state,D.C,'r-',1.2,[],'compliance');
        ylabel(ax,'Compliance (N·mm)'); ylim(ax,[0 800]); yticks(ax,0:100:800);
        ax.YColor='k';
        yyaxis(ax,'right');
        linePlot(ax,D.state,D.nk,'b-.',1.2,[],'normalization_coefficient');
        ylabel(ax,'Normalization coefficient'); ylim(ax,[0 8]); yticks(ax,0:8); ax.YColor='k';
        xlim(ax,[0 250]); xticks(ax,0:50:250);
        legend(ax,{'Compliance (\itC)','Normalization coefficient ({\itn}_{\itk})'},'Location','southeast');
    case 'Fig06_c'
        linePlot(ax,D.local_update,D.rawStress,'r-*',1.2,10,'unfiltered_stress');
        linePlot(ax,D.local_update,D.filteredStress,'b--o',1.2,10,'filtered_stress');
        xlim(ax,[1 10]); xticks(ax,1:10); ylim(ax,[-2 8]); yticks(ax,-2:8);
        ylabel(ax,'Stress-state indicator (MPa)');
        legend(ax,{'Unfiltered ({\itσ}_{\ite,i})','Filtered ({\itσ}''_{\ite,i})'},'Location','northeast');
    case 'Fig06_d'
        linePlot(ax,D.local_update,D.score974,'r-^',1.2,10,'history_score_974');
        linePlot(ax,D.local_update,D.score5829,'b-o',1.2,10,'history_score_5829');
        linePlot(ax,D.local_update,D.threshold,'k--',1.2,[],'retention_threshold');
        xlim(ax,[1 10]); xticks(ax,1:10); ylim(ax,[0 .2]); yticks(ax,0:.05:.2);
        ylabel(ax,'History-averaged utilization');
        legend(ax,{'Element 974','Element 5829','Retention threshold'},'Location','northeast');
    case 'Fig07_a'
        linePlot(ax,D.update,D.solid,'k-.',1.2,[],'solid_volume_percent');
        h=linePlot(ax,D.update,D.tensile,'-',1.2,[],'tensile_volume_percent');
        h.Color=D.palette.tensile;
        h=linePlot(ax,D.update,D.compressive,'--',1.2,[],'compressive_volume_percent');
        h.Color=D.palette.compressive;
        xlim(ax,[0 250]); xticks(ax,0:50:250); ylim(ax,[0 100]); yticks(ax,0:20:100);
        ylabel(ax,'Volume fraction (%)');
        legend(ax,{'Solid ({\itV}_1+{\itV}_2)','Tensile material ({\itV}_1)', ...
            'Compressive material ({\itV}_2)'},'Location','northeast');
    case {'Fig07_b','Fig07_b_zoom'}
        pick=true(size(D.update)); width=1.2;
        if isZoom, pick=D.update>=195 & D.update<=214; width=1.5; end
        linePlot(ax,D.update(pick),D.transitionsSV(pick),'r--',width,[],'solid_void_transitions');
        linePlot(ax,D.update(pick),D.transitionsTC(pick),'b-',width,[],'tensile_compressive_transitions');
        if isZoom
            xlim(ax,[195 215]);xticks(ax,195:5:215);ylim(ax,[0 10]);yticks(ax,0:2:10);xlabel(ax,'');
        else
            xlim(ax,[0 250]);xticks(ax,0:50:250);ylim(ax,[0 2500]);yticks(ax,0:500:2500);
            ylabel(ax,'Element transitions');
            legend(ax,{'Solid–void','Tensile–compressive'},'Location','northeast');
        end
    case {'Fig07_c','Fig07_c_zoom'}
        styles={'k-.','b-','r--','m-','g-'};
        pick=true(size(D.state));width=1.2;
        if isZoom,pick=D.state>=195 & D.state<=214;width=2;end
        for k=1:5
            linePlot(ax,D.state(pick),D.deadband(pick,k),styles{k},width,[],sprintf('deadband_case_%d',k));
        end
        if isZoom
            xlim(ax,[195 215]);xticks(ax,195:5:215);ylim(ax,[-1.5 1.5]);yticks(ax,-1.5:.5:1.5);xlabel(ax,'');
        else
            xlim(ax,[0 250]);xticks(ax,0:50:250);ylim(ax,[-40 40]);yticks(ax,-40:10:40);
            ylabel(ax,'Compliance difference (%)');
            labels={'{\itδ}_{\itσ} = 0 MPa','{\itδ}_{\itσ} = 0.005 MPa', ...
                '{\itδ}_{\itσ} = 0.05 MPa','{\itδ}_{\itσ} = 0.5 MPa', ...
                '{\itδ}_{\itσ} = 5 MPa'};
            legend(ax,labels,'NumColumns',2,'Location','southeast');
        end
    case {'Fig07_d','Fig07_e'}
        if strcmp(panel,'Fig07_d'), values=D.countsSVTC; else, values=D.layoutSVTC; end
        bars=bar(ax,1:5,values,.8,'grouped');
        colors=[1 0 0;0 1 0];
        for k=1:2
            bars(k).FaceColor=colors(k,:);bars(k).Tag=sprintf('%s_series_%d',panel,k);
        end
        set(ax,'XTick',1:5,'XTickLabel',{'0','0.005','0.05','0.5','5'},'Box','on');
        xlabel(ax,'Deadband half-width (MPa)');
        if strcmp(panel,'Fig07_d')
            ylim(ax,[3000 8000]);yticks(ax,3000:1000:8000);ylabel(ax,'Cumulative transition events');
            legend(ax,bars,{'Solid–void','Tensile–compressive'},'Location','northeast');
        else
            ylim(ax,[0 10]);yticks(ax,0:2:10);ylabel(ax,'Layout difference (%)');
            legend(ax,bars,{'Solid–void','Tensile–compressive'},'Location','north');
        end
        drawnow;
        for k=1:2
            for j=1:5
                if strcmp(panel,'Fig07_d'),label=sprintf('%d',values(j,k));
                elseif values(j,k)==0,label='0';else,label=sprintf('%.2f',values(j,k));end
                text(ax,bars(k).XEndPoints(j),bars(k).YEndPoints(j),label, ...
                    'FontName','Times New Roman','FontSize',18,'Color','k', ...
                    'HorizontalAlignment','center','VerticalAlignment','bottom', ...
                    'Tag',sprintf('%s_value_%d_%d',panel,j,k));
            end
        end
end
set(findall(fig,'Type','legend'),'FontName','Times New Roman','FontSize',fontSize,'TextColor','k');
set(fig,'PaperUnits','inches','PaperSize',[560 height]/96, ...
    'PaperPosition',[0 0 560 height]/96,'PaperPositionMode','manual');
drawnow;
if showWindows,fig.Visible='on';end
end

function h=linePlot(ax,x,y,style,width,markerSize,tag)
h=plot(ax,x,y,style,'LineWidth',width,'Tag',tag);
if ~isempty(markerSize),h.MarkerSize=markerSize;end
end
