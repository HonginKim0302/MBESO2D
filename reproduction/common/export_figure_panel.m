function rows=export_figure_panel(fig,outputDir)
%EXPORT_FIGURE_PANEL Export the native figure at a deterministic paper size.
if ~exist(outputDir,'dir'),mkdir(outputDir);end
panel=fig.Tag;base=fullfile(outputDir,panel);
savefig(fig,[base '.fig']);
print(fig,[base '.png'],'-dpng','-r600');
pdfInfo=export_vector_pdf(fig,[base '.pdf']);
formats={'fig','png','pdf'};
if ispc
    print(fig,[base '.emf'],'-dmeta','-painters');
    originalPaperUnits=fig.PaperUnits;fig.PaperUnits='centimeters';
    emfInfo=normalize_emf_size([base '.emf'],10*fig.PaperSize);
    fig.PaperUnits=originalPaperUnits;
    formats{end+1}='emf';
end
exportInfo=struct('pdf',pdfInfo);
if ispc,exportInfo.emf=emfInfo;end
fid=fopen([base '_export_info.json'],'w');assert(fid>=0);
fwrite(fid,jsonencode(exportInfo,PrettyPrint=true),'char');fclose(fid);
position=fig.Position;
rows=cell(numel(formats),6);
for k=1:numel(formats)
    rows(k,:)={panel,formats{k},fullfile('outputs',[panel '.' formats{k}]), ...
        position(3),position(4),fig.UserData.source_mode};
end
end
