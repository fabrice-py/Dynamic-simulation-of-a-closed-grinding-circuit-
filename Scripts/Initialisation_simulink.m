function Initialisation_simulink(scenario_id)
% INITIALISATION_SIMULINK - Prépare les données pour le modèle Simulink

    % 1. Charger la configuration
    cfg = config(); 

    % 2. Gérer le scénario par défaut
    if nargin < 1 || isempty(scenario_id)
        scenario_id = 'scenario1'; 
    end

    % 3. Extraction du scénario
    current_scen = cfg.(scenario_id);
    
    % 4. Injection dans le Base Workspace (Pour Simulink)
    assignin('base', 'F_fresh',   current_scen.F_fresh);
    assignin('base', 'PSD_fresh', current_scen.PSD_fresh);
    assignin('base', 'd50',       current_scen.d50);
    assignin('base', 'tau',       cfg.global.tau);
    assignin('base', 'size_classes',  cfg.global.size_classes);
    assignin('base', 'sim_stop_time', cfg.global.sim_stop_time);

    fprintf('### Initialisation [%s] terminée avec succès ###\n', scenario_id);
end