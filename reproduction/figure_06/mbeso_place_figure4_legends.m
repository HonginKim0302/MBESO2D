function mbeso_place_figure4_legends(f)
% Keep one-row Figure 4 legends below the two-line case labels after scaling.
legends=findall(f,'Type','legend');
for k=1:numel(legends)
 lg=legends(k);if ~isappdata(lg,'MBESO_Figure4BottomLegend'),continue;end
 lg.NumColumns=numel(lg.String);lg.Orientation='horizontal';
 a=findobj(f,'Type','axes','Tag',getappdata(lg,'MBESO_Figure4BottomLegend'));
 au=a.Units;fu=f.Units;lu=lg.Units;
 a.Units='centimeters';f.Units='centimeters';p=a.Position;
 lg.Location='south';lg.ItemTokenSize=[10 7];drawnow;lg.Units='centimeters';r=lg.Position;
 % A one-row legend can use the existing side margins. If enlarged by the
 % master, compact only its symbol widths; keep all words and font sizes.
 availableWidth=f.Position(3)-.16;
 while r(3)>availableWidth && lg.ItemTokenSize(1)>4
  lg.ItemTokenSize=[lg.ItemTokenSize(1)-1 7];drawnow;r=lg.Position;
 end
 r(1)=p(1)+p(3)/2-r(3)/2;
 r(1)=max(.08,min(r(1),f.Position(3)-r(3)-.08));
 r(2)=max(.08,p(2)-1.35-r(4));lg.Position=r;
 a.Position=p;a.Units=au;f.Units=fu;
 % Save physical dimensions; popup helpers normalize only after verification.
 if isappdata(f,'MBESO_PopupOriginalLayout'),lg.Units=lu;
 else,lg.Units='centimeters';end
end
end
