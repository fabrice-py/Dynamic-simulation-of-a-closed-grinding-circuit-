clear;
clc;
close all;

%% ==========================================================
% Dynamic Closed Circuit with Residence Time
% Mill + Hydrocyclone + Recycle + Pulp + Bond Energy
% ===========================================================

%% 1) PARTICLE SIZE CLASSES

size_classes = [75 150 300 600 1200 2400];
n = length(size_classes);

%% 2) FRESH FEED (base case)

PSD_fresh_base = [10 15 20 25 20 10];
PSD_fresh_base = PSD_fresh_base / sum(PSD_fresh_base);

F_fresh_base = 100;   % t/h solids
W_fresh_base = 40;    % t/h water

%% 3) PHYSICAL CONSTANTS

rho_s = 2700;   % kg/m3
rho_w = 1000;   % kg/m3

%% 4) MILL PARAMETERS

selection = [0 0.05 0.10 0.20 0.35 0.50];

tau_h = 0.25;   % residence time in hours (15 min)

%% 5) CYCLONE PARAMETERS

d50 = 300;               % microns
k = 2.5;                 % sharpness
water_overflow_split = 0.80;

%% 6) BOND PARAMETERS

Wi = 14;   % kWh/t

%% 7) BREAKAGE MATRIX

B = zeros(n,n);

B(1,1)=1;
B(1,2)=1;
B(1,3)=0.3; B(2,3)=0.7;
B(1,4)=0.1; B(2,4)=0.3; B(3,4)=0.6;
B(2,5)=0.2; B(3,5)=0.3; B(4,5)=0.5;
B(3,6)=0.2; B(4,6)=0.3; B(5,6)=0.5;

%% 8) TIME GRID

t_end = 5;          % hours
dt = 0.01;          % hours
time = 0:dt:t_end;
nt = length(time);

%% 9) STORAGE ARRAYS

F_fresh_hist   = zeros(nt,1);
F_product_hist = zeros(nt,1);
F_recycle_hist = zeros(nt,1);
F_mill_hist    = zeros(nt,1);

W_mill_hist    = zeros(nt,1);
Cw_hist        = zeros(nt,1);
rho_p_hist     = zeros(nt,1);
Q_pulp_hist    = zeros(nt,1);

P50_hist       = zeros(nt,1);
P80_hist       = zeros(nt,1);
MP50_hist      = zeros(nt,1);
MP80_hist      = zeros(nt,1);

Power_hist     = zeros(nt,1);
CL_hist        = zeros(nt,1);
Holdup_hist    = zeros(nt,1);

%% 10) INITIAL CONDITIONS

% Initial mill holdup (t of solids in each class)
M = 10 * PSD_fresh_base;   % total initial holdup = 10 t solids

% Initial recycle
F_recycle = 0;
PSD_recycle = zeros(1,n);
W_recycle = 0;

%% 11) DYNAMIC SIMULATION LOOP

