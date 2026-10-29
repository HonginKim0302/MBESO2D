function report=mbeso_apply_output_size_mode(folder,mode)
%MBESO_APPLY_OUTPUT_SIZE_MODE Resize individual panels, preserving their data.
% Fonts retain their point sizes. Material maps retain their data aspect ratio.
root=fileparts(mfilename('fullpath'));
if nargin<1,folder=root;end
if nargin<2,mode=mbeso_output_size_mode;end
if ~strcmp(mode,'uniform'),report=table;return;end
backup=fullfile(root,'size_presets','manuscript_original');
manifest=jsondecode(fileread(fullfile(backup,'manifest.json')));
oldPath=path;guard=onCleanup(@()path(oldPath)); %#ok<NASGU>
addpath(root,fullfile(root,'figure_08'),...
    fullfile(root,'figure_09'),fullfile(root,'figure_06'));
rows={};
for j=1:numel(manifest.rows)
 stem=fullfile(root,manifest.rows(j).artifact);
 if ~startsWith(stem,[char(folder) filesep]) || ~isfile([stem '.fig']),continue;end
 target=mbeso_panel_output_size(manifest.rows(j).artifact,'uniform');
 f=openfig([stem '.fig'],'new','invisible');clean=onCleanup(@()close(f));
 f.Units='centimeters';original=f.Position(3:4);
 f.PaperUnits='centimeters';
 already=isappdata(f,'MBESO_OutputSizeMode') && strcmp(getappdata(f,'MBESO_OutputSizeMode'),'uniform') && ...
     max(abs(f.PaperSize-target))<1e-9;
 if ~already
  aa=findall(f,'Type','axes');ll=findall(f,'Type','legend');
  isMaterialPanel=~isempty(findall(f,'Tag','e_material_phase_1')) || ...
      ~isempty(findall(f,'Tag','material_phase_1'));
  mapScale=min(target./original);mapPadding=(target-original*mapScale)/2;
  apos=cell(numel(aa),1);aposCM=apos;lpos=cell(numel(ll),1);laxis=cell(numel(ll),1);oldAxes=cell(numel(ll),1);
  for k=1:numel(aa)
   aa(k).Units='centimeters';aposCM{k}=aa(k).Position;
   aa(k).Units='normalized';apos{k}=aa(k).Position;
  end
  for k=1:numel(ll)
   ll(k).Units='centimeters';lpos{k}=ll(k).Position;
   if ~isempty(ll(k).PlotChildren)
    laxis{k}=ancestor(ll(k).PlotChildren(1),'axes');
    if ~isempty(laxis{k})
     laxis{k}.Units='centimeters';oldAxes{k}=laxis{k}.Position;laxis{k}.Units='normalized';
    end
   end
  end
  fonts=findall(f,'-property','FontSize');sizes=arrayfun(@(h)h.FontSize,fonts);
  f.Position=[f.Position(1:2) target];
  for k=1:numel(aa)
   if isMaterialPanel
    old=aposCM{k};aa(k).Units='centimeters';
    aa(k).Position=[old(1:2)*mapScale+mapPadding old(3:4)*mapScale];
   else
    aa(k).Units='normalized';aa(k).Position=apos{k};
   end
  end
  for k=1:numel(fonts),fonts(k).FontSize=sizes(k);end
  f.PaperUnits='centimeters';f.PaperSize=target;f.PaperPosition=[0 0 target];
  f.PaperPositionMode='manual';f.Resize='on';drawnow;
  % Keep labels of narrow dual-axis graphs inside the requested outer canvas.
  for k=1:numel(aa)
   a=aa(k);a.Units='centimeters';
   if strcmp(a.Visible,'off'),continue;end
   p=a.Position;t=a.TightInset;gap=.06;
   low=max([0 0],[gap gap]-(p(1:2)-t(1:2)));
   high=max([0 0],p(1:2)+p(3:4)+t(3:4)-target+gap);
   if all(p(3:4)-low-high>1)
    a.Position=[p(1:2)+low p(3:4)-low-high];
   end
  end
  % Preserve physical legend text/box sizes instead of stretching their text.
  for k=1:numel(ll)
   old=lpos{k};r=old;
   r(1:2)=[(old(1)+old(3)/2)/original(1)*target(1)-old(3)/2, ...
    (old(2)+old(4)/2)/original(2)*target(2)-old(4)/2];
   if isMaterialPanel
    r(1:2)=(old(1:2)+old(3:4)/2)*mapScale+mapPadding-old(3:4)/2;
   end
   if ~isempty(oldAxes{k}) && all(old(1:2)>=oldAxes{k}(1:2)-.02) && ...
      all(old(1:2)+old(3:4)<=oldAxes{k}(1:2)+oldAxes{k}(3:4)+.02)
    a=laxis{k};a.Units='centimeters';p=a.Position;o=oldAxes{k};
    gaps=[old(1:2)-o(1:2),o(1:2)+o(3:4)-old(1:2)-old(3:4)];
    if gaps(1)<gaps(3),r(1)=p(1)+gaps(1);else,r(1)=p(1)+p(3)-r(3)-gaps(3);end
    r(2)=p(2)+(old(2)+old(4)/2-o(2))/o(4)*p(4)-r(4)/2;
   end
   r(1:2)=max([.06 .06],min(r(1:2),target-r(3:4)-.06));
   ll(k).Units='centimeters';ll(k).Position=r;
  end
  mbeso_apply_lab_style(f);mbeso_place_paper_legends(f);drawnow;
  setappdata(f,'MBESO_OutputSizeMode','uniform');
  setappdata(f,'MBESO_OutputSizeTargetCM',target);
  setappdata(f,'MBESO_OutputSizeOriginalCM',original);
  savefig(f,[stem '.fig']);print(f,[stem '.png'],'-dpng','-r600');
  meta=export_exact_tnr_pdf(f,[stem '.pdf']);mbeso_export_emf(f,[stem '.emf']);
  fid=fopen([stem '_pdf_metadata.json'],'w','n','UTF-8');fprintf(fid,'%s',jsonencode(meta));fclose(fid);
 end
 f.PaperUnits='centimeters';assert(max(abs(f.PaperSize-target))<1e-9);
 rows(end+1,:)={manifest.rows(j).artifact,target(1)*10,target(2)*10,'uniform',true}; %#ok<AGROW>
 clear clean;
end
report=cell2table(rows,'VariableNames',{'artifact','width_mm','height_mm','mode','passed'});
if strcmp(char(folder),root),writetable(report,fullfile(root,'active_output_sizes.csv'));end
fprintf('Default 83 x 64 mm with per-panel size overrides: %d outputs.\n',height(report));
end
