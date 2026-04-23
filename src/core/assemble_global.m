function KG = assemble_global(COORDNOS, CONEC, PROP)
% ASSEMBLE_GLOBAL  Assemble the global stiffness matrix for a 2D truss.
%
%   KG = ASSEMBLE_GLOBAL(COORDNOS, CONEC, PROP) loops over all bar elements,
%   computes each element's 4×4 stiffness matrix (via stiffness_bar2d), and
%   scatters the contributions into the (2*nNos × 2*nNos) global matrix using
%   the direct stiffness method.
%
%   Inputs
%     COORDNOS – (nNos  × 2) nodal coordinates [x, y] in metres
%     CONEC    – (nElem × 2) element connectivity [nodeI, nodeJ]
%     PROP     – (nElem × 2) element properties  [E (Pa), A (m²)]
%
%   Output
%     KG – (2*nNos × 2*nNos) global stiffness matrix [N/m]
%
%   DOF numbering: node i → DOFs [2i-1, 2i] = [Ux_i, Uy_i]
%
%   Reference
%     Logan, D.L., "A First Course in the Finite Element Method", 6th ed.,
%     Chapter 3 — Direct Stiffness Method, §3.5.

nNos  = size(COORDNOS, 1);
nElem = size(CONEC, 1);
KG    = zeros(2*nNos, 2*nNos);

for e = 1:nElem
    ii = CONEC(e, 1);
    jj = CONEC(e, 2);

    dx = COORDNOS(jj, 1) - COORDNOS(ii, 1);
    dy = COORDNOS(jj, 2) - COORDNOS(ii, 2);
    L  = sqrt(dx^2 + dy^2);
    C  = dx / L;
    S  = dy / L;
    E  = PROP(e, 1);
    A  = PROP(e, 2);

    ke  = stiffness_bar2d(E, A, L, C, S);
    DOF = [2*ii-1, 2*ii, 2*jj-1, 2*jj];

    KG(DOF, DOF) = KG(DOF, DOF) + ke;
end
end
