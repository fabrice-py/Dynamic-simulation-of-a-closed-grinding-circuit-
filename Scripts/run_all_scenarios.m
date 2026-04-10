function [results, results_table] = run_all_scenarios()

    cfg = config();

    scenario_fields = fieldnames(cfg);
    scenario_fields = scenario_fields(startsWith(scenario_fields, 'scenario'));

    n = numel(scenario_fields);
    results = struct([]);

    for i = 1:n
        scenario_id = scenario_fields{i};
        fprintf('\nRunning %s...\n', scenario_id);

        current_result = run_one_scenario(scenario_id);

        if i == 1
            results = current_result;
        else
            results(i) = orderfields(current_result, results(1));
        end

        fprintf('  P50 Overflow : %.2f µm\n', results(i).P50_overflow);
        fprintf('  P80 Overflow : %.2f µm\n', results(i).P80_overflow);
        fprintf('  P50 Mill     : %.2f µm\n', results(i).P50_mill);
        fprintf('  P80 Mill     : %.2f µm\n', results(i).P80_mill);
        fprintf('  Fresh Feed   : %.2f t/h\n', results(i).F_fresh);
        fprintf('  Mill Output  : %.2f t/h\n', results(i).F_mill);
        fprintf('  Overflow     : %.2f t/h\n', results(i).F_overflow);
        fprintf('  Underflow    : %.2f t/h\n', results(i).F_underflow);
        fprintf('  CL           : %.4f (-)\n', results(i).CL);
    end

    if ~exist('results', 'dir')
        mkdir('results');
    end
    save('results/all_scenarios_results.mat', 'results');

    scenario_names = strings(n,1);
    P50_overflow_um = zeros(n,1);
    P80_overflow_um = zeros(n,1);
    P50_mill_um     = zeros(n,1);
    P80_mill_um     = zeros(n,1);
    F_fresh_tph     = zeros(n,1);
    F_mill_tph      = zeros(n,1);
    F_overflow_tph  = zeros(n,1);
    F_underflow_tph = zeros(n,1);
    CL_ratio        = zeros(n,1);

    for i = 1:n
        scenario_names(i) = string(results(i).scenario_id);
        P50_overflow_um(i) = results(i).P50_overflow;
        P80_overflow_um(i) = results(i).P80_overflow;
        P50_mill_um(i)     = results(i).P50_mill;
        P80_mill_um(i)     = results(i).P80_mill;
        F_fresh_tph(i)     = results(i).F_fresh;
        F_mill_tph(i)      = results(i).F_mill;
        F_overflow_tph(i)  = results(i).F_overflow;
        F_underflow_tph(i) = results(i).F_underflow;
        CL_ratio(i)        = results(i).CL;
    end

    results_table = table( ...
        scenario_names, ...
        P50_overflow_um, ...
        P80_overflow_um, ...
        P50_mill_um, ...
        P80_mill_um, ...
        F_fresh_tph, ...
        F_mill_tph, ...
        F_overflow_tph, ...
        F_underflow_tph, ...
        CL_ratio, ...
        'VariableNames', { ...
            'Scenario', ...
            'P50_overflow_um', ...
            'P80_overflow_um', ...
            'P50_mill_um', ...
            'P80_mill_um', ...
            'F_fresh_tph', ...
            'F_mill_tph', ...
            'F_overflow_tph', ...
            'F_underflow_tph', ...
            'CL_ratio' ...
        } ...
    );

    fprintf('\n===== SCENARIO COMPARISON TABLE =====\n');
    disp(results_table);

    writetable(results_table, 'results/all_scenarios_results.csv');

    disp('All scenarios completed and saved.');
end