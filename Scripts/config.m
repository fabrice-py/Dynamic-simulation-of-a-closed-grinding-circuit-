function cfg = config()
    % --- 1. GLOBAL PARAMETERS (Safety defaults) ---
    cfg.model_name = 'Dynamic_closed_circuit'; 
    cfg.global.size_classes = [75 150 300 600 1200 2400]; % microns
    cfg.global.tau = 0.25;                               % Residence time
    cfg.global.sim_stop_time = 50;                       % Simulation time
    cfg.global.Q_m3h = 150;
    
    % Default Hydrocyclone Geometry
    cfg.global.Di = 50;
    cfg.global.Dv = 60;
    cfg.global.Da = 35;
    cfg.global.alpha = 2.5;
    cfg.global.bypass = 0.2;
    
    % Default Feed
    cfg.global.F_fresh = 100;
    cfg.global.PSD_fresh = [0 0 0 0.2 0.3 0.5];
    cfg.global.d50 = 300;
    cfg.global.Kb = 1.0;

    % --- 2. SCENARIO 1: Standard Ore (Baseline) ---
    % Since it uses all defaults, we can just initialize it as an empty struct
    % The Initialisation script will pull everything from cfg.global
    cfg.scenario1.id = 'Standard Case';

    % --- 3. SCENARIO 2: Hard Ore + Narrow Vortex ---
    cfg.scenario2.Kb = 0.6;  % Harder ore
    cfg.scenario2.Dv = 40;  % Narrower Vortex finder

    % --- 4. SCENARIO 3: Soft Ore + High Bypass ---
    cfg.scenario3.Kb = 1.4;  % Softer ore
    cfg.scenario3.bypass = 0.35; % Increased bypass (less efficient)
end