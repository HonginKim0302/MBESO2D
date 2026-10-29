function predicted=review_independent_update(snapshot)
%REVIEW_INDEPENDENT_UPDATE Replay one frozen production-input update.
% No production update, filter, normalization, selection, or classification
% function is called. No access to snapshot.production is made.
% Scope: regular cantilever ranking and fixed-solid bridge parity ranking;
% the separate cantilever even-count hysteresis branch is explicitly excluded.
% Independent shifted-neighbour accumulation replaces sparse H*field.
a=snapshot.inputs;o=a.review;[ny,nx]=size(a.x);ne=nx*ny;
assert(strcmp(o.stress_measure,'center'),'Baseline replay currently covers center-stress driving fields.');
assert(strcmp(o.tie_policy,'index'),'Baseline replay declares exact ties ordered by ascending linear element index.');
assert(~(strcmp(snapshot.solver,'mbeso')&&a.even_keep_count), ...
    'Cantilever parity/hysteresis branch is outside the declared replay scope.');
s1=max(a.materials.sigma_m1,1e-6);s2=max(a.materials.sigma_m2,1e-6);
er=min(max(a.er,1e-3),.999);
ratio=abs(s1)/abs(s2);
exponentSteps=log(a.target_volume)/log(1-er);
nk=min(a.previous_nk*ratio^(1/exponentSteps),ratio);
eta=a.utilization_vm/s2; positive=a.sigma_raw>=0;
if strcmpi(a.tension_eta_mode,'with_nk'),den=max(nk*s2,1e-12);else,den=s1;end
eta(positive)=a.utilization_vm(positive)/den;
etaSpace=neighbourAverage(eta,a.r2_elements);
if snapshot.iteration==1,score=etaSpace;else,score=(a.previous_eta_spatial+etaSpace)/2;end
traceSpace=neighbourAverage(a.sigma_raw,a.r1_elements);
volume=max(a.previous_volume*(1-a.er),a.target_volume);
target=volume*ne;
switch o.volume_rounding
    case 'floor',target=floor(target);
    case 'round',target=round(target);
    case 'ceil',target=ceil(target);
    otherwise,error('Undeclared rounding option.');
end
keep=false(ny,nx);cutoff=-Inf;margin=NaN;boundaryTies=0;
if strcmp(snapshot.solver,'mbeso')
    target=max(1,min(target,nnz(a.design_mask)));
    effective=target; candidates=find(a.design_mask);freeCount=target;
else
    fixed=nnz(a.fixed_solid_mask); candidates=find(a.free_design_mask);
    freeCount=max(0,min(target-fixed,numel(candidates)));
    if a.even_keep_count && mod(freeCount,2)==1
        if freeCount<numel(candidates),freeCount=freeCount+1;else,freeCount=freeCount-1;end
    end
    effective=fixed+freeCount;keep(a.fixed_solid_mask)=true;
end
% Lexicographic (-score, global id) states the tie rule explicitly.
if freeCount>0
    key=[-score(candidates),double(candidates)];
    [~,order]=sortrows(key,[1 2]); ranked=candidates(order);
    chosen=ranked(1:freeCount);keep(chosen)=true;cutoff=score(chosen(end));
    boundaryTies=nnz(score(candidates)==cutoff);
    if freeCount<numel(ranked),margin=cutoff-score(ranked(freeCount+1));end
end
allowed=a.design_mask|a.fixed_solid_mask;keep=keep & allowed;
x=a.xmin*ones(ny,nx);x(keep)=1;
phase=zeros(ny,nx);phase(keep)=2;phase(keep & traceSpace>=0)=1;
epsilon=o.material_zero_tolerance;
if epsilon>0
    band=keep & abs(traceSpace)<=epsilon;
    persistentSolid=band & a.x>a.xmin & a.mi_map~=0;
    phase(persistentSolid)=a.mi_map(persistentSolid);phase(band & ~persistentSolid)=1;
end
predicted=struct('nk',nk,'eta_raw',eta,'eta_spatial',etaSpace,'eta_history',score, ...
    'sigma_filtered',traceSpace,'volume_next',volume,'target_keep',target, ...
    'effective_keep',effective,'cutoff',cutoff,'keep_mask',keep,'x',x,'mi_map',phase, ...
    'rank_margin',margin,'exact_cutoff_ties',boundaryTies,'selection_epsilon',0, ...
    'tie_rule','Exact score ties: ascending MATLAB linear element index', ...
    'scope','One update from frozen production FE input; not the unpublished reference implementation');
end

function y=neighbourAverage(field,radius)
% Offset loops are ordered by neighbour element index. Each weight uses
% Euclidean element-centre distance. Domain edges renormalize the denominator.
[ny,nx]=size(field);span=ceil(radius)-1;numerator=zeros(ny,nx);denominator=zeros(ny,nx);
for dc=-span:span
    for dr=-span:span
        w=max(0,radius-sqrt(dc^2+dr^2));if w==0,continue;end
        rows=max(1,1-dr):min(ny,ny-dr);cols=max(1,1-dc):min(nx,nx-dc);
        numerator(rows,cols)=numerator(rows,cols)+w*field(rows+dr,cols+dc);
        denominator(rows,cols)=denominator(rows,cols)+w;
    end
end
assert(all(denominator(:)>0),'Nonpositive filter normalization.');
y=numerator./denominator;
end
