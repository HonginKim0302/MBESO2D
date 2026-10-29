function mbeso_compact_fig8b_legend(f)
%MBESO_COMPACT_FIG8B_LEGEND Fit the two entries without scaling their text.
aa=findobj(f,'Type','axes','Tag','panel_b');
for j=1:numel(aa)
    a=aa(j);
    if isempty(findobj(a,'Tag','trace_raw_974_MPa')),continue;end
    lg=legend(a);au=a.Units;lu=lg.Units;
    a.Units='centimeters';p=a.Position;
    % A named location restores MATLAB's text-fitted legend dimensions.
    lg.ItemTokenSize=[9 6];lg.NumColumns=1;lg.Location='northeast';
    drawnow;lg.Units='centimeters';r=lg.Position;
    gap=.08;r(1:2)=p(1:2)+p(3:4)-r(3:4)-gap;
    lg.Position=r;a.Position=p;
    a.Units=au;lg.Units=lu;
end
end
