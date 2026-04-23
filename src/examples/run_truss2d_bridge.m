%% RUN_TRUSS2D_BRIDGE — Howe Bridge Truss Example (6 nodes, 9 bars)
%
%  Demonstrates the 2D-truss FEM library on a symmetric Howe bridge.
%  Run with a single command:  >> run_truss2d_bridge
%  (No user input required.)
%
%  Geometry (all lengths in metres)
%  ---------------------------------
%  Bottom chord:  nodes 1–2–3  at y = 0,  x = 0, 3, 6
%  Top    chord:  nodes 4–5–6  at y = 3,  x = 0, 3, 6
%
%                  4 -------- 5 -------- 6
%                  |  \       |       /  |
%                  |   \      |      /   |
%                  |    \     |     /    |
%                  1 -------- 2 -------- 3
%               (pin)       50 kN↓    (roller)
%
%  Bar topology (Howe pattern — diagonals slope toward supports)
%  ---------------------------------------------------------------
%  Bar  1: 1–2  (bottom chord left)
%  Bar  2: 2–3  (bottom chord right)
%  Bar  3: 4–5  (top chord left)
%  Bar  4: 5–6  (top chord right)
%  Bar  5: 1–4  (left vertical)
%  Bar  6: 2–5  (centre vertical)
%  Bar  7: 3–6  (right vertical)
%  Bar  8: 2–4  (left Howe diagonal — compression under symmetric load)
%  Bar  9: 3–5  (right Howe diagonal — compression under symmetric load)
%
%  Supports: node 1 pin (Ux=0, Uy=0), node 3 roller (Uy=0)
%  Load:     50 kN downward at node 2 (midspan, bottom chord)
%
%  Material (structural steel, same for all members)
%    E = 200 GPa,  A = 30 cm² = 3×10⁻³ m²
%
%  Determinacy check: m + r = 9 + 3 = 12 = 2n = 2×6  → statically determinate
%
%  Reference
%    Logan, D.L., "A First Course in the Finite Element Method", 6th ed.,
%    Chapter 3 — Example problems, Howe truss configuration.

clear; clc;

% ── Add library paths relative to this file's location ───────────────────
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'core'));
addpath(fullfile(here, '..', 'elements'));
addpath(fullfile(here, '..', 'utils'));

fprintf('=============================================================\n');
fprintf('   Howe Bridge Truss — 2D FEM Solver  (6 nodes, 9 bars)\n');
fprintf('=============================================================\n\n');

% =========================================================================
% INPUT DATA
% =========================================================================

% --- Nodal coordinates [x, y] in metres ----------------------------------
COORDNOS = [0, 0;   % node 1 — bottom left  (pin support)
            3, 0;   % node 2 — bottom middle (loaded)
            6, 0;   % node 3 — bottom right  (roller support)
            0, 3;   % node 4 — top left
            3, 3;   % node 5 — top middle
            6, 3];  % node 6 — top right

% --- Element connectivity [nodeI, nodeJ] ---------------------------------
CONEC = [1, 2;   % bar 1 — bottom chord left
         2, 3;   % bar 2 — bottom chord right
         4, 5;   % bar 3 — top chord left
         5, 6;   % bar 4 — top chord right
         1, 4;   % bar 5 — left vertical
         2, 5;   % bar 6 — centre vertical
         3, 6;   % bar 7 — right vertical
         2, 4;   % bar 8 — left Howe diagonal
         3, 5];  % bar 9 — right Howe diagonal

% --- Material properties [E (Pa), A (m²)] — same for all members ---------
E_steel = 200e9;            % Young's modulus [Pa]
A_sec   = 3e-3;             % cross-sectional area [m²]
nElem   = size(CONEC, 1);
PROP    = repmat([E_steel, A_sec], nElem, 1);

% --- External force vector F [N] -----------------------------------------
% DOF numbering: node i → DOFs [2i-1, 2i] = [Fx_i, Fy_i]
nNos = size(COORDNOS, 1);
F    = zeros(2*nNos, 1);
F(4) = -50e3;               % 50 kN downward at node 2 (DOF 4 = Fy_2)

% --- Constraint vector (1 = restrained DOF, 0 = free) --------------------
RESTRICAO = zeros(2*nNos, 1);
RESTRICAO(1) = 1;   % node 1, Ux — pin
RESTRICAO(2) = 1;   % node 1, Uy — pin
RESTRICAO(6) = 1;   % node 3, Uy — roller  (DOF 2*3 = 6)

% =========================================================================
% FEM SOLUTION PIPELINE
% =========================================================================

% Step 1 — Assemble global stiffness matrix
KG = assemble_global(COORDNOS, CONEC, PROP);

% Step 2 — Save originals, then apply boundary conditions
KG_orig = KG;
F_orig  = F;
[KG_bc, F_bc] = apply_bc(KG, F, RESTRICAO);

% Step 3 — Solve for displacements, reactions, and axial forces
[U, R, N] = solve_system(KG_orig, KG_bc, F_orig, F_bc, COORDNOS, CONEC, PROP);

% =========================================================================
% OUTPUT
% =========================================================================

% Console report
print_report(U, R, N, RESTRICAO);

% Plots (auto-scaled deformed shape + normal force diagram)
plot_truss2d(COORDNOS, CONEC, U, N);
