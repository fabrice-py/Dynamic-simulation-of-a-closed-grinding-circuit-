function generate_final_report(results)
% GENERATE_FINAL_REPORT - Generates the 5 key engineering plots for grinding analysis
% results: structure array from extract_results

if nargin < 1 || isempty(results)
    load('results/all_scenarios_results.mat', 'results');
end

n = numel(results);
colors = lines(n);
size_classes = results(1).size_classes;

%% --- FIGURE 1: GLOBAL CIRCUIT PERFORMANCE (FEED vs MILL vs OVERFLOW) ---
% Takes the first scenario as a reference to show the transformation logic
figure('Name', '1. Circuit Size Transformation', 'Color', 'w');
hold on; grid on;
scen_idx = 1; % Focus on first scenario for clarity
plot(size_classes, cumsum(results(scen_idx).PSD_overflow), 'b-s', 'LineWidth', 2, 'DisplayName', 'Final Product (Overflow)');
plot(size_classes, cumsum(results(scen_idx).PSD_mill), 'k-o', 'LineWidth', 2, 'DisplayName', 'Mill Discharge');
% Assuming PSD_fresh is stored in results
% If not, we use a reference or load it from base
try 
    PSD_fresh = evalin('base', 'PSD_fresh');
    plot(size_classes, cumsum(PSD_fresh), 'r-d', 'LineWidth', 2, 'DisplayName', 'Fresh Feed');
catch
    disp('PSD_fresh not found in workspace, skipping feed curve.');
end
set(gca, 'XScale', 'log');
xlabel('Particle Size (\mum)'); ylabel('Cumulative Passing (-)');
title(['Granulometry Transformation - ', results(scen_idx).scenario_id]);
legend('Location', 'best');

%% --- FIGURE 2: SPECIFIC ENERGY vs PRODUCT FINENESS (P80) ---
figure('Name', '2. Energy vs Fineness', 'Color', 'w');
hold on; grid on;
for i = 1:n
    scatter(results(i).P80_overflow, results(i).Specific_Energy, 200, colors(i,:), 'filled', ...
            'DisplayName', results(i).scenario_id);
    text(results(i).P80_overflow + 5, results(i).Specific_Energy, results(i).scenario_id);
end
xlabel('Product P80 (\mum)'); ylabel('Specific Energy (kWh/t)');
title('Energy Intensity vs Product Size');
legend('Location', 'best');

%% --- FIGURE 3: CIRCULATING LOAD vs MILL POWER ---
figure('Name', '3. Circuit Saturation Analysis', 'Color', 'w');
subplot(2,1,1);
bar(categorical({results.scenario_id}), [results.CL]*100, 'FaceColor', [0.2 0.6 0.8]);
ylabel('Circulating Load (%)'); title('Recirculation Ratio'); grid on;

subplot(2,1,2);
bar(categorical({results.scenario_id}), [results.Mill_Power_kW], 'FaceColor', [0.8 0.4 0.2]);
ylabel('Mill Power (kW)'); title('Total Power Drawn'); grid on;

%% --- FIGURE 4: CYCLONE EFFICIENCY (TROMP CURVE) ---
% This shows the probability of particles going to the underflow
figure('Name', '4. Cyclone Partition (Tromp Curve)', 'Color', 'w');
hold on; grid on;
for i = 1:n
    % Partition = Mass to Underflow / Total Mass at each class
    % Simplified calculation for demonstration
    partition = results(i).F_underflow * results(i).PSD_mill ./ ...
               (results(i).F_underflow * results(i).PSD_mill + results(i).F_overflow * results(i).PSD_overflow + eps);
    plot(size_classes, partition, '-x', 'LineWidth', 1.5, 'Color', colors(i,:), 'DisplayName', results(i).scenario_id);
end
set(gca, 'XScale', 'log');
yline(0.5, '--k', 'd50 cut point');
xlabel('Particle Size (\mum)'); ylabel('Recovery to Underflow (-)');
title('Cyclone Partition Efficiency');
legend('Location', 'best');

%% --- FIGURE 5: SENSITIVITY ANALYSIS (Kb vs POWER) ---
figure('Name', '5. Ore Hardness Impact', 'Color', 'w');
hold on; grid on;

% 1. Extraction et tri des données
kb_raw = [results.Kb];
power_raw = [results.Mill_Power_kW];

% On ne garde que les valeurs uniques de Kb pour éviter le mauvais conditionnement
[kb_unique, idx_unique] = unique(kb_raw);
power_unique = power_raw(idx_unique);

% 2. Plot des points réels
plot(kb_raw, power_raw, 's', 'MarkerSize', 12, 'MarkerFaceColor', 'b', 'DisplayName', 'Simulated Scenarios');

% 3. Calcul de la tendance (uniquement si on a au moins 2 points distincts)
if length(kb_unique) >= 2
    % Utilisation de polyfit avec centrage et réduction pour la stabilité
    [p, ~, mu] = polyfit(kb_unique, power_unique, 1);
    
    % Génération de points pour la ligne de tendance
    kb_range = linspace(min(kb_unique)*0.9, max(kb_unique)*1.1, 50);
    y_fit = polyval(p, kb_range, [], mu);
    
    plot(kb_range, y_fit, '--r', 'LineWidth', 1.5, 'DisplayName', 'Trend Line');
else
    title('Ore Hardness Impact (Need more distinct Kb values for trend)');
end

xlabel('Grindability Index (Kb)');
ylabel('Mill Power (kW)');
title('Sensitivity: Ore Hardness vs Energy Demand');
legend('Location', 'best');
end