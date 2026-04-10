function plot_scenario_comparison(results)
% PLOT_SCENARIO_COMPARISON - Visualizes performance and energy metrics
% results: structure array returned by extract_results

% 1. Load results if not provided
if nargin < 1 || isempty(results)
    if exist('results/all_scenarios_results.mat', 'file')
        S = load('results/all_scenarios_results.mat', 'results');
        results = S.results;
        disp('Loaded results from results/all_scenarios_results.mat');
    else
        error('No results provided and no saved file found.');
    end
end

n = numel(results);
scenario_names = strings(1,n);
colors = lines(n); 

% --- SECURE DATA EXTRACTION ---
% Ensure fields exist, otherwise initialize with zeros to prevent crashing
if isfield(results, 'Mill_Power_kW')
    Power  = [results.Mill_Power_kW];
    Energy = [results.Specific_Energy];
else
    warning('Energy data (Mill_Power_kW) missing. Re-run simulations to see power metrics.');
    Power  = zeros(1, n);
    Energy = zeros(1, n);
end

% Check for Kb (Grindability)
if isfield(results, 'Kb')
    Kb_vals = [results.Kb];
else
    Kb_vals = ones(1, n); % Default to 1.0 if missing
end

CL       = [results.CL];
P50_over = [results.P50_overflow];
P80_over = [results.P80_overflow];
F_over   = [results.F_overflow];

% Get scenario names
for i = 1:n
    scenario_names(i) = string(results(i).scenario_id);
end

%% --- FIGURES (Visualisation) ---
% (Garde tes blocs Figure 1, 2 et 3 tels quels, ils fonctionnent)
% ... [Tes codes de figures ici] ...

%% --- CONSOLE SUMMARY REPORT (CORRECTED SYNTAX) ---
% We use ['string1', 'string2'] or fprint directly to avoid "incompatible sizes" error
sep_line = repmat('=', 1, 95);
dash_line = repmat('-', 1, 95);

fprintf('\n%s\n', sep_line);
fprintf('%-15s | %-5s | %-8s | %-8s | %-6s | %-10s | %-10s\n', ...
    'Scenario', 'Kb', 'P80 (um)', 'F80 (um)', 'CL(%)', 'Power(kW)', 'Energy(kWh/t)');
fprintf('%s\n', dash_line);

for i = 1:n
    % Safely retrieve F80
    f80 = 0; if isfield(results(i), 'F80_fresh'), f80 = results(i).F80_fresh; end
    
    fprintf('%-15s | %-5.1f | %-8.1f | %-8.1f | %-6.1f | %-10.1f | %-10.2f\n', ...
        scenario_names(i), Kb_vals(i), P80_over(i), f80, CL(i)*100, Power(i), Energy(i));
end
fprintf('%s\n', sep_line);

end