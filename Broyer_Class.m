clear;
clc;
close all;

%% =========================
% TD1 - Grinding Basics
% Clean and structured version
% With F50 and F80
% ==========================

%% 1) Input data

% Particle size classes (microns), sorted from finest to coarsest
data.size_classes_um = [75 150 300 600 1200 2400];

% Feed PSD in mass percent for each class
data.PSD_feed_percent = [10 15 20 25 20 10];

% Bond Work Index (kWh/t)
data.Wi_kWh_per_t = 14;

% Assumed product P80 (microns)
data.P80_um = 150;

% Fresh solids feed rate (t/h)
data.F_fresh_tph = 100;

%% 2) Validation of inputs

validateattributes(data.size_classes_um, {'numeric'}, ...
    {'vector', 'real', 'positive', 'increasing'}, mfilename, 'size_classes_um');

validateattributes(data.PSD_feed_percent, {'numeric'}, ...
    {'vector', 'real', 'nonnegative'}, mfilename, 'PSD_feed_percent');

if numel(data.size_classes_um) ~= numel(data.PSD_feed_percent)
    error('size_classes_um and PSD_feed_percent must have the same length.');
end

if sum(data.PSD_feed_percent) <= 0
    error('PSD_feed_percent must have a strictly positive sum.');
end

%% 3) Convert PSD to mass fractions

PSD_feed = data.PSD_feed_percent(:)' / sum(data.PSD_feed_percent);
size_classes = data.size_classes_um(:)';

n_classes = numel(size_classes);

%% 4) Compute cumulative passing

% Since classes are ordered from finest to coarsest,
% cumulative sum represents cumulative passing.
PSD_cum_passing = cumsum(PSD_feed);

%% 5) Compute F50 and F80 using interpolation

target_F50 = 0.50;
target_F80 = 0.80;

F50_um = interpolate_F_value(size_classes, PSD_cum_passing, target_F50);
F80_um = interpolate_F_value(size_classes, PSD_cum_passing, target_F80);

%% 6) Bond specific energy calculation

Wi = data.Wi_kWh_per_t;
P80_um = data.P80_um;
F_fresh_tph = data.F_fresh_tph;

if P80_um <= 0 || F80_um <= 0
    error('P80 and F80 must be strictly positive.');
end

if P80_um >= F80_um
    warning('P80 is greater than or equal to F80. Energy may be zero or negative, which is unusual for grinding.');
end

W_kWh_per_t = 10 * Wi * (1/sqrt(P80_um) - 1/sqrt(F80_um));

if W_kWh_per_t < 0
    warning('Computed Bond energy is negative. Check F80 and P80 assumptions.');
end

%% 7) Mill power

Power_kW = W_kWh_per_t * F_fresh_tph;

%% 8) Store results in a structured way

results.feed.size_classes_um = size_classes;
results.feed.PSD_mass_fraction = PSD_feed;
results.feed.cumulative_passing = PSD_cum_passing;
results.feed.F50_um = F50_um;
results.feed.F80_um = F80_um;

results.mill.Wi_kWh_per_t = Wi;
results.mill.P80_um = P80_um;
results.mill.specific_energy_kWh_per_t = W_kWh_per_t;
results.mill.power_kW = Power_kW;

results.circuit.F_fresh_tph = F_fresh_tph;
results.meta.n_classes = n_classes;

%% 9) Display results

fprintf('\n================ RESULTS ================\n');
fprintf('Number of size classes   : %d\n', results.meta.n_classes);
fprintf('F50                      : %.2f microns\n', results.feed.F50_um);
fprintf('F80                      : %.2f microns\n', results.feed.F80_um);
fprintf('Assumed P80              : %.2f microns\n', results.mill.P80_um);
fprintf('Specific energy (Bond)   : %.4f kWh/t\n', results.mill.specific_energy_kWh_per_t);
fprintf('Mill power               : %.2f kW\n', results.mill.power_kW);
fprintf('Fresh solids feed rate   : %.2f t/h\n', results.circuit.F_fresh_tph);
fprintf('=========================================\n\n');

%% 10) Plot feed PSD

figure('Name', 'Feed PSD');
bar(size_classes, PSD_feed, 'FaceColor', [0.2 0.5 0.8], 'EdgeColor', 'k');
set(gca, 'XScale', 'log');
xlabel('Particle size (\mum)');
ylabel('Mass fraction');
title('Feed Particle Size Distribution');
grid on;

%% 11) Plot cumulative passing

figure('Name', 'Cumulative Passing');
plot(size_classes, PSD_cum_passing, 'o-', 'LineWidth', 1.5, 'MarkerSize', 7);
set(gca, 'XScale', 'log');
xlabel('Particle size (\mum)');
ylabel('Cumulative passing');
title('Cumulative Particle Size Distribution');
grid on;
hold on;

% Mark F50
plot(F50_um, target_F50, 'md', 'MarkerSize', 9, 'LineWidth', 1.5);
yline(target_F50, '--m', '50% passing', 'LineWidth', 1.0);
xline(F50_um, '--m', sprintf('F50 = %.2f \\mum', F50_um), 'LineWidth', 1.0);

% Mark F80
plot(F80_um, target_F80, 'rs', 'MarkerSize', 9, 'LineWidth', 1.5);
yline(target_F80, '--r', '80% passing', 'LineWidth', 1.0);
xline(F80_um, '--k', sprintf('F80 = %.2f \\mum', F80_um), 'LineWidth', 1.0);

legend('Cumulative PSD', 'F50', '50% line', 'F50 vertical', ...
       'F80', '80% line', 'F80 vertical', 'Location', 'best');

hold off;

%% 12) Optional: save workspace results

% save('TD1_results.mat', 'data', 'results'); 

%% =========================
% Local function
% ==========================
function F_value = interpolate_F_value(size_classes, cumulative_passing, target)
    % Interpolates the particle size corresponding to a target cumulative passing

    validateattributes(size_classes, {'numeric'}, {'vector', 'real', 'positive'});
    validateattributes(cumulative_passing, {'numeric'}, {'vector', 'real', '>=', 0, '<=', 1});
    validateattributes(target, {'numeric'}, {'scalar', 'real', '>=', 0, '<=', 1});

    if numel(size_classes) ~= numel(cumulative_passing)
        error('size_classes and cumulative_passing must have the same length.');
    end

    if target < min(cumulative_passing) || target > max(cumulative_passing)
        error('Target passing lies outside the cumulative passing range.');
    end

    F_value = interp1(cumulative_passing, size_classes, target, 'linear');
end