function solve_truss2d(filepath)
% SOLVE_TRUSS2D  Generic 2D truss FEM solver driven by a plain-text input file.
%
%   solve_truss2d(FILEPATH) reads the truss definition from FILEPATH,
%   assembles and solves the FEM system, prints a formatted report, and
%   generates two figures (deformed shape + normal force diagram).
%
%   FILEPATH can be absolute or relative to the current working directory.
%
%   Usage
%     >> solve_truss2d('src/examples/bridge.txt')
%     >> solve_truss2d('src/examples/warren_roof.txt')
%
%   Input file format (sections can appear in any order; % = comment)
%     NODES
%       <id>  <x>  <y>              % one node per line, metres
%     ELEMENTS
%       <id>  <nodeI>  <nodeJ>  <E>  <A>   % E in Pa, A in m^2
%     FORCES
%       <nodeId>  <Fx>  <Fy>         % only loaded nodes listed, Newtons
%     SUPPORTS
%       <nodeId>  <restX>  <restY>   % 1 = restrained DOF, 0 = free
%                                    % only constrained nodes listed
%
%   Reference
%     Logan, D.L., "A First Course in the Finite Element Method", 6th ed.,
%     Chapter 3 — Direct Stiffness Method.

% ── Add library paths relative to this file ──────────────────────────────
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, 'core'));
addpath(fullfile(here, 'elements'));
addpath(fullfile(here, 'utils'));

% ── Parse input file ──────────────────────────────────────────────────────
[COORDNOS, CONEC, PROP, F, RESTRICAO, label] = parse_input(filepath);

nNos  = size(COORDNOS, 1);
nElem = size(CONEC, 1);

[~, fname, fext] = fileparts(filepath);
fprintf('\n%s\n', repmat('=', 1, 62));
fprintf('  2D TRUSS FEM SOLVER — %s\n', upper([fname, fext]));
if ~isempty(label)
    fprintf('  %s\n', label);
end
fprintf('  Nodes: %d  |  Elements: %d  |  DOFs: %d\n', nNos, nElem, 2*nNos);
fprintf('%s\n', repmat('=', 1, 62));

% ── FEM pipeline ─────────────────────────────────────────────────────────

% Step 1 — Global stiffness matrix
KG = assemble_global(COORDNOS, CONEC, PROP);

% Step 2 — Save originals, then enforce boundary conditions
KG_orig = KG;
F_orig  = F;
[KG_bc, F_bc] = apply_bc(KG, F, RESTRICAO);

% Step 3 — Solve: displacements, reactions, axial forces
[U, R, N] = solve_system(KG_orig, KG_bc, F_orig, F_bc, COORDNOS, CONEC, PROP);

% ── Output ───────────────────────────────────────────────────────────────
print_report(U, R, N, RESTRICAO);
plot_truss2d(COORDNOS, CONEC, U, N);

end % solve_truss2d


% =========================================================================
% Local helper — input file parser
% =========================================================================
function [COORDNOS, CONEC, PROP, F, RESTRICAO, label] = parse_input(filepath)
% PARSE_INPUT  Read a structured plain-text truss definition file.
%
%   Returns MATLAB arrays ready for the FEM pipeline.  Recognises four
%   section keywords (NODES, ELEMENTS, FORCES, SUPPORTS), ignores blank
%   lines, and strips % comments anywhere in a line.

    fid = fopen(filepath, 'r');
    if fid == -1
        error('solve_truss2d:fileNotFound', ...
              'Cannot open input file: "%s"\n  Check the path and try again.', ...
              filepath);
    end

    nodes_raw    = [];   % [id, x, y]
    elements_raw = [];   % [id, ni, nj, E, A]
    forces_raw   = [];   % [nodeId, Fx, Fy]
    supports_raw = [];   % [nodeId, rx, ry]
    label        = '';
    section      = '';
    firstLine    = true;

    while ~feof(fid)
        raw  = fgetl(fid);
        if ~ischar(raw); break; end
        line = strtrim(raw);

        % Capture first comment line as the model label
        if firstLine && ~isempty(line) && line(1) == '%'
            label    = strtrim(line(2:end));
            firstLine = false;
            continue;
        end
        firstLine = false;

        % Skip blank lines and comment-only lines
        if isempty(line) || line(1) == '%'
            continue;
        end

        % Strip inline comments
        idx = strfind(line, '%');
        if ~isempty(idx)
            line = strtrim(line(1:idx(1)-1));
        end
        if isempty(line); continue; end

        % Section keyword?
        switch upper(line)
            case 'NODES';    section = 'NODES';    continue;
            case 'ELEMENTS'; section = 'ELEMENTS'; continue;
            case 'FORCES';   section = 'FORCES';   continue;
            case 'SUPPORTS'; section = 'SUPPORTS'; continue;
        end

        % Numeric data row
        vals = str2num(line); %#ok<ST2NM>   % handles 200e9 etc.
        if isempty(vals); continue; end

        switch section
            case 'NODES';    nodes_raw    = [nodes_raw;    vals];
            case 'ELEMENTS'; elements_raw = [elements_raw; vals];
            case 'FORCES';   forces_raw   = [forces_raw;   vals];
            case 'SUPPORTS'; supports_raw = [supports_raw; vals];
        end
    end
    fclose(fid);

    % ── Validate ─────────────────────────────────────────────────────────
    if isempty(nodes_raw)
        error('solve_truss2d:parseError', 'No NODES section found in "%s".', filepath);
    end
    if isempty(elements_raw)
        error('solve_truss2d:parseError', 'No ELEMENTS section found in "%s".', filepath);
    end

    % ── Sort by ID and build arrays ───────────────────────────────────────
    [~, ord] = sort(nodes_raw(:, 1));
    nodes_raw = nodes_raw(ord, :);

    [~, ord] = sort(elements_raw(:, 1));
    elements_raw = elements_raw(ord, :);

    COORDNOS = nodes_raw(:, 2:3);
    CONEC    = elements_raw(:, 2:3);
    PROP     = elements_raw(:, 4:5);

    nNos  = size(COORDNOS, 1);
    F         = zeros(2*nNos, 1);
    RESTRICAO = zeros(2*nNos, 1);

    for k = 1:size(forces_raw, 1)
        i        = round(forces_raw(k, 1));
        F(2*i-1) = forces_raw(k, 2);
        F(2*i)   = forces_raw(k, 3);
    end

    for k = 1:size(supports_raw, 1)
        i                = round(supports_raw(k, 1));
        RESTRICAO(2*i-1) = supports_raw(k, 2);
        RESTRICAO(2*i)   = supports_raw(k, 3);
    end
end
