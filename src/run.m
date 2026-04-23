%% RUN  —  2D Truss FEM Solver  |  Main Launcher
% =====================================================================
%  Entry point for the entire library.  Run from any working directory:
%
%    >> run('path/to/src/run.m')
%
%  Or add src/ to the MATLAB path and type simply:
%    >> run
%
%  Requires MATLAB R2016b or later (local functions inside scripts).
% =====================================================================

clear; clc;

% ── Bootstrap: make solve_truss2d visible from any working directory ──
here = fileparts(mfilename('fullpath'));
addpath(here);

SEP  = repmat('=', 1, 54);
DSEP = repmat('-', 1, 54);

fprintf('\n%s\n', SEP);
fprintf('       2D TRUSS FEM SOLVER  —  MAIN MENU\n');
fprintf('%s\n\n', SEP);

% ── Discover .txt files in src/examples/ ─────────────────────────────
txtFiles = dir(fullfile(here, 'examples', '*.txt'));
nFiles   = numel(txtFiles);

if nFiles > 0
    fprintf('  Available examples:\n\n');
    for k = 1:nFiles
        [~, name] = fileparts(txtFiles(k).name);
        fprintf('    [%2d]  %s\n', k, name);
    end
    fprintf('\n');
else
    fprintf('  (no example files found in src/examples/)\n\n');
end

NEW = nFiles + 1;
fprintf('    [%2d]  New — build a truss interactively\n\n', NEW);
fprintf('%s\n', SEP);
choice = input(sprintf('  Your choice (1–%d): ', NEW));

% ── Validate ─────────────────────────────────────────────────────────
if ~isnumeric(choice) || isempty(choice) || ...
        choice ~= round(choice) || choice < 1 || choice > NEW
    fprintf('\n  Invalid choice. Exiting.\n\n');
    return;
end

% ── Dispatch ─────────────────────────────────────────────────────────
if choice <= nFiles
    filepath = fullfile(here, 'examples', txtFiles(choice).name);
else
    filepath = wizard_new_truss(here, DSEP);
    if isempty(filepath); return; end
end

fprintf('\n');
solve_truss2d(filepath);


%% ====================================================================
%  Local functions  (MATLAB R2016b+)
%% ====================================================================

function filepath = wizard_new_truss(here, DSEP)
% WIZARD_NEW_TRUSS  Collect truss data interactively and save a .txt file.

filepath = '';

fprintf('\n%s\n', DSEP);
fprintf('  NEW TRUSS — INTERACTIVE WIZARD\n');
fprintf('%s\n\n', DSEP);

% ── Model name ───────────────────────────────────────────────────────
name = strtrim(input('  Model name (no spaces, no extension): ', 's'));
name = regexprep(name, '\s+', '_');       % spaces → underscores
name = regexprep(name, '[^\w]', '');      % remove any remaining non-word chars
if isempty(name)
    name = sprintf('truss_%s', datestr(now, 'yyyymmdd_HHMMSS'));
end

outfile = fullfile(here, 'examples', [name, '.txt']);
if exist(outfile, 'file')
    ow = strtrim(input( ...
        sprintf('\n  "%s.txt" already exists. Overwrite? (y/n): ', name), 's'));
    if ~strcmpi(ow, 'y')
        fprintf('  Cancelled.\n\n');
        return;
    end
end

% ── Nodes ─────────────────────────────────────────────────────────────
fprintf('\n%s\n  NODES\n%s\n', DSEP, DSEP);
nNos     = input('  Number of nodes: ');
COORDNOS = zeros(nNos, 2);
for i = 1:nNos
    fprintf('\n  Node %d\n', i);
    COORDNOS(i,1) = input(sprintf('    x%d (m): ', i));
    COORDNOS(i,2) = input(sprintf('    y%d (m): ', i));
end