for it = 1:nt

    t = time(it);

    %% ---- Disturbance scenario ----
    % At t = 2 h, increase fresh feed by 20%
    if t < 2
        F_fresh = F_fresh_base;
        PSD_fresh = PSD_fresh_base;
        W_fresh = W_fresh_base;
    else
        F_fresh = 1.20 * F_fresh_base;
        PSD_fresh = PSD_fresh_base;
        W_fresh = W_fresh_base;
    end

    %% ---- Fresh and recycle solids by class ----
    solids_fresh = F_fresh * PSD_fresh;
    solids_recycle = F_recycle * PSD_recycle;

    solids_in = solids_fresh + solids_recycle;

    %% ---- Mill outflow from current holdup ----
    solids_out = M / tau_h;              % t/h by class
    F_mill_out = sum(solids_out);

    % PSD of mill out
    if F_mill_out > 0
        PSD_mill_out = solids_out / F_mill_out;
    else
        PSD_mill_out = zeros(1,n);
    end

    %% ---- Internal breakage on mill outflow representation ----
    PSD_mill_out_broken = run_mill(PSD_mill_out, selection, B);
    solids_out_broken = F_mill_out * PSD_mill_out_broken;

    %% ---- Dynamic mill mass balance ----
    % dM/dt = solids_in - solids_out_broken
    dMdt = solids_in - solids_out_broken;

    M_new = M + dt * dMdt;

    % Prevent negative masses
    M_new(M_new < 0) = 0;

    M = M_new;

    %% ---- Cyclone on mill discharge ----
    [F_of, PSD_of, F_uf, PSD_uf, P_of] = run_simple_cyclone( ...
        F_mill_out, PSD_mill_out_broken, size_classes, d50, k);

    %% ---- Water balance ----
    W_mill = W_fresh + W_recycle;
    W_of = W_mill * water_overflow_split;
    W_uf = W_mill * (1 - water_overflow_split);

    %% ---- Update recycle for next time step ----
    F_recycle = F_uf;
    PSD_recycle = PSD_uf;
    W_recycle = W_uf;

    %% ---- Mill feed totals ----
    F_mill = F_fresh + F_recycle;

    %% ---- Pulp properties ----
    if (F_mill + W_mill) > 0
        Cw = F_mill / (F_mill + W_mill);
        rho_p = 1 / ((Cw / rho_s) + ((1 - Cw) / rho_w));
        Q_pulp = (F_mill + W_mill) * 1000 / rho_p;   % m3/h
    else
        Cw = 0;
        rho_p = rho_w;
        Q_pulp = 0;
    end

    %% ---- Granulometric metrics ----
    if sum(PSD_of) > 0
        cum_prod = cumsum(PSD_of);
        P50 = interp_psd_metric_safe(size_classes, cum_prod, 0.50);
        P80 = interp_psd_metric_safe(size_classes, cum_prod, 0.80);
    else
        P50 = NaN;
        P80 = NaN;
    end

    if sum(PSD_mill_out_broken) > 0
        cum_millprod = cumsum(PSD_mill_out_broken);
        MP50 = interp_psd_metric_safe(size_classes, cum_millprod, 0.50);
        MP80 = interp_psd_metric_safe(size_classes, cum_millprod, 0.80);
    else
        MP50 = NaN;
        MP80 = NaN;
    end

    %% ---- Bond energy and power ----
    cum_feed = cumsum(PSD_fresh);
    F80 = interp_psd_metric_safe(size_classes, cum_feed, 0.80);

    if ~isnan(P80) && P80 > 0 && F80 > 0
        specific_energy = 10 * Wi * (1/sqrt(P80) - 1/sqrt(F80));
    else
        specific_energy = NaN;
    end

    if ~isnan(specific_energy)
        Power_kW = specific_energy * F_mill;
    else
        Power_kW = NaN;
    end

    %% ---- Circulating load ----
    CL = F_recycle / F_fresh;

    %% ---- Save history ----
    F_fresh_hist(it)   = F_fresh;
    F_product_hist(it) = F_of;
    F_recycle_hist(it) = F_recycle;
    F_mill_hist(it)    = F_mill;

    W_mill_hist(it)    = W_mill;
    Cw_hist(it)        = Cw;
    rho_p_hist(it)     = rho_p;
    Q_pulp_hist(it)    = Q_pulp;

    P50_hist(it)       = P50;
    P80_hist(it)       = P80;
    MP50_hist(it)      = MP50;
    MP80_hist(it)      = MP80;

    Power_hist(it)     = Power_kW;
    CL_hist(it)        = CL;
    Holdup_hist(it)    = sum(M);
end

%% 12) FINAL DISPLAY

fprintf('\n============= TD4.6 DYNAMIC RESULTS =============\n');
fprintf('Final fresh feed flow       : %.2f t/h\n', F_fresh_hist(end));
fprintf('Final mill feed flow        : %.2f t/h\n', F_mill_hist(end));
fprintf('Final product flow          : %.2f t/h\n', F_product_hist(end));
fprintf('Final recycle flow          : %.2f t/h\n', F_recycle_hist(end));
fprintf('Final circulating load      : %.4f\n', CL_hist(end));
fprintf('Final mill holdup           : %.2f t solids\n', Holdup_hist(end));
fprintf('Final mill solids fraction  : %.4f\n', Cw_hist(end));
fprintf('Final pulp density          : %.2f kg/m3\n', rho_p_hist(end));
fprintf('Final pulp flowrate         : %.2f m3/h\n', Q_pulp_hist(end));
fprintf('Final product P50           : %.2f um\n', P50_hist(end));
fprintf('Final product P80           : %.2f um\n', P80_hist(end));
fprintf('Final mill product MP50     : %.2f um\n', MP50_hist(end));
fprintf('Final mill product MP80     : %.2f um\n', MP80_hist(end));
fprintf('Final mill power            : %.2f kW\n', Power_hist(end));
fprintf('=================================================\n\n');

