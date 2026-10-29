function reproduce_assignment_strip
%REPRODUCE_ASSIGNMENT_STRIP Draw actual post-update phases for elements 974/5829.
% The CSV was extracted from recorded solver states, not from an image.
% Input state s drives update s+1 on all local panels.
here=fileparts(mfilename('fullpath'));
oldPath=path; restorePath=onCleanup(@()path(oldPath)); %#ok<NASGU>
addpath(fileparts(here),'-begin');
materialPalette=mbeso_reproduction_palette;
out=fullfile(here,'exports');
T=readtable(fullfile(here,'data','panel_d_assignment_inputs.csv'));
assert(height(T)==20 && all(T.matches==1));
assert(all(T.update==T.input_state+1));
combined=openfig(fullfile(out,'figure1_combined.fig'),'new','invisible');
rect=[94/893*151.1,(1003-889)/1003*169.9,326/893*151.1,117/1003*169.9];
drawStrip(combined,rect,T,materialPalette);
saveAll(combined,fullfile(out,'Fig08_graphs'));close(combined);
page=rect(3:4)+[22 21];
f=figure('Visible','off','Color','white','Units','centimeters','Position',[1 1 page/10], ...
    'PaperUnits','centimeters','PaperSize',page/10,'PaperPosition',[0 0 page/10], ...
    'PaperPositionMode','manual','InvertHardcopy','off','Name','Figure 8(d)','Resize','on');
drawStrip(f,[16 16 rect(3:4)],T,materialPalette);
saveAll(f,fullfile(out,'Fig08_panel_d'));close(f);
end

function drawStrip(f,rect,T,materialPalette)
a=axes(f,'Units','centimeters','Position',rect/10,'PositionConstraint','innerposition', ...
    'Tag','panel_d','FontName','Times New Roman','FontSize',9,'XColor','k','YColor','k', ...
    'XLim',[.5 10.5],'YLim',[.5 2.5],'YDir','reverse','YTick',[1 2], ...
    'YTickLabel',{'974','5829'},'XTick',[1 2 4 6 8 10],'Box','off');hold(a,'on');
colors=materialPalette.map;elements=[974 5829];
phases=zeros(2,10);
for row=1:2
    q=T(T.element==elements(row),:);q=sortrows(q,'update');
    assert(isequal(q.update,(1:10)'));phases(row,:)=q.actual_material_after_update';
    for k=1:10
        patch(a,k+[-.5 .5 .5 -.5],row+[-.31 -.31 .31 .31],colors(phases(row,k)+1,:), ...
            'EdgeColor',[.7 .7 .7],'LineWidth',.4,'Tag',sprintf('phase_%d_update_%d',elements(row),k));
    end
end
a.UserData=struct('element_ids',elements,'updates',1:10,'phase_after_update',phases);
xlabel(a,'Iteration');ylabel(a,'Element');
h=gobjects(1,3);order=[2 3 1];
for j=1:3,h(j)=patch(a,nan,nan,colors(order(j),:));end
lg=legend(a,h,{'Tensile','Compressive','Void'},'Orientation','horizontal','NumColumns',3, ...
    'Location','southoutside','FontName','Times New Roman','FontSize',8,'TextColor','k', ...
    'Box','on','Color','white','EdgeColor',[.84 .86 .88]);
lg.ItemTokenSize=[8 7];a.Position=rect/10;
lg.Units='centimeters';p=lg.Position;p(2)=max(.05,rect(2)/10-1.4);lg.Position=p;
end

function saveAll(f,stem)
mbeso_black_text(f);set(findall(f,'-property','FontName'),'FontName','Times New Roman');
drawnow;savefig(f,[stem '.fig']);print(f,[stem '.png'],'-dpng','-r600');
export_exact_tnr_pdf(f,[stem '.pdf']);
mbeso_export_emf(f,[stem '.emf']);
end
