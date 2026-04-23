%% =====================================================================
%  TRELICA_PLANA.m
%  Análise de Treliça Plana Indeterminada — Método da Rigidez (
% MEF)
%  Cap. 32 — Apostila de Resistência dos Materiais
%  O usuário fornece todos os dados de entrada via Command Window
% ======================================================================
clear; clc;

%% PASSO 1 — Parâmetros Gerais
fprintf('=====================================================\n');
fprintf('     SOLVER DE TRELIÇA PLANA — MÉTODO DA RIGIDEZ   \n');
fprintf('=====================================================\n\n');

nNos       = input('Número de nós: ');
nElementos = input('Número de barras: ');

% PASSO 2 — Coordenadas dos Nós
fprintf('\n--- COORDENADAS DOS NÓS ---\n');
fprintf('(informe x e y de cada nó em metros)\n\n');

COORDNOS = zeros(nNos, 2);
for i = 1:nNos
    fprintf('Nó %d:\n', i);
    COORDNOS(i,1) = input(sprintf('  x%d = ', i));
    COORDNOS(i,2) = input(sprintf('  y%d = ', i));
end

% PASSO 2b — Conectividade das Barras
fprintf('\n--- CONECTIVIDADE DAS BARRAS ---\n');
fprintf('(informe o nó inicial e o nó final de cada barra)\n\n');

CONEC = zeros(nElementos, 2);
for i = 1:nElementos
    fprintf('Barra %d:\n', i);
    CONEC(i,1) = input('  Nó inicial: ');
    CONEC(i,2) = input('  Nó final:   ');
end

% PASSO 2c — Propriedades das Barras
fprintf('\n--- PROPRIEDADES DAS BARRAS ---\n');
fprintf('(E em Pa, A em m^2)\n\n');

PROP = zeros(nElementos, 2);
for i = 1:nElementos
    fprintf('Barra %d:\n', i);
    PROP(i,1) = input(sprintf('  E (Pa): '));
    PROP(i,2) = input(sprintf('  A (m^2): '));
end


% PASSO 3 — Vetor de Forças Externas F
% F(2*i-1) = Fx no nó i | F(2*i) = Fy no nó i
fprintf('\n--- FORCAS EXTERNAS ---\n');
fprintf('(em Newtons; digite 0 se nao houver forca)\n\n');

F = zeros(2*nNos, 1);
for i = 1:nNos
    fprintf('No %d:\n', i);
    F(2*i-1) = input(sprintf('  Fx%d (N): ', i));
    F(2*i)   = input(sprintf('  Fy%d (N): ', i));
end

% PASSO 4 — Vetor de Restrições (Condições de Contorno)
% 0 = GDL livre | 1 = GDL restrito (apoio)
fprintf('\n--- RESTRICOES DE APOIO ---\n');
fprintf('(0 = livre, 1 = restrito/apoio)\n\n');

RESTRICAO = zeros(2*nNos, 1);
for i = 1:nNos
    fprintf('No %d:\n', i);
    RESTRICAO(2*i-1) = input(sprintf('  Ux%d restrito? (0/1): ', i));
    RESTRICAO(2*i)   = input(sprintf('  Uy%d restrito? (0/1): ', i));
end

fprintf('\n=====================================================\n');
fprintf('  Dados recebidos! Calculando...\n');
fprintf('=====================================================\n\n');

%% =====================================================================
%  RESOLUCAO DO EXERCICIO 
% ======================================================================

%% PASSO 5 — Geometria de Cada Barra: L, C = cos(theta), S = sen(theta)

VEC_L = zeros(nElementos, 1);
VEC_C = zeros(nElementos, 1);
VEC_S = zeros(nElementos, 1);

fprintf('===== PASSO 5: Geometria das Barras =====\n');
for i = 1:nElementos
    ii = CONEC(i,1);
    jj = CONEC(i,2);
    dx = COORDNOS(jj,1) - COORDNOS(ii,1);
    dy = COORDNOS(jj,2) - COORDNOS(ii,2);
    L  = sqrt(dx^2 + dy^2);
    C  = dx / L;
    S  = dy / L;
    VEC_L(i) = L;
    VEC_C(i) = C;
    VEC_S(i) = S;
    fprintf('Barra %d (no %d -> no %d): L=%.4f m | C=%.4f | S=%.4f\n', i, ii, jj, L, C, S);
end

