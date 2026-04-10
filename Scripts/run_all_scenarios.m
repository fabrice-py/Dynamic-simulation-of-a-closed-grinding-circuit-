function [results, results_table] = run_all_scenarios()
    cfg = config();
    scenario_fields = fieldnames(cfg);
    scenario_fields = scenario_fields(startsWith(scenario_fields, 'scenario'));
    n = numel(scenario_fields);
    results = struct([]);

    for i = 1:n
        scenario_id = scenario_fields{i};
        fprintf('\nRunning %s...\n', scenario_id);
        
        % This calls your updated extract_results automatically via run_one_scenario
        current_result = run_one_scenario(scenario_id);
        
        if i == 1
            results = current_result;
        else
            % Ensures all fields (including the new Energy ones) are aligned
            results(i) = orderfields(current_result, results(1));
        end

        % Displaying new energy metrics in console
        fprintf('  P80 Overflow : %.2f µm\n', results(i).P80_overflow);
        fprintf('  CL           : %.4f (-)\n', results(i).CL);
        fprintf('  Mill Power   : %.2f kW\n', results(i).Mill_Power_kW);
        fprintf('  Spec. Energy : %.2f kWh/t\n', results(i).Specific_Energy);
    end

    % --- Saving Results ---
    if ~exist('results_dir', 'dir') % Changed name slightly to avoid conflict with variable
        mkdir('results');
    end
    save('results/all_scenarios_results.mat', 'results');

    % --- Table Generation (Adding Energy Columns) ---
    scenario_names = strings(n,1);
    P80_overflow_um = zeros(n,1);
    CL_ratio        = zeros(n,1);
    Power_kW        = zeros(n,1);
    Energy_kwh      = zeros(n,1);
    Kb_val          = zeros(n,1);

    for i = 1:n
        scenario_names(i)  = string(results(i).scenario_id);
        P80_overflow_um(i) = results(i).P80_overflow;
        CL_ratio(i)        = results(i).CL;
        Power_kW(i)        = results(i).Mill_Power_kW;
        Energy_kwh(i)      = results(i).Specific_Energy;
        Kb_val(i)          = results(i).Kb;
    end

    results_table = table( ...
        scenario_names, ...
        Kb_val, ...
        P80_overflow_um, ...
        CL_ratio, ...
        Power_kW, ...
        Energy_kwh, ...
        'VariableNames', { ...
            'Scenario', ...
            'Kb', ...
            'P80_overflow_um', ...
            'CL_ratio', ...
            'Power_kW', ...
            'Specific_Energy_kwh_t' ...
        } ...
    );

    fprintf('\n===== SCENARIO COMPARISON TABLE (INCLUDING ENERGY) =====\n');
    disp(results_table);
    writetable(results_table, 'results/all_scenarios_results.csv');
    disp('All scenarios completed. Energy data successfully saved.');
    % --- Nouvelle section de sauvegarde sécurisée ---
    current_dir = pwd; % Récupère le chemin actuel
    target_dir = fullfile(current_dir, 'results');
    
    if ~exist(target_dir, 'dir')
        mkdir(target_dir);
    end
    
    save_path = fullfile(target_dir, 'all_scenarios_results.mat');
    save(save_path, 'results');
    fprintf('### Data saved successfully in: %s ###\n', save_path);
end