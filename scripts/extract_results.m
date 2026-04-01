function result = extract_results(scenario_id)

size_classes = evalin('base', 'size_classes');

overflow = evalin('base', 'overflow_out');
underflow = evalin('base', 'underflow_out');
mill_out = evalin('base', 'mill_out');

% Si les signaux sont stockés en tableau temporel,
% on prend la dernière ligne
if size(overflow,1) > 1
    overflow_final = overflow(end,:);
else
    overflow_final = overflow;
end

if size(underflow,1) > 1
    underflow_final = underflow(end,:);
else
    underflow_final = underflow;
end

if size(mill_out,1) > 1
    mill_out_final = mill_out(end,:);
else
    mill_out_final = mill_out;
end

F_overflow = sum(overflow_final);
F_underflow = sum(underflow_final);
F_mill = sum(mill_out_final);
F_fresh = evalin('base', 'F_fresh');

PSD_overflow = overflow_final / max(sum(overflow_final), eps);
PSD_mill = mill_out_final / max(sum(mill_out_final), eps);

cum_overflow = cumsum(PSD_overflow);
cum_mill = cumsum(PSD_mill);

P50_overflow = interp_metric(size_classes, cum_overflow, 0.50);
P80_overflow = interp_metric(size_classes, cum_overflow, 0.80);

P50_mill = interp_metric(size_classes, cum_mill, 0.50);
P80_mill = interp_metric(size_classes, cum_mill, 0.80);

result.scenario_id = scenario_id;
result.F_fresh = F_fresh;
result.F_mill = F_mill;
result.F_overflow = F_overflow;
result.F_underflow = F_underflow;
result.CL = F_underflow / max(F_fresh, eps);

result.P50_mill = P50_mill;
result.P80_mill = P80_mill;
result.P50_overflow = P50_overflow;
result.P80_overflow = P80_overflow;

result.PSD_mill = PSD_mill;
result.PSD_overflow = PSD_overflow;
result.size_classes = size_classes;

end

function D = interp_metric(size_classes, cumulative_curve, target)
if max(cumulative_curve) < target || min(cumulative_curve) > target
    D = NaN;
else
    D = interp1(cumulative_curve, size_classes, target, 'linear');
end
end