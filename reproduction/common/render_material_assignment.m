function fig=render_material_assignment(D,showWindows)
%RENDER_MATERIAL_ASSIGNMENT Editable Fig.6(b) assignment table and state-10 map.
% Numeric material states are identical to the recorded data; native layout is
% reconstructed, not a pixel copy of the PowerPoint arrangement.
if nargin<2,showWindows=false;end
assert(isequal(size(D.assignments),[2 10]) && isequal(size(D.materialState10),[60 100]));
colors=D.palette.map;
fig=figure('Visible','off','Name','Fig06_b','NumberTitle','off','Color','w', ...
    'WindowStyle','normal','Units','pixels','Position',[100 100 560 400], ...
    'Renderer','painters','Tag','Fig06_b','InvertHardcopy','off');
fig.UserData=struct('panel','Fig06_b','source_mode',D.source_mode,'data_end',10);
ax=axes('Parent',fig,'Position',[.06 .69 .9 .25],'Tag','Fig06_b_assignment_table');
hold(ax,'on');axis(ax,[-1.4 10.7 0 3.8]);axis(ax,'off');
text(ax,-1.25,2.75,'Element','FontName','Times New Roman','FontSize',14);
text(ax,5.5,3.6,'Iteration','FontName','Times New Roman','FontSize',14,'HorizontalAlignment','center');
for k=1:10
    text(ax,k,2.75,sprintf('%d',k),'FontName','Times New Roman','FontSize',14,'HorizontalAlignment','center');
end
for row=1:2
    y=2.7-row;ids=[974 5829];
    text(ax,-1.1,y,sprintf('%d',ids(row)),'FontName','Times New Roman','FontSize',14);
    for k=1:10
        rectangle(ax,'Position',[k-.22 y-.22 .44 .44], ...
            'FaceColor',colors(D.assignments(row,k)+1,:),'EdgeColor',[.3 .3 .3], ...
            'Tag',sprintf('assignment_%d_%d',ids(row),k));
    end
end
ax.UserData=struct('element_ids',[974 5829],'updates',1:10,'phase',D.assignments);
map=axes('Parent',fig,'Position',[.06 .10 .64 .46],'Tag','Fig06_b_material_state10');
hold(map,'on');
for phase=1:2
    [r,c]=find(D.materialState10==phase);
    patch(map,[c'-.5;c'+.5;c'+.5;c'-.5],[r'-.5;r'-.5;r'+.5;r'+.5], ...
        colors(phase+1,:),'EdgeColor','none','Tag',sprintf('material_phase_%d',phase));
end
map.UserData=struct('phase',D.materialState10,'state',10,'source_column',11);
plot(map,[.5 100.5 100.5 .5 .5],[.5 .5 60.5 60.5 .5],'k-','LineWidth',.8);
for id=[974 5829]
    [r,c]=ind2sub([60 100],id);
    plot(map,c,r,'ko','MarkerFaceColor','w','MarkerSize',4,'LineWidth',1);
    if id==974,labelX=30;else,labelX=80;end
    plot(map,[c c labelX],[r -5 -5],'k-','Clipping','off');
    text(map,labelX,-10,sprintf('%d',id),'FontName','Times New Roman','FontSize',14, ...
        'HorizontalAlignment','center','Clipping','off');
end
set(map,'YDir','reverse','DataAspectRatio',[1 1 1],'XLim',[.5 100.5],'YLim',[.5 60.5],'Visible','off');
key=axes('Parent',fig,'Position',[.73 .13 .26 .44],'Tag','Fig06_b_key');
axis(key,[0 1 0 1]);axis(key,'off');hold(key,'on');
text(key,0,.94,{'Material assignment','at iteration 10'},'FontName','Times New Roman','FontSize',13, ...
    'VerticalAlignment','top');
labels={'Tensile material','Compressive material','Void'};phases=[1 2 0];
for k=1:3
    y=.56-.2*(k-1);
    rectangle(key,'Position',[0 y-.03 .09 .07],'FaceColor',colors(phases(k)+1,:), ...
        'EdgeColor',[.3 .3 .3]);
    text(key,.13,y,labels{k},'FontName','Times New Roman','FontSize',11,'VerticalAlignment','middle');
end
set(fig,'PaperUnits','inches','PaperSize',[560 400]/96, ...
    'PaperPosition',[0 0 560 400]/96,'PaperPositionMode','manual');
drawnow;if showWindows,fig.Visible='on';end
end
