function mbeso_layout_fig9_zoom(f)
% Preserve text point sizes when fitting the reduced Fig. 9(f-2) canvas.
a=findobj(f,'Type','axes','Tag','Fig09f_2');
if isempty(a),return;end
f.PaperUnits='centimeters';sz=f.PaperSize;
if sz(1)>=5,return;end
a.Units='centimeters';
a.XTickLabelRotation=45;
% Fixed text margins are required because the font sizes are not reduced.
a.Position=[.80 1.04 sz(1)-1.08 sz(2)-1.72];
lg=findobj(f,'Type','legend');
lg.NumColumns=2;lg.Location='northoutside';drawnow;
lg.Units='centimeters';p=lg.Position;
lg.Position=[(sz(1)-p(3))/2 sz(2)-.12-p(4) p(3:4)];
a.Position=[.80 1.04 sz(1)-1.08 sz(2)-1.72];drawnow;
% Keep the tall unchanged y-label clear of the full-width legend.
a.YLabel.Units='normalized';p=a.YLabel.Position;p(2)=.38;a.YLabel.Position=p;
drawnow;
end
