function plot_truss2d(COORDNOS, CONEC, U, N, scale)
% PLOT_TRUSS2D  Plot the 2D truss: deformed shape and normal force diagram.
%
%   PLOT_TRUSS2D(COORDNOS, CONEC, U, N) generates two figures:
%     Figure 1 — Original shape (blue dashed) overlaid with the deformed
%                shape (red solid) using an automatically computed
%                amplification factor so displacements are visible.
%     Figure 2 — Normal force diagram with line thickness proportional to
%                force magnitude; blue = tension, red = compression.
%                Force values [kN] are labelled at each bar's midpoint.
%
%   PLOT_TRUSS2D(COORDNOS, CONEC, U, N, scale) uses the caller-supplied
%   amplification factor instead of the automatic one.
%
%   Inputs
%     COORDNOS – (nNos  × 2) nodal coordinates [x, y] in metres
%     CONEC    – (nElem × 2) element connectivity [nodeI, nodeJ]
%     U        – (2*nNos × 1) nodal displacement vector [m]
%     N        – (nElem  × 1) axial bar forces [N]  (+ tension / − compression)
%     scale    – (optional) displacement amplification factor [default: auto]
%
%   Reference
%     Logan, D.L., "A First Course in the Finite Element Method", 6th ed.,
%     Chapter 3 — post-processing and result visualization.

% --- Automatic scale: max displacement becomes ~10 % of structure span ---
if nargin < 5 || isempty(scale)
    span  = max(COORDNOS(:,1)) - min(COORDNOS(:,1));
    maxU  = max(abs(U));
    if maxU > 0
        scale = 0.10 * span / maxU;
    else
        scale = 1;
    end
end

nNos  = size(COORDNOS, 1);
nElem = size(CONEC, 1);

% =========================================================================
% Figure 1 — Original + Deformed Shape
% =========================================================================
figure('Name', 'Truss: Original and Deformed Shape', 'NumberTitle', 'off');
hold on; grid on; axis equal;
title(sprintf('2D Truss — Original (blue) and Deformed (red)  |  amplification \\times%g', ...
      round(scale)));
xlabel('x (m)'); ylabel('y (m)');

for e = 1:nElem
    ii = CONEC(e, 1);
    jj = CONEC(e, 2);

    % Original shape (blue dashed)
    plot([COORDNOS(ii,1), COORDNOS(jj,1)], ...
         [COORDNOS(ii,2), COORDNOS(jj,2)], ...
         'b--', 'LineWidth', 1.5);

    % Deformed shape (red solid)
    xd = [COORDNOS(ii,1) + scale*U(2*ii-1), ...
          COORDNOS(jj,1) + scale*U(2*jj-1)];
    yd = [COORDNOS(ii,2) + scale*U(2*ii), ...
          COORDNOS(jj,2) + scale*U(2*jj)];
    plot(xd, yd, 'r-', 'LineWidth', 2.0);
end

% Node markers and labels
for i = 1:nNos
    % Original node
    plot(COORDNOS(i,1), COORDNOS(i,2), 'bo', ...
         'MarkerSize', 8, 'MarkerFaceColor', 'b');
    text(COORDNOS(i,1), COORDNOS(i,2), sprintf('  N%d', i), ...
         'Color', 'b', 'FontSize', 9, 'FontWeight', 'bold', ...
         'VerticalAlignment', 'bottom');

    % Deformed node
    xd = COORDNOS(i,1) + scale*U(2*i-1);
    yd = COORDNOS(i,2) + scale*U(2*i);
    plot(xd, yd, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
end

% Dummy plots for legend (avoids one entry per element)
h1 = plot(nan, nan, 'b--', 'LineWidth', 1.5);
h2 = plot(nan, nan, 'r-',  'LineWidth', 2.0);
legend([h1, h2], {'Original', sprintf('Deformed (\\times%g)', round(scale))}, ...
       'Location', 'best');
hold off;

% =========================================================================
% Figure 2 — Normal Force Diagram
% =========================================================================
figure('Name', 'Normal Force Diagram', 'NumberTitle', 'off');
hold on; grid on; axis equal;
title('Normal Force Diagram  (blue = tension  |  red = compression)');
xlabel('x (m)'); ylabel('y (m)');

Nmax = max(abs(N));
if Nmax == 0; Nmax = 1; end

COLOR_T = [0.00, 0.45, 0.74];   % blue  — tension
COLOR_C = [0.85, 0.33, 0.10];   % red   — compression

for e = 1:nElem
    ii = CONEC(e, 1);
    jj = CONEC(e, 2);
    xm = 0.5*(COORDNOS(ii,1) + COORDNOS(jj,1));
    ym = 0.5*(COORDNOS(ii,2) + COORDNOS(jj,2));

    if N(e) >= 0
        col  = COLOR_T;
        tipo = 'T';
    else
        col  = COLOR_C;
        tipo = 'C';
    end

    lw = 1.5 + 5.5 * abs(N(e)) / Nmax;    % thickness ∝ force magnitude

    plot([COORDNOS(ii,1), COORDNOS(jj,1)], ...
         [COORDNOS(ii,2), COORDNOS(jj,2)], ...
         '-', 'Color', col, 'LineWidth', lw);

    text(xm, ym, sprintf(' %.2f kN (%s) ', N(e)/1e3, tipo), ...
         'FontSize', 7, 'Color', col, ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
         'BackgroundColor', 'w', 'EdgeColor', 'none');
end

% Node markers
for i = 1:nNos
    plot(COORDNOS(i,1), COORDNOS(i,2), 'ks', ...
         'MarkerSize', 7, 'MarkerFaceColor', 'k');
    text(COORDNOS(i,1), COORDNOS(i,2), sprintf('  N%d', i), ...
         'Color', 'k', 'FontSize', 9, 'VerticalAlignment', 'top');
end

% Legend
h_t = plot(nan, nan, '-', 'Color', COLOR_T, 'LineWidth', 4);
h_c = plot(nan, nan, '-', 'Color', COLOR_C, 'LineWidth', 4);
legend([h_t, h_c], {'Tension', 'Compression'}, 'Location', 'best');
hold off;
end
