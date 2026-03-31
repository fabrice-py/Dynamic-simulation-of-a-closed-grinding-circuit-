clear;
clc;
close all;

%% ==========================================
% TD3 - Simple Hydrocyclone Model
% ===========================================

%% 1) INPUT DATA

data.size_classes_um = [75 150 300 600 1200 2400];

% Cyclone feed PSD (% mass)
% Ici, on peut mettre soit une PSD inventée,
% soit la sortie du broyeur du TD2
data.PSD_cyclone_feed_percent = [18 20 22 18 14 8];

% Cyclone feed solids flowrate (t/h)
data.F_cyclone_feed_tph = 180;

% Cyclone cut size (microns)
data.d50_um = 200;

% Sharpness parameter
data.k_sharpness = 2.5;

%% 2) VALIDATION

size_classes = data.size_classes_um(:)';
PSD_feed = data.PSD_cyclone_feed_percent(:)' / sum(data.PSD_cyclone_feed_percent);
F_feed = data.F_cyclone_feed_tph;
d50 = data.d50_um;
k = data.k_sharpness;

n = numel(size_classes);

if numel(PSD_feed) ~= n
    error('size_classes and PSD_cyclone_feed_percent must have same length.');
end

if F_feed <= 0
    error('Cyclone feed flowrate must be positive.');
end

if d50 <= 0 || k <= 0
    error('d50 and k_sharpness must be strictly positive.');
end

%% 3) PARTITION TO OVERFLOW

% Probability of reporting to overflow for each size class
P_overflow = 1 ./ (1 + (size_classes ./ d50).^k);

% Underflow partition
P_underflow = 1 - P_overflow;

%% 4) SPLIT THE FEED PSD

% Mass fraction of each class going to overflow and underflow
OF_partial = PSD_feed .* P_overflow;
UF_partial = PSD_feed .* P_underflow;

% Total mass split
OF_yield = sum(OF_partial);
UF_yield = sum(UF_partial);

% Normalize PSDs in each stream
PSD_overflow = OF_partial / OF_yield;
PSD_underflow = UF_partial / UF_yield;

%% 5) FLOWRATES

F_overflow_tph = F_feed * OF_yield;
F_underflow_tph = F_feed * UF_yield;

%% 6) CUMULATIVE PASSING

PSD_cum_feed = cumsum(PSD_feed);
PSD_cum_OF   = cumsum(PSD_overflow);
PSD_cum_UF   = cumsum(PSD_underflow);

%% 7) SIZE METRICS

F50_um  = interpolate_size_metric(size_classes, PSD_cum_feed, 0.50);
F80_um  = interpolate_size_metric(size_classes, PSD_cum_feed, 0.80);

O50_um  = interpolate_size_metric(size_classes, PSD_cum_OF, 0.50);
O80_um  = interpolate_size_metric(size_classes, PSD_cum_OF, 0.80);

U50_um  = interpolate_size_metric(size_classes, PSD_cum_UF, 0.50);
U80_um  = interpolate_size_metric(size_classes, PSD_cum_UF, 0.80);

%% 8) SIMPLE CIRCULATING LOAD INDICATOR

% Si l'underflow retourne au broyeur et que l'overflow est produit,
% une définition simple de charge circulante est :
% CL = Underflow / Fresh Feed
%
% Ici, comme on n'a pas encore reconnecté le circuit, on calcule aussi :
% split ratio = Underflow / Overflow

split_UF_OF = F_underflow_tph / F_overflow_tph;

%% 9) MASS CHECK

mass_check = OF_yield + UF_yield;

%% 10) STORE RESULTS

results.feed.size_classes_um = size_classes;
results.feed.PSD = PSD_feed;
results.feed.flow_tph = F_feed;
results.feed.F50_um = F50_um;
results.feed.F80_um = F80_um;

results.partition.P_overflow = P_overflow;
results.partition.P_underflow = P_underflow;
results.partition.d50_um = d50;
results.partition.k_sharpness = k;

results.overflow.PSD = PSD_overflow;
results.overflow.flow_tph = F_overflow_tph;
results.overflow.O50_um = O50_um;
results.overflow.O80_um = O80_um;

results.underflow.PSD = PSD_underflow;
results.underflow.flow_tph = F_underflow_tph;
results.underflow.U50_um = U50_um;
results.underflow.U80_um = U80_um;