% ── Elements ──────────────────────────────────────────────────────────
fprintf('\n%s\n  ELEMENTS\n%s\n', DSEP, DSEP);
nElem = input('  Number of elements: ');
CONEC = zeros(nElem, 2);
PROP  = zeros(nElem, 2);
for e = 1:nElem
    fprintf('\n  Element %d\n', e);
    CONEC(e,1) = input('    Node I:              ');
    CONEC(e,2) = input('    Node J:              ');
    PROP(e,1)  = input('    E (Pa)  [e.g. 200e9]: ');
    PROP(e,2)  = input('    A (m^2) [e.g. 15e-4]: ');
end

% ── Forces ────────────────────────────────────────────────────────────
fprintf('\n%s\n  FORCES\n%s\n', DSEP, DSEP);
nForces     = input('  Number of loaded nodes (0 = none): ');
forces_data = zeros(nForces, 3);   % [nodeId, Fx, Fy]
for k = 1:nForces
    fprintf('\n  Load %d\n', k);
    forces_data(k,1) = input('    Node ID:  ');
    forces_data(k,2) = input('    Fx (N):   ');
    forces_data(k,3) = input('    Fy (N):   ');
end

% ── Supports ──────────────────────────────────────────────────────────
fprintf('\n%s\n  SUPPORTS\n%s\n', DSEP, DSEP);
nSup          = input('  Number of supported nodes: ');
supports_data = zeros(nSup, 3);    % [nodeId, restX, restY]
for k = 1:nSup
    fprintf('\n  Support %d\n', k);
    supports_data(k,1) = input('    Node ID:              ');
    supports_data(k,2) = input('    Restrain Ux? (1/0):   ');
    supports_data(k,3) = input('    Restrain Uy? (1/0):   ');
end

% ── Write file ────────────────────────────────────────────────────────
fprintf('\n  Saving %s.txt ... ', name);
write_truss_txt(outfile, name, COORDNOS, CONEC, PROP, forces_data, supports_data);
fprintf('saved.\n');

filepath = outfile;
end % wizard_new_truss


% ---------------------------------------------------------------------

function write_truss_txt(outfile, label, COORDNOS, CONEC, PROP, forces_data, supports_data)
% WRITE_TRUSS_TXT  Write truss data to the standard .txt input format.

fid = fopen(outfile, 'w');
if fid == -1
    error('run:writeError', 'Cannot write to "%s".', outfile);
end

nNos  = size(COORDNOS, 1);
nElem = size(CONEC,    1);

% ── File header ───────────────────────────────────────────────────────
fprintf(fid, '%% %s\n', label);
fprintf(fid, '%% Generated by src/run.m  —  %s\n', ...
        datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf(fid, '%% Nodes: %d  |  Elements: %d\n', nNos, nElem);

% ── NODES ─────────────────────────────────────────────────────────────
fprintf(fid, '\nNODES\n');
fprintf(fid, '%%  id    x           y\n');
for i = 1:nNos
    fprintf(fid, '%d  %.6g  %.6g\n', i, COORDNOS(i,1), COORDNOS(i,2));
end

% ── ELEMENTS ──────────────────────────────────────────────────────────
fprintf(fid, '\nELEMENTS\n');
fprintf(fid, '%%  id  ni  nj       E (Pa)       A (m^2)\n');
for e = 1:nElem
    fprintf(fid, '%d  %d  %d  %.6g  %.6g\n', ...
            e, CONEC(e,1), CONEC(e,2), PROP(e,1), PROP(e,2));
end

% ── FORCES ────────────────────────────────────────────────────────────
fprintf(fid, '\nFORCES\n');
fprintf(fid, '%%  node   Fx (N)       Fy (N)\n');
for k = 1:size(forces_data, 1)
    fprintf(fid, '%d  %.6g  %.6g\n', ...
            forces_data(k,1), forces_data(k,2), forces_data(k,3));
end

% ── SUPPORTS ──────────────────────────────────────────────────────────
fprintf(fid, '\nSUPPORTS\n');
fprintf(fid, '%%  node  restX  restY\n');
for k = 1:size(supports_data, 1)
    fprintf(fid, '%d  %d  %d\n', ...
            supports_data(k,1), supports_data(k,2), supports_data(k,3));
end

fclose(fid);
end % write_truss_txt
