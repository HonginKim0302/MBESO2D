function F7=prepare_figure_07_data(sourceRoot,outputDir)
%PREPARE_FIGURE_07_DATA Extract common states and recount all updates 1--214.
ids={'cantilever_eps_0','cantilever_eps_0p005','cantilever_eps_0p05','cantilever_eps_0p5','cantilever_eps_5'};
epsilon=[0 .005 .05 .5 5];
F7=struct('states',(0:214)','updates',(1:214)','epsilon_MPa',epsilon, ...
    'phase',zeros(6000,215,5,'uint8'),'C_Nmm',zeros(215,5), ...
    'reference_C_Nmm',zeros(215,5),'reference_N_TC',zeros(214,5), ...
    'reference_N_SV',zeros(214,5),'first_stop',zeros(5,1),'mesh_size',[60 100]);
sourcePaths=cell(10,1);sourceHashes=cell(10,1);
for k=1:5
    relative=fullfile('zero_history',ids{k},'full_history.mat');
    file=fullfile(sourceRoot,relative);loaded=load(file,'data');d=loaded.data;
    assert(d.cfg.nelx==100 && d.cfg.nely==60 && d.n_updates>=214);
    assert(d.cfg.options.material_zero_tolerance==epsilon(k));
    F7.phase(:,:,k)=uint8(d.phase(:,1:215));F7.C_Nmm(:,k)=d.C(1:215);
    F7.first_stop(k)=d.first_stop;
    csvRelative=fullfile('zero_history',ids{k},'state_history.csv');
    csvFile=fullfile(sourceRoot,csvRelative);T=readtable(csvFile,'TextType','string');
    [found,index]=ismember((0:214)',T.state);assert(all(found) && isequal(index,(1:215)'));
    F7.reference_C_Nmm(:,k)=T.C_Nmm(index);
    F7.reference_N_TC(:,k)=T.N_TC(index(2:end));F7.reference_N_SV(:,k)=T.N_SV(index(2:end));
    before=F7.phase(:,1:214,k);after=F7.phase(:,2:215,k);
    assert(isequal(sum(before>0 & after>0 & before~=after,1)',F7.reference_N_TC(:,k)));
    assert(isequal(sum((before>0)~=(after>0),1)',F7.reference_N_SV(:,k)));
    assert(isequal(F7.C_Nmm(:,k),F7.reference_C_Nmm(:,k)));
    sourcePaths{2*k-1}=strrep(relative,'\','/');sourceHashes{2*k-1}=file_sha256(file);
    sourcePaths{2*k}=strrep(csvRelative,'\','/');sourceHashes{2*k}=file_sha256(csvFile);
end
assert(all(ismember(F7.phase(:),uint8([0 1 2]))));
assert(all(isfinite(F7.C_Nmm(:))) && all(F7.C_Nmm(:)>0));
F7.compliance_difference_percent=100*(F7.C_Nmm./F7.C_Nmm(:,1)-1);
after=F7.phase(:,2:215,1);
F7.baseline_volume_percent=100*[sum(after>0,1)' sum(after==1,1)' sum(after==2,1)']/6000;
if ~isfolder(outputDir),mkdir(outputDir);end
save(fullfile(outputDir,'figure_data.mat'),'F7','-v7');
writetable(table(sourcePaths,sourceHashes,'VariableNames',{'source_relative_path','sha256'}),fullfile(outputDir,'source_manifest.csv'));
end
