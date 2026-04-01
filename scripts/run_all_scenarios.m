function results = run_all_scenarios()

cfg = config();

scenario_fields = fieldnames(cfg);
scenario_fields = scenario_fields(startsWith(scenario_fields, 'scenario'));

n = numel(scenario_fields);
results = struct([]);

for i = 1:n
    scenario_id = scenario_fields{i};
    fprintf('Running %s...\n', scenario_id);

    results(i) = run_one_scenario(scenario_id);
end

save('results/all_scenarios_results.mat', 'results');

disp('All scenarios completed and saved.');

end