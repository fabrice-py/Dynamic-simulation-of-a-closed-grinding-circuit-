%% =========================================
% Comparison: Mill Product vs Overflow
% =========================================

clear; clc; close all;

%% Size classes
size_classes = [75 150 300 600 1200 2400];

%% Replace these with your real vectors
% Mill product = sortie broyeur avant hydrocyclone
mill_product = [12 18 24 30 24.01 11.99];

% Overflow = sortie fine de l'hydrocyclone
overflow = [29.92 38.15 31.79 15.90 3.741 0.4899];

%% Normalize into PSD
PSD_mill = mill_product / sum(mill_product);
PSD_overflow = overflow / sum(overflow);

%% Cumulative passing
cum_mill = cumsum(PSD_mill);
cum_overflow = cumsum(PSD_overflow);

%% Compute P50 and P80
P50_mill = interp1(cum_mill, size_classes, 0.50, 'linear');
P80_mill = interp1(cum_mill, size_classes, 0.80, 'linear');

P50_overflow = interp1(cum_overflow, size_classes, 0.50, 'linear');
P80_overflow = interp1(cum_overflow, size_classes, 0.80, 'linear');

%% Plot cumulative PSD
figure('Color','w');
plot(size_classes, cum_mill, 'ko-', 'LineWidth', 1.8, 'MarkerSize', 8); hold on;
plot(size_classes, cum_overflow, 'bs-', 'LineWidth', 1.8, 'MarkerSize', 8);

set(gca, 'XScale', 'log');
xlabel('Particle size (\mum)');
ylabel('Cumulative passing');
title('Cumulative PSD - Mill Product vs Overflow');
grid on;
ylim([0 1.05]);

% 50% and 80% reference lines
yline(0.50, '--k', '50%');
yline(0.80, '--k', '80%');

% Mark P50
plot(P50_mill, 0.50, 'ko', 'MarkerSize', 8, 'LineWidth', 1.5);
plot(P50_overflow, 0.50, 'bs', 'MarkerSize', 8, 'LineWidth', 1.5);

% Mark P80
plot(P80_mill, 0.80, 'ko', 'MarkerSize', 8, 'LineWidth', 1.5);
plot(P80_overflow, 0.80, 'bs', 'MarkerSize', 8, 'LineWidth', 1.5);

% Vertical lines
xline(P50_mill, '--k', sprintf('Mill P50 = %.1f \\mum', P50_mill), 'LineWidth', 1.2);
xline(P80_mill, '--k', sprintf('Mill P80 = %.1f \\mum', P80_mill), 'LineWidth', 1.2);

xline(P50_overflow, '--b', sprintf('Overflow P50 = %.1f \\mum', P50_overflow), 'LineWidth', 1.2);
xline(P80_overflow, '--b', sprintf('Overflow P80 = %.1f \\mum', P80_overflow), 'LineWidth', 1.2);

legend('Mill Product', 'Overflow', 'Location', 'best');
hold off;

%% Print values
fprintf('\n===== Mill Product vs Overflow =====\n');
fprintf('Mill Product  P50 = %.2f µm\n', P50_mill);
fprintf('Mill Product  P80 = %.2f µm\n', P80_mill);
fprintf('Overflow      P50 = %.2f µm\n', P50_overflow);
fprintf('Overflow      P80 = %.2f µm\n', P80_overflow);
fprintf('====================================\n\n');