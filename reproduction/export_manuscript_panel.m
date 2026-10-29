function export_manuscript_panel(source,stem,figureNumber,panel)
%EXPORT_MANUSCRIPT_PANEL Apply the final Word placement to a native MATLAB plot.
% Only physical geometry and type size change; data coordinates stay intact.
% Word source-rectangle cropping removes blank margins, not data samples.
root=fileparts(mfilename('fullpath'));
G=readtable(fullfile(root,'manuscript_panel_geometry.csv'),'TextType','string');
row=G.manuscript_figure==figureNumber & G.panel==string(panel);
assert(nnz(row)==1,'A unique manuscript panel geometry is required.');g=G(row,:);
f=openfig(source,'new','invisible');clean=onCleanup(@()close(f)); %#ok<NASGU>
f.Units='centimeters';original=f.Position(3:4);
target=[g.width_mm g.height_mm]/10;
crop=[g.crop_left_fraction g.crop_bottom_fraction g.crop_right_fraction g.crop_top_fraction];
fullSize=target./[1-crop(1)-crop(3),1-crop(2)-crop(4)];
scale=fullSize./original;offset=fullSize.*crop(1:2);
aa=findall(f,'Type','axes');ll=findall(f,'Type','legend');
positions=cell(numel(aa),1);legends=cell(numel(ll),1);
for k=1:numel(aa),aa(k).Units='centimeters';positions{k}=aa(k).Position;end
for k=1:numel(ll),ll(k).Units='centimeters';legends{k}=ll(k).Position;end
fonts=findall(f,'-property','FontSize');sizes=zeros(numel(fonts),1);depth=sizes;
for k=1:numel(fonts)
    sizes(k)=fonts(k).FontSize;h=fonts(k);
    while isgraphics(h)&&~isequal(h,f),depth(k)=depth(k)+1;h=h.Parent;end
end
f.Position=[f.Position(1:2) target];
[~,order]=sort(depth);
for k=order(:)',fonts(k).FontSize=sizes(k)*sqrt(prod(scale));end
for k=1:numel(aa)
    p=positions{k};aa(k).Position=[p(1:2).*scale-offset,p(3:4).*scale];
end
for k=1:numel(ll)
    p=legends{k};ll(k).Position=[p(1:2).*scale-offset,p(3:4).*scale];
end
f.PaperUnits='centimeters';f.PaperSize=target;
f.PaperPosition=[0 0 target];f.PaperPositionMode='manual';f.Resize='on';
setappdata(f,'ManuscriptPlacement',table2struct(g));
setappdata(f,'ManuscriptSourceCanvasCM',original);
setappdata(f,'ManuscriptPlacementScale',scale);
drawnow;
savefig(f,[stem '.fig']);print(f,[stem '.png'],'-dpng','-r600');
oldPath=path;guard=onCleanup(@()path(oldPath)); %#ok<NASGU>
addpath(fullfile(root,'figure_06'),'-begin');
export_exact_tnr_pdf(f,[stem '.pdf']);mbeso_export_emf(f,[stem '.emf']);
end