%% PASSO 6 — Montagem das Matrizes de Rigidez Locais KLOCAL(i, 4, 4)
% K_local = (EA/L)*[C2 CS -C2 -CS; CS S2 -CS -S2; -C2 -CS C2 CS; -CS -S2 CS S2]

KLOCAL = zeros(nElementos, 4, 4);

for i = 1:nElementos
    E = PROP(i,1);
    A = PROP(i,2);
    L = VEC_L(i);
    C = VEC_C(i);
    S = VEC_S(i);
    f = (E * A) / L;
    KLOCAL(i,:,:) = f * [ C^2,  C*S, -C^2, -C*S;
                           C*S,  S^2, -C*S, -S^2;
                          -C^2, -C*S,  C^2,  C*S;
                          -C*S, -S^2,  C*S,  S^2];
end

%% PASSO 7 — Exibir KLOCAL de Cada Barra

fprintf('\n===== PASSO 7: Matrizes de Rigidez Locais =====\n');
for i = 1:nElementos
    fprintf('\nKLOCAL — Barra %d:\n', i);
    disp(squeeze(KLOCAL(i,:,:)));
end


%% PASSO 9 — Espalhamento: Somar KLOCAL nas Posicoes Corretas de KG
% Mapeamento: no ii -> GDLs [2ii-1, 2ii] | no jj -> GDLs [2jj-1, 2jj]

KG = zeros(2*nNos, 2*nNos);
for i = 1:nElementos
    ii  = CONEC(i,1);
    jj  = CONEC(i,2);
    DOF = [2*ii-1, 2*ii, 2*jj-1, 2*jj];
    for r = 1:4
        for c = 1:4
            KG(DOF(r), DOF(c)) = KG(DOF(r), DOF(c)) + KLOCAL(i,r,c);
        end
    end
end

%% PASSO 10 — Exibir KG Global (antes das condicoes de contorno)

fprintf('===== PASSO 10: Matriz KG Global (antes das CCs) =====\n');
disp(KG);

%% PASSO 11 — Salvar KG e F Originais (necessarios para calcular reacoes)

KGLOBAL_ORIG = KG;
F_ORIG       = F;

%% PASSO 12 — Aplicar Condicoes de Contorno
% Para cada GDL restrito: zera linha, zera coluna, diagonal=1, F=0

for i = 1:2*nNos
    if RESTRICAO(i) == 1
        KG(i,:) = 0;
        KG(:,i) = 0;
        KG(i,i) = 1;
        F(i)    = 0;
    end
end

%% PASSO 13 — Exibir KG Modificada (apos condicoes de contorno)

fprintf('===== PASSO 14: KG Modificada (apos CCs) =====\n');
disp(KG);

%% PASSO 14 — Resolver Sistema Linear: U = KG \ F

U = KG \ F;

fprintf('===== PASSO 15: Deslocamentos Nodais =====\n');
for i = 1:nNos
    fprintf('No %d: Ux = %+.6e m  |  Uy = %+.6e m\n', i, U(2*i-1), U(2*i));
end

%% PASSO 15 — Calcular Reacoes de Apoio: R = KG_orig * U - F_orig

R = KGLOBAL_ORIG * U - F_ORIG;

%% PASSO 16 — Calcular Forcas Normais nas Barras
% Para cada barra: extrai U_local, multiplica por KLOCAL, projeta no eixo da barra
% N > 0: tracao | N < 0: compressao

N = zeros(nElementos, 1);

for i = 1:nElementos
    ii      = CONEC(i,1);
    jj      = CONEC(i,2);
    DOF     = [2*ii-1, 2*ii, 2*jj-1, 2*jj];
    U_local = U(DOF);
    F_local = squeeze(KLOCAL(i,:,:)) * U_local;
    N(i)    = F_local(3)*VEC_C(i) + F_local(4)*VEC_S(i);
end

%% PASSO 17 — Tabelas de Resultados (preparadas nos vetores U, R, N)

% Vetores prontos para exibicao no menu abaixo

%% PASSO 18 — Menu Interativo de Saida

fprintf('\n=====================================================\n');
fprintf('         RESULTADOS — TRELICA PLANA (MEF)          \n');
fprintf('=====================================================\n');
fprintf('[1] Deslocamentos nodais\n');
fprintf('[2] Forcas normais nas barras\n');
fprintf('[3] Reacoes de apoio\n');
fprintf('[4] Mostrar tudo\n');
fprintf('=====================================================\n');
opcao = input('Escolha uma opcao (1-4): ');

% --- sub-rotinas de impressao ---

