clear;
clc;
close all;

%% =========================================================
% Closed Grinding Circuit: Mill + Hydrocyclone
% Steady-state iterative simulation
% ==========================================================

%% 1) INPUT DATA

data.size_classes_um = [75 150 300 600 1200 2400];

% Fresh feed PSD (%)
data.PSD_fresh_percent = [10 15 20 25 20 10];

% Fresh feed solids flowrate (t/h)
data.F_fresh_tph = 100;

% ----- Mill model parameters -----
% Fraction selected for breakage in each size class
data.selection = [0.00 0.05 0.10 0.20 0.35 0.50];

% ----- Cyclone parameters -----
data.d50_um = 200;
data.k_sharpness = 1.5;

% ----- Iteration parameters -----
data.max_iter = 200;
data.tol = 1e-8;

%% 2) PREPARE INPUTS

size_classes = data.size_classes_um(:)';
PSD_fresh = data.PSD_fresh_percent(:)' / sum(data.PSD_fresh_percent);
F_fresh = data.F_fresh_tph;
selection = data.selection(:)';
d50 = data.d50_um;
k = data.k_sharpness;

n = numel(size_classes);

if numel(PSD_fresh) ~= n || numel(selection) ~= n
    error('Input vectors must have the same length.');
end

if any(selection < 0) || any(selection > 1)
    error('Selection values must be between 0 and 1.');
end

%% 3) BUILD BREAKAGE MATRIX FOR MILL

B = zeros(n,n);

% Finest class
B(1,1) = 1.0;

% Class 2 -> class 1
B(1,2) = 1.0;

% Class 3 -> classes 1,2
B(1,3) = 0.30;
B(2,3) = 0.70;

% Class 4 -> classes 1,2,3
B(1,4) = 0.10;
B(2,4) = 0.30;
B(3,4) = 0.60;

% Class 5 -> classes 2,3,4
B(2,5) = 0.20;
B(3,5) = 0.30;
B(4,5) = 0.50;

% Class 6 -> classes 3,4,5
B(3,6) = 0.20;
B(4,6) = 0.30;
B(5,6) = 0.50;

for j = 1:n
    col_sum = sum(B(:,j));
    if col_sum > 0 && abs(col_sum - 1) > 1e-12
        error('Column %d of breakage matrix does not sum to 1.', j);
    end
end

%% 4) INITIALIZE RECYCLE STREAM

F_recycle = 0;
PSD_recycle = zeros(1,n);

history.err = [];
history.F_recycle = [];
history.F_product = [];

%% 5) ITERATE UNTIL CONVERGENCE

for iter = 1:data.max_iter

    % ----- Mill feed = fresh feed + recycle -----
    F_mill_feed = F_fresh + F_recycle;

    if F_mill_feed <= 0
        error('Mill feed flowrate became non-positive.');
    end

    solids_fresh = F_fresh * PSD_fresh;
    solids_recycle = F_recycle * PSD_recycle;

    solids_mill_feed = solids_fresh + solids_recycle;
    PSD_mill_feed = solids_mill_feed / sum(solids_mill_feed);

    % ----- Mill model -----
    PSD_mill_out = run_simple_mill(PSD_mill_feed, selection, B);

    % Assume total solids flow conserved through mill
    F_mill_out = F_mill_feed;

    solids_mill_out = F_mill_out * PSD_mill_out;

    % ----- Cyclone model -----
    [F_overflow, PSD_overflow, F_underflow, PSD_underflow, P_overflow] = ...
        run_simple_cyclone(F_mill_out, PSD_mill_out, size_classes, d50, k);

    % ----- Convergence test on recycle solids vector -----
    new_recycle_solids = F_underflow * PSD_underflow;
    old_recycle_solids = F_recycle * PSD_recycle;

    err = norm(new_recycle_solids - old_recycle_solids, 2);

    history.err(end+1) = err; %#ok<SAGROW>
    history.F_recycle(end+1) = F_underflow; %#ok<SAGROW>
    history.F_product(end+1) = F_overflow; %#ok<SAGROW>

    % Update recycle
    F_recycle = F_underflow;
    PSD_recycle = PSD_underflow;

    if err < data.tol
        fprintf('Converged in %d iterations.\n', iter);
        break;
    end
end

if iter == data.max_iter && err >= data.tol
    warning('Maximum number of iterations reached before convergence.');
end

%% 6) FINAL STREAMS

