function meta=export_vector_pdf(fig,pdfPath)
% Export vector PDF with embedded fonts and an exact, uncropped page size.
% Standalone MATLAB R2024b helper. No external executable or toolbox needed.
% Times New Roman must already be assigned to all figure text. Prefer Unicode
% Greek characters with TeX subscripts over TeX Greek commands, which select
% MATLAB's separate mathematical font. This function never rescales data.
oldUnits=fig.PaperUnits;fig.PaperUnits='centimeters';pageMM=10*fig.PaperSize;fig.PaperUnits=oldUnits;
boundary=annotation(fig,'rectangle',[0 0 1 1],'Units','normalized', ...
 'Color','white','LineWidth',.01,'Tag','temporary_pdf_page_boundary');
cleanup=onCleanup(@()removeBoundary(boundary));
exportgraphics(fig,pdfPath,'ContentType','vector','BackgroundColor','white');
removeBoundary(boundary);clear cleanup;

% exportgraphics embeds the actual TrueType font but integer-rounds its PDF
% page boxes. Only the page dictionary is updated; content streams, positions
% and font resources remain byte-for-byte unchanged.
fid=fopen(pdfPath,'rb');assert(fid>=0);bytes=fread(fid,Inf,'*uint8')';fclose(fid);raw=char(bytes);
objects=regexp(raw,'(?ms)^(\d+) 0 obj\s*(.*?)\s*endobj','tokens');page=[];
for j=1:numel(objects)
 if ~isempty(regexp(objects{j}{2},'/Type\s*/Page\s','once')),page=objects{j};break;end
end
assert(~isempty(page),'Expected an explicit single-page PDF dictionary.');
id=str2double(page{1});body=page{2};pt=pageMM*72/25.4;
box=regexp(body,'/MediaBox\s*\[([^\]]+)\]','tokens','once');originalBox=sscanf(box{1},'%f')';
for kind={'MediaBox','CropBox','BleedBox','TrimBox'}
 expression=['/',kind{1},'\s*\[[^\]]*\]'];replacement=sprintf('/%s [0 0 %.12f %.12f]',kind{1},pt);
 body=regexprep(body,expression,replacement);
end
trailers=regexp(raw,'(?s)trailer\s*(<<.*?>>)\s*startxref\s*(\d+)','tokens');old=trailers{end};
trailer=regexprep(old{1},'>>\s*$',sprintf('  /Prev %s\n>>',old{2}));
object=sprintf('\n%d 0 obj\n%s\nendobj\n',id,body);offset=numel(bytes)+1;
xrefOffset=numel(bytes)+numel(object);
tail=sprintf('xref\n%d 1\n%010d 00000 n \ntrailer\n%s\nstartxref\n%d\n%%%%EOF\n',id,offset,trailer,xrefOffset);
fid=fopen(pdfPath,'ab');assert(fid>=0);fwrite(fid,uint8([object,tail]),'uint8');fclose(fid);
fontTokens=regexp(raw,'/BaseFont\s*/([^\s/<>]+)','tokens');fonts=unique(cellfun(@(x)x{1},fontTokens,'UniformOutput',false));
meta=struct('page_mm',pageMM,'raw_page_box_points',originalBox,'font_names',{fonts}, ...
 'font_file_count',numel(regexp(raw,'/FontFile\d?\s+\d+\s+0\s+R','match')), ...
 'raster_image_count',numel(regexp(raw,'/Subtype\s*/Image\b','match')), ...
 'content_rescaled',false,'native_figure_changed',false, ...
 'device_coordinate_quantization_mm',25.4/get(groot,'ScreenPixelsPerInch'));
assert(meta.font_file_count>0,'No embedded font file found in vector PDF.');
assert(meta.raster_image_count==0,'Unexpected raster image in this line-art PDF.');
end
function removeBoundary(h)
if isgraphics(h),delete(h);end
end
