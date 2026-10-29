function mbeso_apply_lab_style(f)
%MBESO_APPLY_LAB_STYLE Shared journal axes and unit notation; data stay intact.
% Reference: professor's supplied MATLAB examples use grid on and Times fonts.
% A complete four-sided frame follows the author's 2026-10-19 instruction.
objects=findall(f);
for k=1:numel(objects)
    h=objects(k);
    if isprop(h,'FontName'),h.FontName='Times New Roman';end
    if isprop(h,'String'),h.String=editText(h.String);end
    if isprop(h,'DisplayName'),h.DisplayName=editText(h.DisplayName);end
end
% Legend titles are not returned by findall in some MATLAB releases.
legends=findall(f,'Type','legend');
for k=1:numel(legends)
    legends(k).Title.String=editText(legends(k).Title.String);
    legends(k).Title.FontName='Times New Roman';
    legends(k).Title.Color='black';
end
axesHandles=findall(f,'Type','axes');
for k=1:numel(axesHandles)
    a=axesHandles(k);
    % Material maps and assignment strips are diagrams, not Cartesian plots.
    if strcmp(a.Visible,'off') || isempty(a.XTick) || isempty(a.YTick),continue;end
    set(a,'Box','on','TickDir','in','XGrid','on','YGrid','on', ...
        'XMinorGrid','off','YMinorGrid','off','GridLineStyle','-', ...
        'GridColor',[.15 .15 .15],'GridAlpha',.15,'Layer','bottom', ...
        'XColor','black','YColor','black');
    for j=1:numel(a.YAxis),a.YAxis(j).Color='black';end
end
setappdata(f,'MBESO_LabStyleVersion','2026-10-19');
mbeso_apply_final_axes(f);
mbeso_compact_fig8b_legend(f);
mbeso_apply_professor_feedback(f);
end

function value=editText(value)
if iscell(value)
    for j=1:numel(value),value{j}=editText(value{j});end
elseif isstring(value)
    for j=1:numel(value),value(j)=string(editText(char(value(j))));end
elseif ischar(value)
    value=regexprep(value,'[Rr]esponse stop','Analysis termination');
    value=strrep(value,'N mm',['N' char(183) 'mm']);
    value=strrep(value,'Nmm',['N' char(183) 'mm']);
    value=strrep(value,'MN m',['MN' char(183) 'm']);
    value=regexprep(value,'\[([^\[\]]*(?:MPa|MN|mm|%|MN·m))\]','($1)');
    % These are descriptive normalization labels, not arithmetic expressions.
    value=strrep(value,'Solid-void / domain','Solid-void domain');
    value=strrep(value,'Material / common solids','Material common solids');
end
end
