function plot_scenario_comparison(results)

n = numel(results);

scenario_names = strings(1,n);
CL = zeros(1,n);
P50_over = zeros(1,n);
P80_over = zeros(1,n);
F_over = zeros(1,n);

for i = 1:n
    scenario_names(i) = string(results(i).scenario_id);
    CL(i) = results(i).CL;
    P50_over(i) = results(i).P50_overflow;
    P80_over(i) = results(i).P80_overflow;
    F_over(i) = results(i).F_overflow;
end

figure('Color','w');
bar(CL);
set(gca, 'XTickLabel', scenario_names);
ylabel('Circulating Load');
title('Comparison of Circulating Load by Scenario');
grid on;

figure('Color','w');
bar([P50_over(:), P80_over(:)]);
set(gca, 'XTickLabel', scenario_names);
legend('P50 Overflow','P80 Overflow','Location','best');
ylabel('Particle size (\mum)');
title('Overflow Size Metrics by Scenario');
grid on;

figure('Color','w');
bar(F_over);
set(gca, 'XTickLabel', scenario_names);
ylabel('Overflow flowrate (t/h)');
title('Overflow Flowrate by Scenario');
grid on;

% Courbes cumulées overflow
figure('Color','w');
hold on;
for i = 1:n
    cum_over = cumsum(results(i).PSD_overflow);
    plot(results(i).size_classes, cum_over, '-o', 'LineWidth', 1.6, ...
        'DisplayName', char(scenario_names(i)));
end
set(gca, 'XScale', 'log');
xlabel('Particle size (\mum)');
ylabel('Cumulative passing');
title('Overflow Cumulative PSD - Scenario Comparison');
legend('Location','best');
grid on;
hold off;

end