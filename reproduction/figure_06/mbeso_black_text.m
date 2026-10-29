function mbeso_black_text(f)
%MBESO_BLACK_TEXT Apply black text without changing plotted data or series colors.
set(findall(f,'Type','text'),'Color',[0 0 0]);
a=findall(f,'Type','axes');
for j=1:numel(a)
    set(a(j),'XColor',[0 0 0],'YColor',[0 0 0],'ZColor',[0 0 0]);
    % yyaxis has two rulers whose colors must both be set explicitly.
    for k=1:numel(a(j).YAxis),a(j).YAxis(k).Color=[0 0 0];end
end
set(findall(f,'Type','legend'),'TextColor',[0 0 0], ...
    'Box','on','Color','white','EdgeColor',[.84 .86 .88],'LineWidth',.45);
set(findall(f,'Type','colorbar'),'Color',[0 0 0]);
% Keep the newly opaque boxes above the data, also after master scaling.
layout={'axes_c',[.99 1.08];'Figure3_e',[.99 1.04]};
for j=1:size(layout,1)
    ax=findobj(f,'Type','axes','Tag',layout{j,1});
    if numel(ax)~=1,continue;end
    lg=legend(ax);lg.Location='northeast';drawnow;
    lg.Units=ax.Units;p=ax.Position;r=lg.Position;
    r(1:2)=p(1:2)+layout{j,2}.*p(3:4)-r(3:4);lg.Position=r;
end


% Apply the shared journal template after legend placement.
stylePath=path;styleGuard=onCleanup(@()path(stylePath)); %#ok<NASGU>
addpath(fileparts(fileparts(mfilename('fullpath'))),'-begin');
mbeso_apply_lab_style(f);
end
