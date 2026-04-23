function [U, R, N] = solve_system(KG_orig, KG_bc, F_orig, F_bc, COORDNOS, CONEC, PROP)
% SOLVE_SYSTEM  Solve the FEM linear system and recover reactions and bar forces.
%
%   [U, R, N] = SOLVE_SYSTEM(KG_orig, KG_bc, F_orig, F_bc, COORDNOS, CONEC, PROP)
%
%   Step 1 — Solves the modified system:  KG_bc * U = F_bc
%   Step 2 — Recovers support reactions:  R = KG_orig * U - F_orig
%   Step 3 — Computes axial bar forces by projecting the element end-force
%             (ke * u_e) onto the bar axis direction at node j.
%
%   Inputs
%     KG_orig  – (nDOF × nDOF) global stiffness matrix BEFORE BCs [N/m]
%     KG_bc    – (nDOF × nDOF) global stiffness matrix AFTER  BCs [N/m]
%     F_orig   – (nDOF × 1)    external force vector  BEFORE BCs [N]
%     F_bc     – (nDOF × 1)    external force vector  AFTER  BCs [N]
%     COORDNOS – (nNos  × 2)   nodal coordinates [x, y] in metres
%     CONEC    – (nElem × 2)   element connectivity [nodeI, nodeJ]
%     PROP     – (nElem × 2)   element properties  [E (Pa), A (m²)]
%
%   Outputs
%     U – (nDOF × 1)   nodal displacement vector [m]
%     R – (nDOF × 1)   nodal reaction vector [N]  (non-zero only at
%                       restrained DOFs; negligible elsewhere)
%     N – (nElem × 1)  axial force in each bar [N]
%                       N > 0 → tension  |  N < 0 → compression
%
%   Reference
%     Logan, D.L., "A First Course in the Finite Element Method", 6th ed.,
%     Chapter 3 — Direct Stiffness Method, §3.9 (reaction recovery),
%     eq. (3.34) (element axial force).

% --- Solve for nodal displacements ---
U = KG_bc \ F_bc;

% --- Recover support reactions ---
R = KG_orig * U - F_orig;

% --- Compute axial force in each bar element ---
nElem = size(CONEC, 1);
N     = zeros(nElem, 1);

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

    DOF     = [2*ii-1, 2*ii, 2*jj-1, 2*jj];
    U_e     = U(DOF);
    ke      = stiffness_bar2d(E, A, L, C, S);
    F_e     = ke * U_e;                    % element force vector (global)
    N(e)    = F_e(3)*C + F_e(4)*S;        % project node-j force onto bar axis
end
end
