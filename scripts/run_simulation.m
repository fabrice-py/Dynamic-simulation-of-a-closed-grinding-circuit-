function run_simulation(scenario_name)

% Charger config
init_simulation(scenario_name);

% Lancer Simulink
simOut = sim('closed_circuit_simulink');

disp(['Simulation completed: ', scenario_name]);

end