 function result = extract_results(scenario_id)
% EXTRACT_RESULTS - Retrieves data and calculates energy & reduction performance
    if nargin < 1 || isempty(scenario_id)
        scenario_id = 'manual_run';
    end

    % 1) Global parameters
    size_classes = evalin('base', 'size_classes');
    F_fresh      = evalin('base', 'F_fresh');
    PSD_fresh    = evalin('base', 'PSD_fresh'); 
    Kb           = evalin('base', 'Kb');        
    
    size_classes = double(size_classes(:)');
    num_classes  = numel(size_classes);

    % 2) Signals Retrieval
    overflow_final  = getLastPoint('overflow_out',  num_classes);
    underflow_final = getLastPoint('underflow_out', num_classes);
    mill_out_final  = getLastPoint('mill_out',      num_classes);

    % 3) Force numeric row vectors
    overflow_final  = double(reshape(overflow_final,  1, []));
    underflow_final = double(reshape(underflow_final, 1, []));
    mill_out_final  = double(reshape(mill_out_final,  1, []));

    % 4) Flowrates (t/h)
    F_overflow  = sum(overflow_final);
    F_underflow = sum(underflow_final);
    F_mill      = sum(mill_out_final);

    % 5) PSD Calculation
    PSD_overflow = overflow_final / max(F_overflow, eps);
    PSD_mill     = mill_out_final / max(F_mill, eps);

    % 6) Cumulative PSD (Passing)
    cum_overflow = cumsum(PSD_overflow);
    cum_mill     = cumsum(PSD_mill);
    cum_fresh    = cumsum(PSD_fresh);

    % 7) Size metrics (microns)
    % 80% passing (Standard metrics)
    result.P80_mill     = interp_metric(size_classes, cum_mill,     0.80);
    result.F80_fresh    = interp_metric(size_classes, cum_fresh,    0.80);
    result.P80_overflow = interp_metric(size_classes, cum_overflow, 0.80);

    % 50% passing (Median size metrics)
    result.P50_mill     = interp_metric(size_classes, cum_mill,     0.50);
    result.F50_fresh    = interp_metric(size_classes, cum_fresh,    0.50);
    result.P50_overflow = interp_metric(size_classes, cum_overflow, 0.50);

    % 8) Reduction Ratios
    % How much the size has been reduced (Feed size / Product size)
    result.RR80 = result.F80_fresh / max(result.P80_mill, eps);
    result.RR50 = result.F50_fresh / max(result.P50_mill, eps);

    % 9) ENERGY CALCULATION (Bond's Law)
    BWI_eff = 15 / max(Kb, eps); 
    
    if result.P80_mill > 0 && result.F80_fresh > result.P80_mill
        result.Specific_Energy = 10 * BWI_eff * (1/sqrt(result.P80_mill) - 1/sqrt(result.F80_fresh));
    else
        result.Specific_Energy = 0;
    end
    
    result.Mill_Power_kW = result.Specific_Energy * F_mill;

    % 10) Store outputs
    result.scenario_id  = scenario_id;
    result.Kb           = Kb;
    result.F_fresh      = F_fresh;
    result.F_mill       = F_mill;
    result.F_overflow   = F_overflow;
    result.F_underflow  = F_underflow;
    result.CL           = F_underflow / max(F_fresh, eps);
    result.PSD_mill     = PSD_mill;
    result.PSD_overflow = PSD_overflow;
    result.size_classes = size_classes;
end

% =========================================================
% HELPER FUNCTIONS
% =========================================================

function data = getLastPoint(varName, num_classes)
    val = evalin('base', varName);

    % Case 1: numeric array
    if isnumeric(val) || islogical(val)
        data = extractFromNumeric(val, num_classes);
        return;
    end

    % Case 2: timeseries
    if isa(val, 'timeseries')
        raw = val.Data;
        data = extractFromNumeric(raw, num_classes);
        return;
    end

    % Case 3: structure from To Workspace
    if isstruct(val)
        if isfield(val, 'signals') && isfield(val.signals, 'values')
            raw = val.signals.values;
            data = extractFromNumeric(raw, num_classes);
            return;
        elseif isfield(val, 'Data')
            raw = val.Data;
            data = extractFromNumeric(raw, num_classes);
            return;
        end
    end

    error('Variable "%s" has unsupported type: %s', varName, class(val));
end

function data = extractFromNumeric(raw, num_classes)
    raw = double(raw);

    dims = ndims(raw);

    if isvector(raw)
        raw = raw(:)';
        if numel(raw) < num_classes
            error('Signal has fewer elements than expected.');
        end
        data = raw(end-num_classes+1:end);
        return;
    end

    if dims == 2
        % Usually [time x classes] or [classes x time]
        [r, c] = size(raw);

        if c == num_classes
            data = raw(end, :);
        elseif r == num_classes
            data = raw(:, end)';
        else
            % fallback: flatten and take last block
            flat = raw(:)';
            data = flat(end-num_classes+1:end);
        end
        return;
    end

    if dims == 3
        % Example: 1 x 6 x N or N x 1 x 6, etc.
        sz = size(raw);

        if sz(2) == num_classes
            temp = raw(1, :, end);
            data = reshape(temp, 1, num_classes);
        elseif sz(1) == num_classes
            temp = raw(:, 1, end);
            data = reshape(temp, 1, num_classes);
        elseif sz(3) == num_classes
            temp = raw(end, 1, :);
            data = reshape(temp, 1, num_classes);
        else
            flat = raw(:)';
            data = flat(end-num_classes+1:end);
        end
        return;
    end

    error('Unsupported numeric signal shape.');
end

function D = interp_metric(size_classes, cumulative_curve, target)
    cumulative_curve = double(cumulative_curve(:)');
    size_classes     = double(size_classes(:)');
    
    % FIX: Remove duplicate values in cumulative curve for stable interpolation
    [cum_unique, idx] = unique(cumulative_curve, 'stable');
    size_unique = size_classes(idx);
    
    if max(cum_unique) < target || min(cum_unique) > target
        D = NaN;
    else
        % Use unique values here
        D = interp1(cum_unique, size_unique, target, 'linear');
    end
end