% Fresh feed metrics
PSD_cum_fresh = cumsum(PSD_fresh);
F50_um = interpolate_size_metric(size_classes, PSD_cum_fresh, 0.50);
F80_um = interpolate_size_metric(size_classes, PSD_cum_fresh, 0.80);

% Mill feed metrics
PSD_cum_mill_feed = cumsum(PSD_mill_feed);
MF50_um = interpolate_size_metric(size_classes, PSD_cum_mill_feed, 0.50);
MF80_um = interpolate_size_metric(size_classes, PSD_cum_mill_feed, 0.80);

% Mill product metrics
PSD_cum_mill_out = cumsum(PSD_mill_out);
MP50_um = interpolate_size_metric(size_classes, PSD_cum_mill_out, 0.50);
MP80_um = interpolate_size_metric(size_classes, PSD_cum_mill_out, 0.80);

% Final product = cyclone overflow
PSD_cum_product = cumsum(PSD_overflow);
P50_um = interpolate_size_metric(size_classes, PSD_cum_product, 0.50);
P80_um = interpolate_size_metric(size_classes, PSD_cum_product, 0.80);

% Recycle = cyclone underflow
PSD_cum_recycle = cumsum(PSD_recycle);
R50_um = interpolate_size_metric(size_classes, PSD_cum_recycle, 0.50);
R80_um = interpolate_size_metric(size_classes, PSD_cum_recycle, 0.80);

%% 7) PERFORMANCE INDICATORS

circulating_load = F_recycle / F_fresh;
product_yield = F_overflow / F_fresh;
overall_mass_balance = F_overflow + F_recycle - F_mill_out;

RR80_overall = F80_um / P80_um;
RR50_overall = F50_um / P50_um;

%% 8) STORE RESULTS

results.inputs = data;

results.streams.fresh.flow_tph = F_fresh;
results.streams.fresh.PSD = PSD_fresh;
results.streams.fresh.F50_um = F50_um;
results.streams.fresh.F80_um = F80_um;

results.streams.mill_feed.flow_tph = F_mill_feed;
results.streams.mill_feed.PSD = PSD_mill_feed;
results.streams.mill_feed.F50_um = MF50_um;
results.streams.mill_feed.F80_um = MF80_um;

results.streams.mill_out.flow_tph = F_mill_out;
results.streams.mill_out.PSD = PSD_mill_out;
results.streams.mill_out.P50_um = MP50_um;
results.streams.mill_out.P80_um = MP80_um;

results.streams.overflow.flow_tph = F_overflow;
results.streams.overflow.PSD = PSD_overflow;
results.streams.overflow.P50_um = P50_um;
results.streams.overflow.P80_um = P80_um;

results.streams.underflow.flow_tph = F_recycle;
results.streams.underflow.PSD = PSD_recycle;
results.streams.underflow.U50_um = R50_um;
results.streams.underflow.U80_um = R80_um;

results.partition.P_overflow = P_overflow;
results.performance.circulating_load = circulating_load;
results.performance.product_yield = product_yield;
results.performance.overall_mass_balance = overall_mass_balance;
results.performance.RR50_overall = RR50_overall;
results.performance.RR80_overall = RR80_overall;
results.performance.iterations = iter;
results.performance.final_error = err;

results.history = history;

%% 9) DISPLAY RESULTS

fprintf('\n================ TD4 RESULTS ================\n');
fprintf('Fresh feed flow               : %.2f t/h\n', F_fresh);
fprintf('Mill feed flow                : %.2f t/h\n', F_mill_feed);
fprintf('Mill out flow                 : %.2f t/h\n', F_mill_out);
fprintf('Final product flow (OF)       : %.2f t/h\n', F_overflow);
fprintf('Recycle flow (UF)             : %.2f t/h\n', F_recycle);
fprintf('Circulating load              : %.4f\n', circulating_load);
fprintf('Product yield                 : %.4f\n', product_yield);
fprintf('Mass balance check            : %.6e\n', overall_mass_balance);
fprintf('\n');
fprintf('Fresh Feed F50                : %.2f um\n', F50_um);
fprintf('Fresh Feed F80                : %.2f um\n', F80_um);
fprintf('Mill Feed F50                 : %.2f um\n', MF50_um);
fprintf('Mill Feed F80                 : %.2f um\n', MF80_um);
fprintf('Mill Product P50              : %.2f um\n', MP50_um);
fprintf('Mill Product P80              : %.2f um\n', MP80_um);
fprintf('Final Product P50             : %.2f um\n', P50_um);
fprintf('Final Product P80             : %.2f um\n', P80_um);
fprintf('Recycle U50                   : %.2f um\n', R50_um);
fprintf('Recycle U80                   : %.2f um\n', R80_um);
fprintf('\n');
fprintf('Overall RR50                  : %.4f\n', RR50_overall);
fprintf('Overall RR80                  : %.4f\n', RR80_overall);
fprintf('Iterations                    : %d\n', iter);
fprintf('Final convergence error       : %.6e\n', err);
fprintf('============================================\n\n');

