function verification_write_table(T,path)
%REVIEW_WRITE_TABLE CSV with 17 significant digits; MAT remains authoritative.
f=fopen(path,'w','n','UTF-8'); assert(f>=0,'Cannot write %s',path); c=onCleanup(@()fclose(f));
fprintf(f,'%s\n',strjoin(T.Properties.VariableNames,','));
for i=1:height(T)
    vals=cell(1,width(T));
    for j=1:width(T)
        v=T{i,j}; if iscell(v),v=v{1};end
        if isnumeric(v)||islogical(v), vals{j}=sprintf('%.17g',v);
        else, vals{j}=['"' strrep(char(string(v)),'"','""') '"']; end
    end
    fprintf(f,'%s\n',strjoin(vals,','));
end
end