results.performance.OF_yield = OF_yield;
results.performance.UF_yield = UF_yield;
results.performance.split_UF_OF = split_UF_OF;
results.performance.mass_check = mass_check;

%% 11) DISPLAY RESULTS

fprintf('\n============= TD3 RESULTS =============\n');
fprintf('Cyclone feed flow       : %.2f t/h\n', F_feed);
fprintf('Overflow flow           : %.2f t/h\n', F_overflow_tph);
fprintf('Underflow flow          : %.2f t/h\n', F_underflow_tph);
fprintf('Overflow yield          : %.4f\n', OF_yield);
fprintf('Underflow yield         : %.4f\n', UF_yield);
fprintf('Mass check              : %.6f\n', mass_check);
fprintf('\n');
fprintf('Feed F50                : %.2f um\n', F50_um);
fprintf('Feed F80                : %.2f um\n', F80_um);
fprintf('Overflow O50            : %.2f um\n', O50_um);
fprintf('Overflow O80            : %.2f um\n', O80_um);
fprintf('Underflow U50           : %.2f um\n', U50_um);
fprintf('Underflow U80           : %.2f um\n', U80_um);
fprintf('UF/OF split ratio       : %.4f\n', split_UF_OF);
fprintf('=======================================\n\n');

%% 12) PLOT PARTITION CURVE

figure('Name','Cyclone Partition Curve');
plot(size_classes, P_overflow, 'o-', 'LineWidth', 1.5, 'MarkerSize', 7);
set(gca,'XScale','log');
xlabel('Particle size (\mum)');
ylabel('Probability to Overflow');
title('Hydrocyclone Partition to Overflow');
grid on;
hold on;
xline(d50, '--r', sprintf('d50 = %.0f \\mum', d50), 'LineWidth', 1.2);
hold off;

%% 13) PLOT PSD COMPARISON

figure('Name','PSD Feed vs Overflow vs Underflow');
bar(size_classes, [PSD_feed; PSD_overflow; PSD_underflow]');
set(gca,'XScale','log');
xlabel('Particle size (\mum)');
ylabel('Mass fraction');
title('Cyclone Feed / Overflow / Underflow PSD');
legend('Feed','Overflow','Underflow','Location','best');
grid on;

%% 14) PLOT CUMULATIVE PASSING

figure('Name','Cumulative PSD Comparison');
plot(size_classes, PSD_cum_feed, 'ko-', 'LineWidth', 1.5, 'MarkerSize', 7);
hold on;
plot(size_classes, PSD_cum_OF, 'bs-', 'LineWidth', 1.5, 'MarkerSize', 7);
plot(size_classes, PSD_cum_UF, 'rd-', 'LineWidth', 1.5, 'MarkerSize', 7);
set(gca,'XScale','log');
xlabel('Particle size (\mum)');
ylabel('Cumulative passing');
title('Cumulative PSD - Feed / Overflow / Underflow');
legend('Feed','Overflow','Underflow','Location','best');
grid on;

% Mark 50% and 80%
yline(0.50, '--', '50%');
yline(0.80, '--', '80%');

plot(F50_um, 0.50, 'ko', 'MarkerSize', 8, 'LineWidth', 1.5);
plot(O50_um, 0.50, 'bs', 'MarkerSize', 8, 'LineWidth', 1.5);
plot(U50_um, 0.50, 'rd', 'MarkerSize', 8, 'LineWidth', 1.5);

plot(F80_um, 0.80, 'ko', 'MarkerSize', 8, 'LineWidth', 1.5);
plot(O80_um, 0.80, 'bs', 'MarkerSize', 8, 'LineWidth', 1.5);
plot(U80_um, 0.80, 'rd', 'MarkerSize', 8, 'LineWidth', 1.5);

hold off;

%% ==========================
% Local function
% ==========================
function D_value = interpolate_size_metric(size_classes, cumulative_passing, target)

    if numel(size_classes) ~= numel(cumulative_passing)
        error('size_classes and cumulative_passing must have same length.');
    end

    if target < min(cumulative_passing) || target > max(cumulative_passing)
        error('Target %.2f lies outside cumulative passing range.', target);
    end

    D_value = interp1(cumulative_passing, size_classes, target, 'linear');
end