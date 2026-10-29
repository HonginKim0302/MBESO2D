function D = submitted_plot_data()
%SUBMITTED_PLOT_DATA Read submitted vectors and recount archived material maps.
% All paths are relative to this function, independent of the working folder.
here=fileparts(mfilename('fullpath'));
repro=fileparts(here);
raw=fullfile(here,'original_plot');
D=struct();
D.palette=readMaterialPalette(repro);
isFresh=isfile(fullfile(repro,'fresh_source.json'));
D.source_mode='recorded_submission';
if isFresh,D.source_mode='fresh_history';end
D.state=(0:214)'; D.update=(1:214)'; D.local_update=(1:10)';
D.epsilon_MPa=[0 .005 .05 .5 5]';
if ~isFresh
D.C=load(fullfile(raw,'Fig_6a_C.txt'));
D.nk=load(fullfile(raw,'Fig_6a_nk.txt'));
D.rawStress=load(fullfile(raw,'Fig_6b_Unfiltered.txt'));
D.filteredStress=load(fullfile(raw,'Fig_6b_Filtered.txt'));
D.score974=load(fullfile(raw,'Fig_6c_Score974.txt'));
D.score5829=load(fullfile(raw,'Fig_6c_Score5829.txt'));
D.threshold=load(fullfile(raw,'Fig_6c_Threshold.txt'));
D.solid=load(fullfile(raw,'Fig_7a_SolidVol.txt'));
D.tensile=load(fullfile(raw,'Fig_7a_TensVol.txt'));
D.compressive=load(fullfile(raw,'Fig_7a_CompVol.txt'));
D.transitionsSV=load(fullfile(raw,'Fig_7b_N_SV.txt'));
D.transitionsTC=load(fullfile(raw,'Fig_7b_N_TC.txt'));
D.deadband=load(fullfile(raw,'Fig_7c_Deadband.txt'));
end
L=load(fullfile(repro,'figure_09','data','source_states_0_214.mat'),'S'); S=L.S;
assert(isequal(double(S.states(:)),D.state),'Expected archived states 0:214.');
assert(isequal(double(S.epsilon_MPa(:)),D.epsilon_MPa),'Unexpected deadband order.');
assert(isequal(size(S.phase),[6000 215 5]),'Unexpected archived phase dimensions.');
D.countsSVTC=zeros(5,2); D.layoutSVTC=zeros(5,2); D.initialSVTC=zeros(5,2);
base=S.phase(:,end,1);
for k=1:5
    before=S.phase(:,1:end-1,k); after=S.phase(:,2:end,k);
    sv=sum((before>0)~=(after>0),1)';
    tc=sum(before>0 & after>0 & before~=after,1)';
    assert(isequal(tc,double(S.reference_N_TC(:,k))));
    assert(isequal(sv,double(S.reference_N_SV(:,k))));
    D.countsSVTC(k,:)=[sum(sv),sum(tc)];
    D.initialSVTC(k,:)=[sv(1),tc(1)];
    final=S.phase(:,end,k); common=base>0 & final>0;
    D.layoutSVTC(k,:)=[100*sum((base>0)~=(final>0))/numel(base), ...
        100*sum(base(common)~=final(common))/sum(common)];
    if k==1
        if isFresh
            D.transitionsSV=sv;D.transitionsTC=tc;
            D.solid=100*sum(after>0,1)'/6000;
            D.tensile=100*sum(after==1,1)'/6000;
            D.compressive=100*sum(after==2,1)'/6000;
        else
            assert(isequal(sv,D.transitionsSV) && isequal(tc,D.transitionsTC));
            assert(max(abs(100*sum(after>0,1)'/6000-D.solid))<1e-10);
            assert(max(abs(100*sum(after==1,1)'/6000-D.tensile))<1e-10);
            assert(max(abs(100*sum(after==2,1)'/6000-D.compressive))<1e-10);
        end
        D.assignments=double(S.phase([974 5829],2:11,1));
        D.materialState10=reshape(S.phase(:,11,1),60,100);
    end
end
expectedCounts=[5200 5725;5392 6607;5360 5770;5000 4734;5138 4033];
expectedLayout=[0 0;1.86666666666667 .170648464163823;1 .126582278481013; ...
    1.86666666666667 .383959044368601;8.33333333333333 1.44186046511628];
if ~isFresh
    assert(isequal(D.countsSVTC,expectedCounts),'Submitted cumulative totals differ from archived states.');
    assert(max(abs(D.layoutSVTC-expectedLayout),[],'all')<1e-11);
end
L=load(fullfile(repro,'figure_08','data','plot_inputs.mat'),'P'); P=L.P;
if isFresh
    D.C=P.response.C_Nmm(:);D.nk=P.response.nk(:);
else
    assert(max(abs(P.response.C_Nmm(:)-D.C))<1e-10);
    assert(max(abs(P.response.nk(:)-D.nk))<1e-10);
end
local=P.local; pick=local.decision_update>=1 & local.decision_update<=10;
fields={'trace_raw_974_MPa','trace_filtered_974_MPa','eta_temporal_974','eta_temporal_5829','selection_cutoff'};
dest={'rawStress','filteredStress','score974','score5829','threshold'};
for k=1:numel(fields)
    value=local.(fields{k});
    if isFresh,D.(dest{k})=double(value(pick));
    else,assert(max(abs(double(value(pick))-D.(dest{k})))<1e-10);end
end
assert(isequal(D.materialState10,P.material.phase));
L=load(fullfile(repro,'figure_09','data','plot_inputs_214.mat'),'P');
if isFresh,D.deadband=L.P.C_change_same_state_percent;
else,assert(max(abs(L.P.C_change_same_state_percent-D.deadband),[],'all')<1e-10);end
D.provenance=struct('vectors','original_plot/*.txt', ...
    'material_states','../figure_09/data/source_states_0_214.mat', ...
    'local_fields','../figure_08/data/plot_inputs.mat', ...
    'initial_update_included',true,'last_state',214);
if isFresh,D.provenance.vectors='freshly prepared MAT inputs';end
assert(numel(D.C)==215 && numel(D.nk)==215 && isequal(size(D.deadband),[215 5]));
assert(all(isfinite(D.C)) && all(isfinite(D.nk)) && all(isfinite(D.deadband),'all'));
assert(max(abs(D.solid-D.tensile-D.compressive))<1e-10);
end

function palette=readMaterialPalette(repro)
% Resolve the parent adapter from this bundle, including standalone support.
helper=fullfile(repro,'mbeso_reproduction_palette.m');
assert(isfile(helper),'The reproduction material palette adapter is missing.');
oldPath=path;
restorePath=onCleanup(@()path(oldPath)); %#ok<NASGU>
addpath(repro,'-begin');
assert(strcmp(which('mbeso_reproduction_palette'),helper), ...
    'Unexpected reproduction material palette on the MATLAB path.');
palette=mbeso_reproduction_palette();
end
