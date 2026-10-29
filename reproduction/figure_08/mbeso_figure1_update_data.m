function d = mbeso_figure1_update_data(P)
%MBESO_FIGURE1_UPDATE_DATA Select unchanged inputs to updates 1:10.
% P.local preserves the original eleven stored FE input states 0:10.
% Only states 0:9 belong to the ten decisions shown with panel d.
d=P.local;
keep=d.decision_update>=1 & d.decision_update<=10;
names=fieldnames(d); n=numel(d.state_iteration);
for j=1:numel(names)
    v=d.(names{j});
    if isvector(v) && numel(v)==n,d.(names{j})=v(keep);end
end
assert(isequal(d.state_iteration(:),(0:9)'));
assert(isequal(d.decision_update(:),(1:10)'));
end
