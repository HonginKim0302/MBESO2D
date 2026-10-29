function h=verification_sha256(value,isfile)
%REVIEW_SHA256 SHA-256 of bytes on disk or UTF-8 text.
if nargin<2,isfile=false;end
if isfile
    f=fopen(value,'rb'); assert(f>=0); c=onCleanup(@()fclose(f)); bytes=fread(f,Inf,'*uint8');
else
    bytes=unicode2native(char(value),'UTF-8');
end
md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
end
