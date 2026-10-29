function meta=mbeso_normalize_emf_size(file,paperMM)
%MBESO_NORMALIZE_EMF_SIZE Correct native EMF physical size, preserving records.
% MATLAB records display coordinates at ScreenPixelsPerInch, but its EMF
% header may describe the monitor's physical dimensions at a different DPI.
% Normalize BOTH the frame and reference device. Changing only Frame scales
% the drawing incorrectly when applications replay it into a target rectangle.
fid=fopen(file,'rb');assert(fid>=0);bytes=fread(fid,Inf,'*uint8');fclose(fid);
assert(typecast(bytes(1:4),'uint32')==1,'Not an EMF header.');
headerLength=double(typecast(bytes(5:8),'uint32'));
assert(headerLength>=88 && all(paperMM>0));before=bytes;
frame=int32([0 0 round(100*paperMM)]);
dpi=get(groot,'ScreenPixelsPerInch');
device=int32([round(100*dpi) round(100*dpi)]);
bytes(25:40)=typecast(frame,'uint8');
bytes(73:80)=typecast(device,'uint8');
bytes(81:88)=typecast(int32([2540 2540]),'uint8');
if headerLength>=108
    bytes(101:108)=typecast(int32([2540000 2540000]),'uint8');
end
assert(isequal(bytes(headerLength+1:end),before(headerLength+1:end)), ...
    'EMF drawing records must remain byte-identical.');
fid=fopen(file,'wb');assert(fid>=0);fwrite(fid,bytes,'uint8');fclose(fid);
meta=struct('paper_mm',paperMM,'emf_frame_mm',double(frame(3:4))/100, ...
    'reference_dpi',dpi,'drawing_records_unchanged',true, ...
    'frame_quantization_mm',.01);
end
