function Initialisation_simulink(scenario_id)

cfg = config();

if ~isfield(cfg, scenario_id)
    error('Scenario "%s" does not exist', scenario_id);
end

sc = cfg.(scenario_id);

% Variables globales
size_classes = cfg.global.size_classes;
tau = cfg.global.tau;
dt = cfg.global.dt;

% Variables scénario
F_fresh = sc.F_fresh;
PSD_fresh = sc.PSD_fresh;
d50 = sc.d50;

% Normalisation
PSD_fresh = PSD_fresh(:).';
PSD_fresh = PSD_fresh / sum(PSD_fresh);

% Injection dans Simulink
assignin('base','size_classes',size_classes);
assignin('base','tau',tau);
assignin('base','dt',dt);

assignin('base','F_fresh',F_fresh);
assignin('base','PSD_fresh',PSD_fresh);
assignin('base','d50',d50);

end