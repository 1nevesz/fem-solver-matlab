function ke = stiffness_bar2d(E, A, L, C, S)
% STIFFNESS_BAR2D  4×4 global stiffness matrix for a 2D bar (truss) element.
%
%   ke = STIFFNESS_BAR2D(E, A, L, C, S) returns the element stiffness matrix
%   already transformed to global (x–y) coordinates.  The derivation applies
%   the standard transformation T'*k_local*T where k_local is the 2×2 axial
%   stiffness and T is the 2×4 rotation matrix.
%
%   Inputs
%     E  – Young's modulus [Pa]
%     A  – Cross-sectional area [m²]
%     L  – Element length [m]
%     C  – cos(θ) — direction cosine with respect to global x-axis [-]
%     S  – sin(θ) — direction cosine with respect to global y-axis [-]
%
%   Output
%     ke – 4×4 element stiffness matrix in global coordinates [N/m]
%
%   DOF ordering: [u_i, v_i, u_j, v_j]
%
%   Reference
%     Logan, D.L., "A First Course in the Finite Element Method", 6th ed.,
%     Chapter 3 — Development of Truss Equations, eq. (3.23).

f  = E * A / L;
ke = f * [ C^2,   C*S,  -C^2,  -C*S;
           C*S,   S^2,  -C*S,  -S^2;
          -C^2,  -C*S,   C^2,   C*S;
          -C*S,  -S^2,   C*S,   S^2];
end
