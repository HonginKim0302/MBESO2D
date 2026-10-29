% SPDX-License-Identifier: GPL-3.0-or-later
function [fig, summary] = mbeso_plot_cantilever_mesh_utilization(results, exclusion_size_mm)
%MBESO_PLOT_CANTILEVER_MESH_UTILIZATION Assigned-material mesh consistency.
% Rows: mesh resolutions. Left: full solid domain scale. Right: the same
% field with scale extrema evaluated outside physical load/support patches.
% M1: +100*center VM/sigma_m1. M2: -100*center VM/sigma_m2. Void: NaN.
% The sign labels material identity, not local tensile/compressive stress.
% Exclusion changes only statistics/color limits; all solid values are kept.
% Each sign occupies half the colorbar, with actual extrema at the ends.
if nargin<2 || isempty(exclusion_size_mm),exclusion_size_mm=40;end
validateattributes(exclusion_size_mm,{'numeric'},{'scalar','positive','finite'});
if isstruct(results),results=num2cell(results);end
assert(iscell(results)&&~isempty(results),'Provide a nonempty cell array of results.');
[~,order]=sort(cellfun(@(r)size(r.x,2),results));results=results(order);
n=numel(results);width=15.3;height=max(7,1.7+4.7*n);
fig=figure('Color','w','Name','Cantilever mesh consistency: assigned-material utilization', ...
 'NumberTitle','off','Units','centimeters','Position',[2 2 width height], ...
 'PaperUnits','centimeters','PaperSize',[width height], ...
 'PaperPosition',[0 0 width height],'PaperPositionMode','manual', ...
 'DefaultAxesFontName','Times New Roman','DefaultTextFontName','Times New Roman');
rows=cell(n,10);
for row=1:n
 r=results{row};assert(ismatrix(r.x)&&strcmpi(r.settings.bc_case,'cantilever'), ...
  'Only two-dimensional cantilever results are supported.');
 U=mbeso_assigned_material_utilization(r);[ny,nx]=size(r.x);
 validateattributes(r.settings.elSize,{'numeric'},{'scalar','positive','finite'});
 layers=min(min(nx,ny),max(1,ceil(exclusion_size_mm/r.settings.elSize-1e-12)));
 excluded=false(ny,nx);excluded(1:layers,1:layers)=true;
 excluded(end-layers+1:end,1:layers)=true;excluded(end-layers+1:end,end-layers+1:end)=true;
 full=U.solid_mask;regular=full&~excluded;
 m1full=masked_max(U.percent,full&U.tensile_mask);m2full=masked_max(U.percent,full&U.compressive_mask);
 m1regular=masked_max(U.percent,regular&U.tensile_mask);m2regular=masked_max(U.percent,regular&U.compressive_mask);
 plotWidth=4.6;plotHeight=plotWidth*ny/nx;
 y=height-1.05-(row-1)*4.7-plotHeight;
 for col=1:2
  if col==1,scaleMask=full;label='All solid elements';m1=m1full;m2=m2full;
  else,scaleMask=regular;label=sprintf('Outside %.0f x %.0f mm',exclusion_size_mm,exclusion_size_mm);m1=m1regular;m2=m2regular;end
  assert(any(scaleMask(:)&isfinite(U.signed_percent(:))), ...
   'No solid elements remain for the selected scale.');
  scale=mbeso_zero_centered_scale(U.signed_percent,scaleMask);
  x=1.1+(col-1)*7.0;
  ax=axes(fig,'Units','centimeters','Position',[x y plotWidth plotHeight], ...
   'Tag',sprintf('assigned_mesh_%dx%d_%d',nx,ny,col));
  img=imagesc(ax,scale.display_values);img.AlphaData=U.solid_mask;
  axis(ax,'image');axis(ax,'tight');set(ax,'YDir','reverse','XTick',[],'YTick',[], ...
   'FontName','Times New Roman','XColor','k','YColor','k','Color','w','Box','on');
  colormap(ax,scale.colormap);set(ax,'CLim',scale.color_limits);
  title(ax,{sprintf('%d x %d',nx,ny),label},'FontSize',9,'FontWeight','normal','Color','k');
  cb=colorbar(ax);cb.FontName='Times New Roman';cb.FontSize=8;cb.Color='k';
  cb.Ticks=scale.ticks;cb.TickLabels=scale.tick_labels;
  title(cb,'%','FontName','Times New Roman','FontSize',8,'Color','k');
  ax.Position=[x y plotWidth plotHeight];cb.Units='centimeters';
  cb.Position=[x+plotWidth+.13 y .22 plotHeight];
  text(ax,.5,-.12,sprintf('M1 max: %.3f%%; M2 max: %.3f%%',m1,m2), ...
   'Units','normalized','HorizontalAlignment','center','VerticalAlignment','top', ...
   'FontName','Times New Roman','FontSize',8,'Color','k','Clipping','off','Interpreter','none');
  setappdata(ax,'MBESO_AssignedUtilization',U);
  setappdata(ax,'MBESO_ScaleMask',scaleMask);
  setappdata(ax,'MBESO_MaterialMaximaPercent',[m1 m2]);
  setappdata(img,'MBESO_ElementDatatipData',struct('values',U.signed_percent, ...
   'material_map',U.material_map,'quantity',U.definition,'unit','%'));
  setappdata(img,'MBESO_ColorScale',scale);
  if col==2
   hold(ax,'on');zones=[.5 .5; .5 ny-layers+.5; nx-layers+.5 ny-layers+.5];
   for z=1:3,rectangle(ax,'Position',[zones(z,:) layers layers], ...
     'EdgeColor',[.8 0 0],'LineWidth',.9,'Tag','exclusion_40mm');end
  end
 end
 rows(row,:)={nx,ny,r.iterations,r.settings.elSize,layers,layers*r.settings.elSize, ...
   m1full,m2full,m1regular,m2regular};
end
summary=cell2table(rows,'VariableNames',{'nelx','nely','iterations','element_size_mm', ...
 'patch_layers','actual_exclusion_size_mm','assigned_m1_max_full_percent', ...
 'assigned_m2_max_full_percent','assigned_m1_max_excluded_percent','assigned_m2_max_excluded_percent'});
setappdata(fig,'MBESO_AssignedMeshSummary',summary);
setappdata(fig,'MBESO_UtilizationDefinition',U.definition);
setappdata(fig,'MBESO_ExclusionScope','Mesh consistency only; no FE elements or stress values removed.');
mbeso_enable_physical_contour_datatips(fig);
end
function value=masked_max(field,mask)
values=field(mask&isfinite(field));if isempty(values),value=NaN;else,value=max(values);end
end
