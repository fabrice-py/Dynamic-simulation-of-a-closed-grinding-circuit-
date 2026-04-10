function run_simulation(scenario_name)
    addpath(genpath(pwd)); 

    if nargin < 1
        scenario_name = 'scenario1'; 
    end
    Initialisation_simulink(scenario_name);
    try
        simOut = sim('closed_circuit_simulink');
        disp(['Simulation terminée avec succès : ', scenario_name]);
    catch ME
        fprintf('Erreur lors de la simulation : %s\n', ME.message);
    end
end