function [field, gauss_vm] = mbeso_review_gauss_vm(U, x, mi_map, fem, D1, D2, penal, elSize, measure)
% Four 2x2 Gauss points of a square Q4 element; arithmetic mean of VM scalars.
% Node order is top-left, top-right, bottom-right, bottom-left (positive y down).
if size(U,2) ~= 1
    error('Review Gauss variants currently require one load case.');
end
Ue = reshape(U(fem.edofMat),fem.nele,8); gauss_vm = zeros(fem.nele,4);
g = 1/sqrt(3); points = [-g -g; g -g; g g; -g g];
m1 = mi_map(:) == 1; xp = x(:).^penal;
for k = 1:4
    xi = points(k,1); eta = points(k,2);
    dx = [-(1-eta), 1-eta, 1+eta, -(1+eta)] / (2*elSize);
    dy = [-(1-xi), -(1+xi), 1+xi, 1-xi] / (2*elSize);
    B = zeros(3,8); B(1,1:2:8) = dx; B(2,2:2:8) = dy;
    B(3,1:2:8) = dy; B(3,2:2:8) = dx;
    strain = Ue*B'; stress = zeros(fem.nele,3);
    if any(m1), stress(m1,:) = (strain(m1,:)*D1').*xp(m1); end
    if any(~m1), stress(~m1,:) = (strain(~m1,:)*D2').*xp(~m1); end
    gauss_vm(:,k) = sqrt(stress(:,1).^2 - stress(:,1).*stress(:,2) + ...
        stress(:,2).^2 + 3*stress(:,3).^2);
end
if strcmp(measure,'gauss_mean_vm'), values = mean(gauss_vm,2);
elseif strcmp(measure,'gauss_max_vm'), values = max(gauss_vm,[],2);
else, error('Unknown Gauss stress measure.');
end
field = reshape(values,fem.nely,fem.nelx);
end
