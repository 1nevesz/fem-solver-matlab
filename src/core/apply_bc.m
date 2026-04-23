function [KG_bc, F_bc] = apply_bc(KG, F, RESTRICAO)
% APPLY_BC  Apply essential (Dirichlet) boundary conditions to the FEM system.
%
%   [KG_bc, F_bc] = APPLY_BC(KG, F, RESTRICAO) enforces zero-displacement
%   boundary conditions using the elimination method: for each restrained DOF i,
%   row i and column i are zeroed, the diagonal KG(i,i) is set to 1, and
%   F(i) is set to 0.  This preserves matrix symmetry and yields U(i) = 0
%   upon solving.
%
%   Inputs
%     KG        – (nDOF × nDOF) assembled global stiffness matrix before BCs
%     F         – (nDOF × 1)    external force vector before BCs [N]
%     RESTRICAO – (nDOF × 1)    constraint flags: 1 = restrained DOF, 0 = free
%
%   Outputs
%     KG_bc – (nDOF × nDOF) modified stiffness matrix after BCs
%     F_bc  – (nDOF × 1)    modified force vector after BCs
%
%   Note: the original KG and F should be saved before calling this function
%   so that reactions can be recovered as R = KG_orig*U - F_orig.
%
%   Reference
%     Logan, D.L., "A First Course in the Finite Element Method", 6th ed.,
%     Chapter 2 — Introduction to the Stiffness Method, §2.5.

KG_bc = KG;
F_bc  = F;

for i = 1:length(F)
    if RESTRICAO(i) == 1
        KG_bc(i, :) = 0;
        KG_bc(:, i) = 0;
        KG_bc(i, i) = 1;
        F_bc(i)     = 0;
    end
end
end
