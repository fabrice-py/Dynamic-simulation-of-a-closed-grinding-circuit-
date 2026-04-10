function result = run_one_scenario(scenario_id)
% RUN_ONE_SCENARIO - Initialization and launching of simulink
    
    % 1. Security: define a scenario if none is set
    if nargin < 1 || isempty(scenario_id)
        scenario_id = 'scenario1';
    end

    % 2. Load configuration
    cfg = config();
    
    % --- CRITICAL FIX ---
    % Check if model_name exists in cfg, otherwise use a default name
    if isfield(cfg, 'model_name')
        model_name = cfg.model_name;
    else
        % Fallback to your actual file name if missing in config.m
        model_name = 'Dynamic_closed_circuit'; 
        warning('model_name not found in config.m. Using default: %s', model_name);
    end
    % --------------------

    % 3. Initialization file (sends variables to Base Workspace)
    Initialisation_simulink(scenario_id);

    % 4. Simulink model setting
    load_system(model_name);
    set_param(model_name, 'StopTime', num2str(cfg.global.sim_stop_time));

    % 5. Launch simulink
    disp(['Launching simulation: ', scenario_id, ' (Model: ', model_name, ')...']);
    sim(model_name);

    % 6. Results extraction
    result = extract_results(scenario_id);
    
    disp(['Simulation and extraction completed for: ', scenario_id]);
end