switch opcao
    case 1
        fprintf('\n--- DESLOCAMENTOS NODAIS ---\n');
        fprintf('%-5s  %-22s  %-22s\n', 'No', 'UX (m)', 'UY (m)');
        fprintf('%s\n', repmat('-', 1, 55));
        for i = 1:nNos
            fprintf('%-5d  %+.6e          %+.6e\n', i, U(2*i-1), U(2*i));
        end

    case 2
        fprintf('\n--- FORCAS NORMAIS NAS BARRAS ---\n');
        fprintf('%-8s  %-22s  %s\n', 'Barra', 'N (kN)', 'Tipo');
        fprintf('%s\n', repmat('-', 1, 50));
        for i = 1:nElementos
            if N(i) >= 0
                tipo = 'TRACAO';
            else
                tipo = 'COMPRESSAO';
            end
            fprintf('%-8d  %+.6e          %s\n', i, N(i)/1e3, tipo);
        end

    case 3
        fprintf('\n--- REACOES DE APOIO ---\n');
        fprintf('%-5s  %-22s  %-22s\n', 'No', 'RX (kN)', 'RY (kN)');
        fprintf('%s\n', repmat('-', 1, 55));
        for i = 1:nNos
            if RESTRICAO(2*i-1) == 1 || RESTRICAO(2*i) == 1
                fprintf('%-5d  %+.6e          %+.6e\n', i, R(2*i-1)/1e3, R(2*i)/1e3);
            end
        end

    case 4
        fprintf('\n--- DESLOCAMENTOS NODAIS ---\n');
        fprintf('%-5s  %-22s  %-22s\n', 'No', 'UX (m)', 'UY (m)');
        fprintf('%s\n', repmat('-', 1, 55));
        for i = 1:nNos
            fprintf('%-5d  %+.6e          %+.6e\n', i, U(2*i-1), U(2*i));
        end

        fprintf('\n--- FORCAS NORMAIS NAS BARRAS ---\n');
        fprintf('%-8s  %-22s  %s\n', 'Barra', 'N (kN)', 'Tipo');
        fprintf('%s\n', repmat('-', 1, 50));
        for i = 1:nElementos
            if N(i) >= 0
                tipo = 'TRACAO';
            else
                tipo = 'COMPRESSAO';
            end
            fprintf('%-8d  %+.6e          %s\n', i, N(i)/1e3, tipo);
        end

        fprintf('\n--- REACOES DE APOIO ---\n');
        fprintf('%-5s  %-22s  %-22s\n', 'No', 'RX (kN)', 'RY (kN)');
        fprintf('%s\n', repmat('-', 1, 55));
        for i = 1:nNos
            if RESTRICAO(2*i-1) == 1 || RESTRICAO(2*i) == 1
                fprintf('%-5d  %+.6e          %+.6e\n', i, R(2*i-1)/1e3, R(2*i)/1e3);
            end
        end

    otherwise
        fprintf('Opcao invalida.\n');
end

%% PASSO 19 — Plot da Trelica (Original e Deformada)

escala = 1000;  % fator de amplificacao visual da deformacao

figure;
hold on; grid on; axis equal;
title('Trelica Plana — Original (azul) e Deformada (vermelho)');
xlabel('x (m)'); ylabel('y (m)');

for i = 1:nElementos
    ii = CONEC(i,1);
    jj = CONEC(i,2);
    % Original
    plot([COORDNOS(ii,1), COORDNOS(jj,1)], ...
         [COORDNOS(ii,2), COORDNOS(jj,2)], 'b--', 'LineWidth', 1.5);
    % Deformada
    xd = [COORDNOS(ii,1)+escala*U(2*ii-1), COORDNOS(jj,1)+escala*U(2*jj-1)];
    yd = [COORDNOS(ii,2)+escala*U(2*ii),   COORDNOS(jj,2)+escala*U(2*jj)];
    plot(xd, yd, 'r-', 'LineWidth', 2);
end

for i = 1:nNos
    % No original
    plot(COORDNOS(i,1), COORDNOS(i,2), 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
    text(COORDNOS(i,1)+0.05, COORDNOS(i,2)+0.05, sprintf('N%d',i), 'Color','b','FontSize',10);
    % No deformado
    xd = COORDNOS(i,1) + escala*U(2*i-1);
    yd = COORDNOS(i,2) + escala*U(2*i);
    plot(xd, yd, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
end

legend('Original','Deformada (amplificada)','Location','best');
hold off;

