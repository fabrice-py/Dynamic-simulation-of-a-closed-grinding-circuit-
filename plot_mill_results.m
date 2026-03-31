figure;
plot(mill_out_75, 'LineWidth', 1.5); hold on;
plot(mill_out_150, 'LineWidth', 1.5);
plot(mill_out_300, 'LineWidth', 1.5);
plot(mill_out_600, 'LineWidth', 1.5);
plot(mill_out_1200, 'LineWidth', 1.5);
plot(mill_out_2400, 'LineWidth', 1.5);

legend('75 µm','150 µm','300 µm','600 µm','1200 µm','2400 µm');

title('Sortie broyeur par classe granulométrique');
xlabel('Temps');
ylabel('Débit (t/h)');
grid on;