function D=read_figure_data
%READ_FIGURE_DATA Load numerical histories and verify the plotted decisions.
root=fileparts(fileparts(mfilename('fullpath')));
assert(~isfile(fullfile(root,'PREPARATION_INCOMPLETE.txt')),'The data preparation is incomplete.');
A=load(fullfile(root,'figure_06','data','figure_data.mat'),'F6');A=A.F6;
B=load(fullfile(root,'figure_07','data','figure_data.mat'),'F7');B=B.F7;
D=struct('palette',read_material_palette,'source_mode','recorded_data');
source=fullfile(root,'data_source.json');
if isfile(source)
    metadata=jsondecode(fileread(source));D.source_mode=char(metadata.source_mode);
end
D.state=double(A.response_state(:));D.update=double(B.updates(:));
D.local_update=double(A.decision_update(:));D.epsilon_MPa=double(B.epsilon_MPa(:));
assert(isequal(D.state,(0:214)') && isequal(double(B.states(:)),D.state));
assert(isequal(D.update,(1:214)') && isequal(D.local_update,(1:10)'));
assert(isequal(D.epsilon_MPa,[0 .005 .05 .5 5]'));
assert(isequal(size(B.phase),[6000 215 5]) && all(ismember(B.phase(:),uint8([0 1 2]))));
D.C=double(A.C_Nmm(:));D.nk=double(A.normalization_coefficient(:));
D.rawStress=double(A.unfiltered_indicator_MPa(:));D.filteredStress=double(A.filtered_indicator_MPa(:));
D.score974=double(A.history_score(:,1));D.score5829=double(A.history_score(:,2));
D.threshold=double(A.retention_threshold(:));
D.assignments=double(A.material_assignment);D.materialState10=double(A.material_state10);
assert(max(abs(D.C-double(B.C_Nmm(:,1))))<1e-10);
assert(max(abs(double(B.C_Nmm(:))-double(B.reference_C_Nmm(:))))<1e-10);
assert(isequal(D.assignments,double(B.phase([974 5829],2:11,1))));
assert(isequal(D.materialState10,double(reshape(B.phase(:,11,1),60,100))));
retained=[D.score974 D.score5829]>=D.threshold;
assert(isequal(retained,D.assignments'>0),'The selection scores and material states disagree.');
predicted=zeros(10,1);predicted(retained(:,1))=2-double(D.filteredStress(retained(:,1))>=0);
assert(isequal(predicted,D.assignments(1,:)'),'The filtered indicator and material assignment disagree.');
D.countsSVTC=zeros(5,2);D.layoutSVTC=zeros(5,2);D.initialSVTC=zeros(5,2);
baseline=B.phase(:,end,1);
for k=1:5
    before=B.phase(:,1:end-1,k);after=B.phase(:,2:end,k);
    sv=sum((before>0)~=(after>0),1)';
    tc=sum(before>0 & after>0 & before~=after,1)';
    assert(isequal(sv,double(B.reference_N_SV(:,k))));
    assert(isequal(tc,double(B.reference_N_TC(:,k))));
    D.countsSVTC(k,:)=[sum(sv),sum(tc)];D.initialSVTC(k,:)=[sv(1),tc(1)];
    current=B.phase(:,end,k);common=baseline>0 & current>0;
    assert(any(common),'No common solids for material comparison.');
    D.layoutSVTC(k,:)=[100*sum((baseline>0)~=(current>0))/6000, ...
        100*sum(baseline(common)~=current(common))/sum(common)];
    if k==1
        fractions=100*[sum(after>0,1)' sum(after==1,1)' sum(after==2,1)']/6000;
        assert(max(abs(fractions-double(B.baseline_volume_percent)),[],'all')<1e-10);
        D.solid=double(B.baseline_volume_percent(:,1));
        D.tensile=double(B.baseline_volume_percent(:,2));
        D.compressive=double(B.baseline_volume_percent(:,3));
        D.transitionsSV=sv;D.transitionsTC=tc;
    end
end
D.deadband=double(B.compliance_difference_percent);
assert(max(abs(D.deadband-100*(double(B.C_Nmm)./double(B.C_Nmm(:,1))-1)),[],'all')<1e-10);
assert(numel(D.C)==215 && numel(D.nk)==215 && isequal(size(D.deadband),[215 5]));
assert(all(isfinite([D.C;D.nk;D.rawStress;D.filteredStress;D.score974;D.score5829;D.threshold])));
assert(all(isfinite(D.deadband),'all') && max(abs(D.solid-D.tensile-D.compressive))<1e-10);
D.provenance=struct('local_history','figure_06/data/figure_data.mat', ...
    'material_history','figure_07/data/figure_data.mat','initial_update_included',true,'last_state',214);
end