%% 10) PLOTS

% --- PSD comparison ---
figure('Name','Closed Circuit - PSD Comparison');
bar(size_classes, [PSD_fresh; PSD_mill_feed; PSD_mill_out; PSD_overflow; PSD_recycle]');
set(gca,'XScale','log');
xlabel('Particle size (\mum)');
ylabel('Mass fraction');
title('PSD of Main Streams in Closed Circuit');
legend('Fresh Feed','Mill Feed','Mill Out','Final Product (OF)','Recycle (UF)', ...
       'Location','best');
grid on;

% --- cumulative curves ---
figure('Name','Closed Circuit - Cumulative PSD');
plot(size_classes, cumsum(PSD_fresh), 'ko-', 'LineWidth', 1.5); hold on;
plot(size_classes, cumsum(PSD_mill_feed), 'bd-', 'LineWidth', 1.5);
plot(size_classes, cumsum(PSD_mill_out), 'm^-', 'LineWidth', 1.5);
plot(size_classes, cumsum(PSD_overflow), 'gs-', 'LineWidth', 1.5);
plot(size_classes, cumsum(PSD_recycle), 'rv-', 'LineWidth', 1.5);
set(gca,'XScale','log');
xlabel('Particle size (\mum)');
ylabel('Cumulative passing');
title('Cumulative PSD of Main Streams');
legend('Fresh Feed','Mill Feed','Mill Out','Final Product (OF)','Recycle (UF)', ...
       'Location','best');
grid on;
yline(0.50, '--', '50%');
yline(0.80, '--', '80%');
hold off;

% --- partition curve ---
figure('Name','Hydrocyclone Partition');
plot(size_classes, P_overflow, 'o-', 'LineWidth', 1.5);
set(gca,'XScale','log');
xlabel('Particle size (\mum)');
ylabel('Probability to Overflow');
title('Cyclone Partition Curve');
grid on;
xline(d50, '--r', sprintf('d50 = %.0f \\mum', d50), 'LineWidth', 1.2);

% --- convergence ---
figure('Name','Closed Circuit Convergence');
semilogy(history.err, 'LineWidth', 1.5);
xlabel('Iteration');
ylabel('Error norm');
title('Convergence of Recycle Stream');
grid on;

%% 11) OPTIONAL SAVE

% save('TD4_closed_circuit_results.mat', 'results');

%% =========================================================
% LOCAL FUNCTIONS
% ==========================================================

function PSD_out = run_simple_mill(PSD_in, selection, B)

    n = numel(PSD_in);
    PSD_out = zeros(1,n);

    for j = 1:n
        feed_j = PSD_in(j);
        s_j = selection(j);

        unbroken = (1 - s_j) * feed_j;
        broken = s_j * feed_j;

        PSD_out(j) = PSD_out(j) + unbroken;
        PSD_out = PSD_out + broken * B(:,j)';
    end

    PSD_out = PSD_out / sum(PSD_out);
end

function [F_overflow, PSD_overflow, F_underflow, PSD_underflow, P_overflow] = ...
    run_simple_cyclone(F_feed, PSD_feed, size_classes, d50, k)

    P_overflow = 1 ./ (1 + (size_classes ./ d50).^k);
    P_underflow = 1 - P_overflow;

    OF_partial = PSD_feed .* P_overflow;
    UF_partial = PSD_feed .* P_underflow;

    OF_yield = sum(OF_partial);
    UF_yield = sum(UF_partial);

    PSD_overflow = OF_partial / OF_yield;
    PSD_underflow = UF_partial / UF_yield;

    F_overflow = F_feed * OF_yield;
    F_underflow = F_feed * UF_yield;
end

function D_value = interpolate_size_metric(size_classes, cumulative_passing, target)

    if numel(size_classes) ~= numel(cumulative_passing)
        error('size_classes and cumulative_passing must have same length.');
    end

    if target < min(cumulative_passing) || target > max(cumulative_passing)
        error('Target %.2f lies outside cumulative passing range.', target);
    end

    D_value = interp1(cumulative_passing, size_classes, target, 'linear');
end