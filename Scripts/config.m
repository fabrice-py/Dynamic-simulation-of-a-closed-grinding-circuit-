function cfg = config()

cfg.model_name = 'closed_circuit_simulink';

cfg.global.size_classes = [75 150 300 600 1200 2400];
cfg.global.tau = 0.25;
cfg.global.dt = 0.01;
cfg.global.sim_stop_time = 5;

% ===== Scenario 1 =====
cfg.scenario1.name = 'Base case';
cfg.scenario1.F_fresh = 100;
cfg.scenario1.PSD_fresh = [0.10 0.15 0.20 0.25 0.20 0.10];
cfg.scenario1.d50 = 300;
cfg.scenario1.recycle_gain = 0.50;

% ===== Scenario 2 =====
cfg.scenario2.name = 'Higher feed rate';
cfg.scenario2.F_fresh = 120;
cfg.scenario2.PSD_fresh = [0.10 0.15 0.20 0.25 0.20 0.10];
cfg.scenario2.d50 = 300;
cfg.scenario2.recycle_gain = 0.50;

% ===== Scenario 3 =====
cfg.scenario3.name = 'Finer cyclone cut';
cfg.scenario3.F_fresh = 100;
cfg.scenario3.PSD_fresh = [0.10 0.15 0.20 0.25 0.20 0.10];
cfg.scenario3.d50 = 200;
cfg.scenario3.recycle_gain = 0.50;

% ===== Scenario 4 =====
cfg.scenario4.name = 'Coarser feed';
cfg.scenario4.F_fresh = 100;
cfg.scenario4.PSD_fresh = [0.05 0.10 0.20 0.30 0.25 0.10];
cfg.scenario4.d50 = 300;
cfg.scenario4.recycle_gain = 0.50;

end