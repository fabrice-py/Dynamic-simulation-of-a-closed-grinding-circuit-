function Initialisation_simulink(scenario_id)
% INITIALISATION_SIMULINK - Prépare les données pour le modèle Simulink
    
    % 1. Charger la configuration
    cfg = config(); 
    
    % 2. Gérer le scénario par défaut
    if nargin < 1 || isempty(scenario_id)
        scenario_id = 'scenario1'; 
    end
    
    % 3. Extraction du scénario (on vérifie l'existence du scénario)
    if isfield(cfg, scenario_id)
        current_scen = cfg.(scenario_id);
    else
        error('Le scenario "%s" n''existe pas dans config.m', scenario_id);
    end
    
    % 4. Injection sécurisée dans le Base Workspace
    % On vérifie si le champ existe dans le scénario, sinon on cherche dans global
    
    % --- Paramètres de Flux ---
    assignin('base', 'F_fresh',   get_val(current_scen, cfg, 'F_fresh'));
    assignin('base', 'PSD_fresh', get_val(current_scen, cfg, 'PSD_fresh'));
    
    % --- Paramètres Broyeur & Temps ---
    assignin('base', 'Kb',            get_val(current_scen, cfg, 'Kb'));
    assignin('base', 'tau',           cfg.global.tau);
    assignin('base', 'size_classes',  cfg.global.size_classes);
    assignin('base', 'sim_stop_time', cfg.global.sim_stop_time);
    
    % --- Géométrie Hydrocyclone ---
    assignin('base', 'd50',    get_val(current_scen, cfg, 'd50'));
    assignin('base', 'Di',     get_val(current_scen, cfg, 'Di'));
    assignin('base', 'Dv',     get_val(current_scen, cfg, 'Dv'));
    assignin('base', 'Da',     get_val(current_scen, cfg, 'Da'));
    assignin('base', 'alpha',  get_val(current_scen, cfg, 'alpha'));
    assignin('base', 'bypass', get_val(current_scen, cfg, 'bypass'));
    % Valeur de test pour le débit volumétrique (m3/h)
    assignin('base', 'Q_m3h', get_val(current_scen, cfg, 'bypass'));
    
    fprintf('### Initialisation [%s] terminee avec succes ###\n', scenario_id);
end

% --- Fonction Helper pour éviter les erreurs "Field not found" ---
function val = get_val(scen, full_cfg, fieldName)
    if isfield(scen, fieldName)
        val = scen.(fieldName);
    elseif isfield(full_cfg.global, fieldName)
        val = full_cfg.global.(fieldName);
    else
        error('Le parametre "%s" est introuvable dans le scenario et dans global.', fieldName);
    end
end