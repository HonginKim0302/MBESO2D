function manifest=review_source_manifest(repoRoot)
% Include nested validation helpers while excluding generated result copies.
repoRoot=char(java.io.File(char(repoRoot)).getCanonicalPath());
dirs={'src','review_validation','visualization'}; rel={}; sha={};
for k=1:numel(dirs)
    files=dir(fullfile(repoRoot,dirs{k},'**','*.m'));
    for j=1:numel(files)
        file=fullfile(files(j).folder,files(j).name);
        relative=strrep(file(numel(repoRoot)+2:end),'\','/');
        parts=strsplit(lower(relative),'/');
        if any(ismember(parts,{'results','source_snapshot','source_snapshots','snapshots','archived_reference'})),continue;end
        rel{end+1,1}=relative; %#ok<AGROW>
        sha{end+1,1}=review_sha256(fullfile(files(j).folder,files(j).name),true); %#ok<AGROW>
    end
end
if isfile(fullfile(repoRoot,'REPRODUCE_Revision3.m'))
    rel{end+1,1}='REPRODUCE_Revision3.m';sha{end+1,1}=review_sha256(fullfile(repoRoot,'REPRODUCE_Revision3.m'),true);
end
manifest=table(string(rel),string(sha),'VariableNames',{'relative_path','sha256'});
manifest=sortrows(manifest,'relative_path');
end
