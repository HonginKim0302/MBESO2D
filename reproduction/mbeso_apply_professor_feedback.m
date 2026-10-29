function mbeso_apply_professor_feedback(f)
%MBESO_APPLY_PROFESSOR_FEEDBACK Apply the advisor's graph display corrections.
% Full histories end at state/update 214; 214--250 is empty display space.
% Scoped TeX italics affect variables only, keeping prose, units and digits roman.
aa=findall(f,'Type','axes');
for j=1:numel(aa)
    a=aa(j);
    fullHistory=strcmp(a.Tag,'Figure3_b') || ismember(a.Tag,{'Fig09e','Fig09f_1'}) || ...
        (strcmp(a.Tag,'panel_a') && ~isempty(findobj(a,'Tag','C_Nmm')));
    if fullHistory
        a.XLim=[0 250];a.XTick=0:50:250;a.XTickLabelMode='auto';
        setappdata(a,'MBESO_HistoryDisplayRange',[0 250]);
        setappdata(a,'MBESO_HistoryDataEnd',214);
    end
end
objects=findall(f);
for j=1:numel(objects)
    h=objects(j);
    if isprop(h,'String')
        value=mathText(h.String);
        if ~isequal(value,h.String)
            h.String=value;
            if isprop(h,'Interpreter'),h.Interpreter='tex';end
        end
    end
    if isprop(h,'DisplayName'),h.DisplayName=mathText(h.DisplayName);end
end
% Legend titles are not included by findall in every MATLAB version.
ll=findall(f,'Type','legend');
for j=1:numel(ll)
    ll(j).Title.String=mathText(ll(j).Title.String);
    ll(j).Title.Interpreter='tex';
end
if ~isempty(findobj(f,'Type','axes','Tag','Fig09f_1'))
    mbeso_mark_fig9_zoom_start(f);
end
setappdata(f,'MBESO_ProfessorFeedbackVersion','2026-10-24-display250-italics');
end

function value=mathText(value)
if iscell(value)
    for k=1:numel(value),value{k}=mathText(value{k});end
elseif isstring(value)
    for k=1:numel(value),value(k)=string(mathText(char(value(k))));end
elseif ischar(value)
    % Idempotent: a prior pass has formatted every mathematical token.
    if contains(value,'{\it '),return;end
    before={'σ′_{e,i}','σ_{e,i}','η′_i','η_i',[char(8134) '_i^{k}'], ...
        'δ_σ','V_k','n_k','V_1','V_2'};
    after={'{\it σ}′_{\it e,i}','{\it σ}_{\it e,i}', ...
        '{\it η}′_{\it i}','{\it η}_{\it i}', ...
        ['{\it ' char(8134) '}_{\it i}^{\it k}'], ...
        '{\it δ}_{\it σ}','{\it V}_{\it k}','{\it n}_{\it k}', ...
        '{\it V}_1','{\it V}_2'};
    for k=1:numel(before),value=strrep(value,before{k},after{k});end
    % Only the standalone compliance symbol, never the word Compliance or Case.
    value=regexprep(value,'(?<![A-Za-z])C(?![A-Za-z])','{\\it C}');
end
end
