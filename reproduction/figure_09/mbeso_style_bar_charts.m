function mbeso_style_bar_charts(f)
%MBESO_STYLE_BAR_CHARTS Outline Figure 3 bars and label their actual heights.
% Idempotent: safe for saved exports and already-open MASTER_FONT_SCALE windows.
% Does not change the data, axes geometry, limits, fill colors or paper size.
for panel='cde'
    ax=findobj(f,'Type','axes','Tag',['Figure3_' panel]);
    if numel(ax)~=1,continue;end
    drawnow;
    for series=1:2
        h=findobj(ax,'Type','bar','Tag',sprintf('Figure3_%s_series_%d',panel,series));
        if numel(h)~=1,continue;end
        set(h,'EdgeColor',[0 0 0],'LineStyle','-','LineWidth',.6);
        for j=1:numel(h.YData)
            value=h.YData(j);
            if panel=='e' && value~=0,label=sprintf('%.2f',value);
            else,label=sprintf('%.0f',value);end
            tag=sprintf('Figure3_%s_barlabel_%d_%d',panel,series,j);
            t=findall(ax,'Type','text','Tag',tag);
            if isempty(t)
                t=text(ax,0,0,'','Tag',tag,'FontName','Times New Roman', ...
                    'FontSize',8,'Interpreter','none','Color','k', ...
                    'HorizontalAlignment','center','VerticalAlignment','bottom', ...
                    'Clipping','off','HandleVisibility','off');
            end
            assert(isscalar(t),'Duplicate bar labels found.');
            if ~isappdata(t,'MBESO_BarLabelStyleV2')
                if panel=='e',baseSize=8;else,baseSize=6.5;end
                t.FontSize=baseSize;setappdata(t,'MBESO_BarLabelStyleV2',true);
                if isappdata(t,'MBESO_MasterBaseFontSize')
                    setappdata(t,'MBESO_MasterBaseFontSize',baseSize);
                end
            end
            % Retain FontSize on existing labels so master scaling is preserved.
            t.String=label;t.Position=[h.XEndPoints(j),value+.015*diff(ax.YLim),0];
            t.HorizontalAlignment='center';
            % Put the short bar's label toward the outside of its pair so its
            % digits do not lie on the neighboring, taller bar.
            other=findobj(ax,'Type','bar','Tag',sprintf('Figure3_%s_series_%d',panel,3-series));
            if isscalar(other) && value>0 && value<other.YData(j)
                offset=.35*abs(other.XEndPoints(j)-h.XEndPoints(j));
                if series==1
                    t.HorizontalAlignment='right';t.Position(1)=h.XEndPoints(j)+offset;
                else
                    t.HorizontalAlignment='left';t.Position(1)=h.XEndPoints(j)-offset;
                end
            end
            t.Color=[0 0 0];t.FontName='Times New Roman';
            % Keep edge-group labels on the plot side of the vertical axis.
            au=ax.Units;ax.Units='centimeters';u=t.Units;t.Units='centimeters';
            box=t.Extent;t.Position(1)=t.Position(1)+max(0,.01-box(1));
            t.Units=u;ax.Units=au;
            setappdata(t,'MBESO_SourceBarValue',value);
        end
    end
    % Keep the framed legend in the existing upper margin, clear of bar labels.
    lg=legend(ax);lg.AutoUpdate='off';lg.Location='northeast';
    if panel~='e',lg.NumColumns=2;end
    drawnow;
    lg.Units=ax.Units;p=ax.Position;r=lg.Position;
    if panel=='e',top=1.10;else,top=1.06;end
    r(1:2)=p(1:2)+[.99 top].*p(3:4)-r(3:4);lg.Position=r;
    % Master font enlargement can make the legend taller. Lift it only as
    % much as the actual label extents require; do not shrink any text.
    au=ax.Units;lu=lg.Units;ax.Units='centimeters';lg.Units='centimeters';
    r=lg.Position;labels=findall(ax,'Type','text','-regexp','Tag','_barlabel_');
    for j=1:numel(labels)
        u=labels(j).Units;labels(j).Units='centimeters';box=labels(j).Extent;
        labels(j).Units=u;box(1:2)=box(1:2)+ax.Position(1:2);
        if min(box(1)+box(3),r(1)+r(3))>max(box(1),r(1))
            r(2)=max(r(2),box(2)+box(4)+.06);
        end
    end
    lg.Position=r;ax.Units=au;lg.Units=lu;
end
end
