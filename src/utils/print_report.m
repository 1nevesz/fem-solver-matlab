function print_report(U, R, N, RESTRICAO)
% PRINT_REPORT  Print a formatted FEM results report to the console.
%
%   PRINT_REPORT(U, R, N, RESTRICAO) displays three result tables:
%     1. Nodal displacements [m]
%     2. Axial bar forces [kN] with tension / compression classification
%     3. Support reactions [kN] (only for restrained nodes)
%
%   Inputs
%     U         – (2*nNos × 1) nodal displacement vector [m]
%     R         – (2*nNos × 1) nodal reaction vector [N]
%     N         – (nElem  × 1) axial bar forces [N]  (+ tension / − compression)
%     RESTRICAO – (2*nNos × 1) constraint flags (1 = restrained DOF, 0 = free)
%
%   Reference
%     Logan, D.L., "A First Course in the Finite Element Method", 6th ed.,
%     Chapter 3 — Direct Stiffness Method, §3.9–3.10.

nNos  = length(U) / 2;
nElem = length(N);

SEP  = repmat('=', 1, 62);
DASH = repmat('-', 1, 62);

fprintf('\n%s\n', SEP);
fprintf('         FEM RESULTS — 2D TRUSS (DIRECT STIFFNESS METHOD)\n');
fprintf('%s\n', SEP);

% -------------------------------------------------------------------------
% 1. Nodal Displacements
% -------------------------------------------------------------------------
fprintf('\n  NODAL DISPLACEMENTS\n');
fprintf('  %s\n', DASH);
fprintf('  %-6s  %-22s  %-22s\n', 'Node', 'Ux (m)', 'Uy (m)');
fprintf('  %s\n', DASH);
for i = 1:nNos
    fprintf('  %-6d  %+.6e          %+.6e\n', i, U(2*i-1), U(2*i));
end

% -------------------------------------------------------------------------
% 2. Axial Bar Forces
% -------------------------------------------------------------------------
fprintf('\n  AXIAL BAR FORCES\n');
fprintf('  %s\n', DASH);
fprintf('  %-6s  %-22s  %s\n', 'Bar', 'N (kN)', 'Type');
fprintf('  %s\n', DASH);
for e = 1:nElem
    if N(e) >= 0
        tipo = 'TENSION';
    else
        tipo = 'COMPRESSION';
    end
    fprintf('  %-6d  %+.6e          %s\n', e, N(e)/1e3, tipo);
end

% -------------------------------------------------------------------------
% 3. Support Reactions
% -------------------------------------------------------------------------
fprintf('\n  SUPPORT REACTIONS\n');
fprintf('  %s\n', DASH);
fprintf('  %-6s  %-22s  %-22s\n', 'Node', 'Rx (kN)', 'Ry (kN)');
fprintf('  %s\n', DASH);
hasReaction = false;
for i = 1:nNos
    if RESTRICAO(2*i-1) == 1 || RESTRICAO(2*i) == 1
        fprintf('  %-6d  %+.6e          %+.6e\n', i, R(2*i-1)/1e3, R(2*i)/1e3);
        hasReaction = true;
    end
end
if ~hasReaction
    fprintf('  (no restrained DOFs found)\n');
end

fprintf('\n%s\n\n', SEP);
end
