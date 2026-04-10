%% =========================================================
% Comparison: Fresh Feed vs Mill Product vs Overflow
% =========================================================
clear; clc; close all;

%% 1. Size classes
size_classes = [75 150 300 600 1200 2400];

%% 2. Data Vectors (Example values - replace with your simulation results)
% Fresh Feed (Entrée du circuit)
fresh_feed   = [2 5 10 25 35 23]; 
% Mill product (Sortie broyeur)
mill_product = [12 18 24 30 24.01 11.99];
% Overflow (Produit fini)
overflow     = [29.92 38.15 31.79 15.90 3.741 0.4899];

%% 3. Normalize into PSD
PSD_feed     = fresh_feed / sum(fresh_feed);
PSD_mill     = mill_product / sum(mill_product);
PSD_overflow = overflow / sum(overflow);

%% 4. Cumulative passing
cum_feed     = cumsum(PSD_feed);
cum_mill     = cumsum(PSD_mill);
cum_overflow = cumsum(PSD_overflow);

%% 5. Compute Metrics (F50, F80, P50, P80)
% Fresh Feed
F50 = interp1(cum_feed, size_classes, 0.50, 'linear');
F80 = interp1(cum_feed, size_classes, 0.80, 'linear');
% Mill
P50_mill = interp1(cum_mill, size_classes, 0.50, 'linear');
P80_mill = interp1(cum_mill, size_classes, 0.80, 'linear');
% Overflow
P50_over = interp1(cum_overflow, size_classes, 0.50, 'linear');
P80_over = interp1(cum_overflow, size_classes, 0.80, 'linear');

%% 6. Plot cumulative PSD
figure('Color','w', 'Name', 'Circuit PSD Comparison');
hold on; grid on;

% Plot curves
plot(size_classes, cum_feed, 'rd-', 'LineWidth', 1.8, 'MarkerSize', 7, 'DisplayName', 'Fresh Feed (Input)');
plot(size_classes, cum_mill, 'ko-', 'LineWidth', 1.8, 'MarkerSize', 7, 'DisplayName', 'Mill Product');
plot(size_classes, cum_overflow, 'bs-', 'LineWidth', 1.8, 'MarkerSize', 7, 'DisplayName', 'Overflow (Output)');

set(gca, 'XScale', 'log');
xlabel('Particle size (\mum)');
ylabel('Cumulative passing (-)');
title('Circuit Granulometry Comparison');
ylim([0 1.05]);

% Reference lines
yline(0.50, '--', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
yline(0.80, '--', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');

% Vertical markers for P80
xline(F80, ':r', sprintf('F80=%.0f', F80), 'LabelVerticalAlignment', 'bottom');
xline(P80_mill, ':k', sprintf('Mill P80=%.0f', P80_mill), 'LabelVerticalAlignment', 'bottom');
xline(P80_over, ':b', sprintf('Over P80=%.0f', P80_over), 'LabelVerticalAlignment', 'bottom');

legend('Location', 'best');
hold off;

%% 7. Print Summary Table (FIXED SYNTAX)
sep_line = repmat('=', 1, 45);
dash_line = repmat('-', 1, 45);

fprintf('\n%s\n', sep_line);
fprintf('%-15s | %-10s | %-10s\n', 'Stream', 'P50 (µm)', 'P80 (µm)');
fprintf('%s\n', dash_line);
fprintf('%-15s | %-10.2f | %-10.2f\n', 'Fresh Feed', F50, F80);
fprintf('%-15s | %-10.2f | %-10.2f\n', 'Mill Product', P50_mill, P80_mill);
fprintf('%-15s | %-10.2f | %-10.2f\n', 'Overflow', P50_over, P80_over);
fprintf('%s\n\n', sep_line);