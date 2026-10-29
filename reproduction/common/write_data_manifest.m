function write_data_manifest(root)
%WRITE_DATA_MANIFEST Record identities of the two numerical figure datasets.
files={'figure_06/data/figure_data.mat';'figure_07/data/figure_data.mat'};
bytes=zeros(2,1);hashes=cell(2,1);
for k=1:2
    full=fullfile(root,files{k});item=dir(full);bytes(k)=item.bytes;hashes{k}=file_sha256(full);
end
writetable(table(files,bytes,hashes,'VariableNames',{'relative_path','bytes','sha256'}),fullfile(root,'data_manifest.csv'));
end
