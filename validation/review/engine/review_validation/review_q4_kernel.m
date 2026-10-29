function kernel = review_q4_kernel(E, nu, thickness_mm, hx_mm, hy_mm)
% Independent isoparametric Q4 plane-stress integration (2 x 2 Gauss).
% Nodes: top-left, top-right, bottom-right, bottom-left; y points down.
% This implementation does not call the production element stiffness/stress code.
D = E / (1 - nu^2) * [1 nu 0; nu 1 0; 0 0 (1-nu)/2];
xy = [0 0; hx_mm 0; hx_mm hy_mm; 0 hy_mm];
g = 1 / sqrt(3);
points = [-g -g; g -g; g g; -g g];
K = zeros(8); B_gauss = zeros(3,8,4); jacobian = zeros(4,1);
for q = 1:4
    [B, detJ] = b_matrix(points(q,1), points(q,2), xy);
    K = K + thickness_mm * detJ * (B' * D * B);
    B_gauss(:,:,q) = B; jacobian(q) = detJ;
end
[B_center,~] = b_matrix(0,0,xy);
kernel = struct('K',K,'D',D,'B_center',B_center,'B_gauss',B_gauss, ...
    'gauss_points',points,'detJ',jacobian,'coordinates_mm',xy);
end

function [B,detJ] = b_matrix(xi,eta,xy)
dN = .25 * [-(1-eta), 1-eta, 1+eta, -(1+eta); ...
    -(1-xi), -(1+xi), 1+xi, 1-xi];
J = dN * xy;
detJ = det(J);
assert(detJ > 0,'Independent Q4 integration requires a positive Jacobian.');
dNxy = J \ dN;
B = zeros(3,8);
B(1,1:2:8) = dNxy(1,:); B(2,2:2:8) = dNxy(2,:);
B(3,1:2:8) = dNxy(2,:); B(3,2:2:8) = dNxy(1,:);
end