%% 13) PLOTS

figure('Name','Dynamic Flows');
plot(time, F_fresh_hist, 'k-', 'LineWidth', 1.5); hold on;
plot(time, F_mill_hist, 'b-', 'LineWidth', 1.5);
plot(time, F_product_hist, 'g-', 'LineWidth', 1.5);
plot(time, F_recycle_hist, 'r-', 'LineWidth', 1.5);
xlabel('Time (h)');
ylabel('Flowrate (t/h)');
title('Dynamic Flowrates');
legend('Fresh Feed','Mill Feed','Product','Recycle','Location','best');
grid on;

figure('Name','Dynamic Circulating Load');
plot(time, CL_hist, 'LineWidth', 1.5);
xlabel('Time (h)');
ylabel('Circulating Load');
title('Circulating Load vs Time');
grid on;

figure('Name','Dynamic Product Size');
plot(time, P50_hist, 'LineWidth', 1.5); hold on;
plot(time, P80_hist, 'LineWidth', 1.5);
xlabel('Time (h)');
ylabel('Size (\mum)');
title('Final Product Granulometric Metrics');
legend('P50','P80','Location','best');
grid on;

figure('Name','Dynamic Mill Product Size');
plot(time, MP50_hist, 'LineWidth', 1.5); hold on;
plot(time, MP80_hist, 'LineWidth', 1.5);
xlabel('Time (h)');
ylabel('Size (\mum)');
title('Mill Product Granulometric Metrics');
legend('MP50','MP80','Location','best');
grid on;

figure('Name','Dynamic Power and Holdup');
yyaxis left
plot(time, Power_hist, 'LineWidth', 1.5);
ylabel('Power (kW)');

yyaxis right
plot(time, Holdup_hist, 'LineWidth', 1.5);
ylabel('Holdup (t solids)');

xlabel('Time (h)');
title('Mill Power and Solids Holdup');
grid on;

figure('Name','Dynamic Pulp Properties');
subplot(3,1,1)
plot(time, Cw_hist, 'LineWidth', 1.5);
ylabel('Cw');
title('Mill Pulp Solids Fraction');
grid on;

subplot(3,1,2)
plot(time, rho_p_hist, 'LineWidth', 1.5);
ylabel('\rho_p (kg/m3)');
title('Mill Pulp Density');
grid on;

subplot(3,1,3)
plot(time, Q_pulp_hist, 'LineWidth', 1.5);
ylabel('Q (m3/h)');
xlabel('Time (h)');
title('Mill Pulp Volumetric Flowrate');
grid on;

%% ==========================================================
% LOCAL FUNCTIONS
% ==========================================================

function PSD_out = run_mill(PSD_in, selection, B)

    n = length(PSD_in);
    PSD_out = zeros(1,n);

    for j = 1:n
        f = PSD_in(j);
        s = selection(j);

        unbroken = (1 - s) * f;
        broken = s * f;

        PSD_out(j) = PSD_out(j) + unbroken;
        PSD_out = PSD_out + broken * B(:,j)';
    end

    PSD_out = PSD_out / sum(PSD_out);
end

function [F_overflow, PSD_overflow, F_underflow, PSD_underflow, P_overflow] = ...
    run_simple_cyclone(F_feed, PSD_feed, size_classes, d50, k)

    if F_feed <= 0 || sum(PSD_feed) <= 0
        F_overflow = 0;
        F_underflow = 0;
        PSD_overflow = zeros(size(PSD_feed));
        PSD_underflow = zeros(size(PSD_feed));
        P_overflow = zeros(size(PSD_feed));
        return;
    end

    P_overflow = 1 ./ (1 + (size_classes ./ d50).^k);
    P_underflow = 1 - P_overflow;

    OF_partial = PSD_feed .* P_overflow;
    UF_partial = PSD_feed .* P_underflow;

    OF_yield = sum(OF_partial);
    UF_yield = sum(UF_partial);

    PSD_overflow = OF_partial / OF_yield;
    PSD_underflow = UF_partial / UF_yield;

    F_overflow = F_feed * OF_yield;
    F_underflow = F_feed * UF_yield;
end

function D = interp_psd_metric_safe(size_classes, cumulative_curve, target)

    if any(isnan(cumulative_curve)) || max(cumulative_curve) < target || min(cumulative_curve) > target
        D = NaN;
        return;
    end

    D = interp1(cumulative_curve, size_classes, target, 'linear');
end