function mbeso_place_paper_legends(f)
%MBESO_PLACE_PAPER_LEGENDS Keep legend boxes clear of the four-sided frame.
aa=findall(f,'Type','axes');
for j=1:numel(aa)
 a=aa(j);tag=a.Tag;side='right';bottom=false;
 if strcmp(tag,'panel_c') && ~isempty(findobj(a,'Tag','eta_raw_974'))
     % Empty display headroom accommodates five unchanged legend entries.
     a.YLim=[0 .5];a.YTick=0:.1:.5;
     setappdata(a,'MBESO_DisplayHeadroom','Original data unchanged; upper limit 0.34 to 0.50 for legend clearance.');
 elseif strcmp(tag,'axes_b') && ~isempty(findobj(a,'Tag','b_tensile'))
 elseif strcmp(tag,'Figure3_b')
     bottom=true;
 elseif ismember(tag,{'Figure3_c','Figure3_d','Figure3_e'})
     if strcmp(tag,'Figure3_e'),side='left';end
 else
     continue;
 end
 lg=legend(a);au=a.Units;lu=lg.Units;
 a.Units='centimeters';lg.Units='centimeters';p=a.Position;r=lg.Position;
 gap=.08;
 if strcmp(side,'left'),r(1)=p(1)+gap;else,r(1)=p(1)+p(3)-r(3)-gap;end
 if bottom,r(2)=p(2)+gap;else,r(2)=p(2)+p(4)-r(4)-gap;end
 lg.Position=r;
 a.Units=au;lg.Units=lu;
end
setappdata(f,'MBESO_PaperLegendVersion','2026-10-19');
end
