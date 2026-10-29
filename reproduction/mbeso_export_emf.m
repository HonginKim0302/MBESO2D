function meta=mbeso_export_emf(f,file)
%MBESO_EXPORT_EMF Native editable vector output at the approved paper size.
% MATLAB's enhanced-metafile driver is available on Windows.
if ~ispc,return;end
print(f,file,'-dmeta');
u=f.PaperUnits;f.PaperUnits='centimeters';mm=10*f.PaperSize;f.PaperUnits=u;
meta=mbeso_normalize_emf_size(file,mm);
fid=fopen(strrep(file,'.emf','_emf_metadata.json'),'w','n','UTF-8');assert(fid>=0);
guard=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s',jsonencode(meta));
end
