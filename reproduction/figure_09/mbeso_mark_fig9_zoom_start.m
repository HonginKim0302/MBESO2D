function showLabel=mbeso_mark_fig9_zoom_start(f)
% Mark iteration 195, hiding its number only when the next tick is too close.
a=findobj(f,'Type','axes','Tag','Fig09f_1');
if isempty(a),showLabel=false;return;end
if a.XLim(2)==250
    a.XTick=[0 50 100 150 195 200 250];
    labels={'0','50','100','150','195','200','250'};nextTick=200;
else
    a.XTick=[2 50 100 150 195 214];
    labels={'2','50','100','150','195','214'};nextTick=214;
end
a.XTickLabelRotation=0;
oldUnits=a.Units;a.Units='centimeters';width=a.Position(3);a.Units=oldUnits;
t=text(a,0,0,'195','Units','centimeters','Visible','off', ...
    'FontName',a.FontName,'FontSize',a.FontSize,'FontWeight',a.FontWeight, ...
    'Interpreter','none');
drawnow;width195=t.Extent(3);t.String=sprintf('%d',nextTick);drawnow;widthNext=t.Extent(3);delete(t);
gap=(nextTick-195)/diff(a.XLim)*width;
showLabel=gap>=(width195+widthNext)/2+.03;
if ~showLabel,labels{5}='';end
a.XTickLabel=labels;
setappdata(f,'MBESO_Fig9Tick195',struct('label_visible',showLabel,'gap_cm',gap, ...
    'label_widths_cm',[width195 widthNext],'next_tick',nextTick));
end
