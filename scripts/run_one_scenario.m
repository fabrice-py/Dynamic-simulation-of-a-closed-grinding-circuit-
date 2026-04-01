function result = run_one_scenario(scenario_id)

cfg = config();
model_name = cfg.model_name;

init_simulation(scenario_id);

load_system(model_name);
set_param(model_name, 'StopTime', num2str(evalin('base','sim_stop_time')));

sim(model_name);

result = extract_results(scenario_id);

end