clear
clc

%% ==========================================
% INITIALISATION DES PARAMETRES
% Circuit fermé Broyeur + Hydrocyclone
% ==========================================

%% 1) CLASSES GRANULOMETRIQUES

size_classes = [75 150 300 600 1200 2400];   % microns
n_classes = length(size_classes);

%% 2) DISTRIBUTION GRANULOMETRIQUE DU FEED

PSD_fresh = [0.10 0.15 0.20 0.25 0.20 0.10];

% normalisation (important)
PSD_fresh = PSD_fresh / sum(PSD_fresh);

%% 3) DEBITS INITIAUX

F_fresh_base = 100;      % débit solide frais (t/h)
W_fresh_base = 40;       % débit eau frais (t/h)

%% 4) PARAMETRES DU BROYEUR

% Probabilité de cassure par classe
selection = [0 0.05 0.10 0.20 0.35 0.50];

% temps de séjour moyen dans le broyeur (heures)
tau_h = 0.25;

%% 5) MATRICE DE CASSURE (Breakage matrix)

B = zeros(n_classes,n_classes);

B(1,1) = 1;

B(1,2) = 1;

B(1,3) = 0.3;
B(2,3) = 0.7;

B(1,4) = 0.1;
B(2,4) = 0.3;
B(3,4) = 0.6;

B(2,5) = 0.2;
B(3,5) = 0.3;
B(4,5) = 0.5;

B(3,6) = 0.2;
B(4,6) = 0.3;
B(5,6) = 0.5;

%% 6) PARAMETRES HYDROCYCLONE

d50 = 300;                 % taille de coupure (microns)

k_sharpness = 2.5;         % coefficient de netteté

water_overflow_split = 0.80;   % fraction d'eau allant à l'overflow

%% 7) PARAMETRES ENERGETIQUES (Bond)

Wi = 14;    % Work Index (kWh/t)

%% 8) DENSITES

rho_s = 2700;   % densité solide (kg/m3)

rho_w = 1000;   % densité eau (kg/m3)

%% 9) PAS DE TEMPS POUR SIMULATION

dt = 0.01;     % heures

t_end = 5;     % durée simulation (heures)

%% 10) AFFICHAGE RAPIDE

disp('-----------------------------------')
disp('INITIALISATION TD5 TERMINEE')
disp('Variables disponibles :')
disp('size_classes')
disp('PSD_fresh')
disp('F_fresh_base')
disp('W_fresh_base')
disp('selection')
disp('B')
disp('tau_h')
disp('d50')
disp('k_sharpness')
disp('Wi')
disp('-----------------------------------')
