function result = run_one_scenario(scenario_id)
% RUN_ONE_SCENARIO - Initialisation and launching of simulink

    % 1. Security : define a sceanario if none it's set
    if nargin < 1 || isempty(scenario_id)
        scenario_id = 'scenario1';
    end

    % 2. Change configuration
    cfg = config();
    model_name = cfg.model_name;

    % 3. Initialisation file
    Initialisation_simulink(scenario_id);

    % 4.Simulink model setting
    load_system(model_name);
    set_param(model_name, 'StopTime', num2str(cfg.global.sim_stop_time));

    % 5. Launch simulink
    disp(['Lancement de la simulation : ', scenario_id, '...']);
    sim(model_name);

    % 6. Results extraction
    result = extract_results(scenario_id);
    
    disp(['Simulation et extraction terminées pour : ', scenario_id]);
end