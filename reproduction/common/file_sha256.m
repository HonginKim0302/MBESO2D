function value=file_sha256(file)
%FILE_SHA256 Hash a data or source file without loading it into MATLAB arrays.
fid=fopen(file,'rb');assert(fid>=0);guard=onCleanup(@()fclose(fid)); %#ok<NASGU>
md=java.security.MessageDigest.getInstance('SHA-256');
while true
    bytes=fread(fid,1024*1024,'*uint8');if isempty(bytes),break;end
    md.update(typecast(bytes,'int8'));
end
value=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
end
