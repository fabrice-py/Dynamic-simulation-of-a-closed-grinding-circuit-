clear;
clc;
close all;

%% ==========================================
% TD2 - Simple Mill Model with Breakage Matrix
% ===========================================

%% 1) INPUT DATA

data.size_classes_um = [75 150 300 600 1200 2400];
data.PSD_feed_percent = [10 15 20 25 20 10];

% Fraction selected for breakage in each class
% Fine classes: low breakage
% Coarse classes: high breakage
data.selection = [0.00 0.05 0.10 0.20 0.35 0.50];

%% 2) VALIDATION

size_classes = data.size_classes_um(:)';
PSD_feed = data.PSD_feed_percent(:)' / sum(data.PSD_feed_percent);
selection = data.selection(:)';

n = numel(size_classes);

if numel(PSD_feed) ~= n || numel(selection) ~= n
    error('size_classes, PSD_feed_percent, and selection must have the same length.');
end

if any(selection < 0) || any(selection > 1)
    error('Selection values must be between 0 and 1.');
end

%% 3) BUILD BREAKAGE MATRIX
% breakage_matrix(i,j) = fraction of broken material from class j
% that reports to class i
%
% Columns = source class
% Rows    = destination class
%
% Only finer classes can receive broken material.

B = zeros(n,n);

% Class 1 (finest): if broken, it stays in class 1
B(1,1) = 1.0;

% Class 2 -> mostly class 1
B(1,2) = 1.0;

% Class 3 -> class 1 and 2
B(1,3) = 0.30;
B(2,3) = 0.70;

% Class 4 -> class 1,2,3
B(1,4) = 0.10;
B(2,4) = 0.30;
B(3,4) = 0.60;

% Class 5 -> class 2,3,4
B(2,5) = 0.20;
B(3,5) = 0.30;
B(4,5) = 0.50;

% Class 6 -> class 3,4,5
B(3,6) = 0.20;
B(4,6) = 0.30;
B(5,6) = 0.50;

% Check that each non-zero column sums to 1
for j = 1:n
    col_sum = sum(B(:,j));
    if col_sum > 0 && abs(col_sum - 1) > 1e-12
        error('Column %d of breakage matrix does not sum to 1.', j);
    end
end

%% 4) APPLY SIMPLE MILL MODEL

PSD_out = zeros(1,n);

for j = 1:n
    feed_j = PSD_feed(j);
    s_j = selection(j);

    unbroken = (1 - s_j) * feed_j;
    broken = s_j * feed_j;

    % Material that remains in the same class
    PSD_out(j) = PSD_out(j) + unbroken;

    % Broken material redistributed to finer classes
    PSD_out = PSD_out + broken * B(:,j)';
end

% Normalize to avoid tiny numerical drift
PSD_out = PSD_out / sum(PSD_out);

%% 5) CUMULATIVE PASSING

PSD_cum_feed = cumsum(PSD_feed);
PSD_cum_out  = cumsum(PSD_out);

%% 6) SIZE METRICS

F50_um = interpolate_F_value(size_classes, PSD_cum_feed, 0.50);
F80_um = interpolate_F_value(size_classes, PSD_cum_feed, 0.80);

P50_um = interpolate_F_value(size_classes, PSD_cum_out, 0.50);
P80_um = interpolate_F_value(size_classes, PSD_cum_out, 0.80);

RR50 = F50_um / P50_um;
RR80 = F80_um / P80_um;

%% 7) DISPLAY RESULTS

fprintf('\n============== TD2 RESULTS ==============\n');
fprintf('Feed F50   : %.2f um\n', F50_um);
fprintf('Feed F80   : %.2f um\n', F80_um);
fprintf('Prod P50   : %.2f um\n', P50_um);
fprintf('Prod P80   : %.2f um\n', P80_um);
fprintf('RR50       : %.3f\n', RR50);
fprintf('RR80       : %.3f\n', RR80);
fprintf('Mass check : %.6f\n', sum(PSD_out));
fprintf('=========================================\n\n');

%% 8) PLOTS

figure('Name','PSD Comparison');
bar(size_classes, [PSD_feed; PSD_out]');
set(gca,'XScale','log');
xlabel('Particle size (\mum)');
ylabel('Mass fraction');
title('Feed vs Product PSD');
legend('Feed','Product');
grid on;

figure('Name','Cumulative Passing Comparison');
plot(size_classes, PSD_cum_feed, 'o-', 'LineWidth', 1.5, 'MarkerSize', 7);
hold on;
plot(size_classes, PSD_cum_out, 's-', 'LineWidth', 1.5, 'MarkerSize', 7);
set(gca,'XScale','log');
xlabel('Particle size (\mum)');
ylabel('Cumulative passing');
title('Cumulative PSD: Feed vs Product');
legend('Feed','Product','Location','best');
grid on;

% Mark F50/F80 and P50/P80
plot(F50_um, 0.50, 'ko', 'MarkerSize', 8, 'LineWidth', 1.5);
plot(F80_um, 0.80, 'ko', 'MarkerSize', 8, 'LineWidth', 1.5);
plot(P50_um, 0.50, 'rs', 'MarkerSize', 8, 'LineWidth', 1.5);
plot(P80_um, 0.80, 'rs', 'MarkerSize', 8, 'LineWidth', 1.5);

yline(0.50, '--', '50%');
yline(0.80, '--', '80%');

hold off;

%% 9) SAVE RESULTS IN STRUCT

results.feed.size_classes_um = size_classes;
results.feed.PSD = PSD_feed;
results.feed.cumulative = PSD_cum_feed;
results.feed.F50_um = F50_um;
results.feed.F80_um = F80_um;

results.product.PSD = PSD_out;
results.product.cumulative = PSD_cum_out;
results.product.P50_um = P50_um;
results.product.P80_um = P80_um;

results.model.selection = selection;
results.model.breakage_matrix = B;
results.model.RR50 = RR50;
results.model.RR80 = RR80;

%% =========================
% LOCAL FUNCTION
% ==========================
function F_value = interpolate_F_value(size_classes, cumulative_passing, target)

    if numel(size_classes) ~= numel(cumulative_passing)
        error('size_classes and cumulative_passing must have same length.');
    end

    if target < min(cumulative_passing) || target > max(cumulative_passing)
        error('Target %.2f lies outside cumulative range.', target);
    end

    F_value = interp1(cumulative_passing, size_classes, target, 'linear');
end