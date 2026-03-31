clear
clc
close all

%% ====================================
% Closed Circuit with Pulp & Energy
% ====================================

%% Particle sizes

size_classes = [75 150 300 600 1200 2400];
n = length(size_classes);

%% Fresh ore PSD

PSD_fresh = [10 15 20 25 20 10];
PSD_fresh = PSD_fresh/sum(PSD_fresh);

%% Flows

F_fresh = 100;      % t/h solids
W_fresh = 40;       % t/h water

%% Physical constants

rho_s = 2700;
rho_w = 1000;

%% Mill parameters

selection = [0 0.05 0.10 0.20 0.35 0.50];

%% Cyclone parameters

d50 = 300;
k = 2.5;

water_overflow_split = 0.8;

%% Bond parameters

Wi = 14;

%% Breakage matrix

B = zeros(n,n);

B(1,1)=1;
B(1,2)=1;
B(1,3)=0.3; B(2,3)=0.7;
B(1,4)=0.1; B(2,4)=0.3; B(3,4)=0.6;
B(2,5)=0.2; B(3,5)=0.3; B(4,5)=0.5;
B(3,6)=0.2; B(4,6)=0.3; B(5,6)=0.5;

%% Initial recycle

F_recycle = 0;
PSD_recycle = zeros(1,n);
W_recycle = 0;

%% Iteration

for iter = 1:200

    %% Mill feed
    
    F_mill = F_fresh + F_recycle;
    W_mill = W_fresh + W_recycle;
    
    solids_fresh = F_fresh*PSD_fresh;
    solids_recycle = F_recycle*PSD_recycle;
    
    solids_mill = solids_fresh + solids_recycle;
    PSD_mill = solids_mill/sum(solids_mill);
    
    %% Mill model
    
    PSD_mill_out = run_mill(PSD_mill,selection,B);
    
    %% Cyclone
    
    P_of = 1./(1+(size_classes/d50).^k);
    
    OF_partial = PSD_mill_out.*P_of;
    UF_partial = PSD_mill_out.*(1-P_of);
    
    OF_yield = sum(OF_partial);
    UF_yield = sum(UF_partial);
    
    PSD_of = OF_partial/OF_yield;
    PSD_uf = UF_partial/UF_yield;
    
    F_of = F_mill*OF_yield;
    F_uf = F_mill*UF_yield;
    
    %% Water split
    
    W_of = W_mill*water_overflow_split;
    W_uf = W_mill*(1-water_overflow_split);
    
    %% Convergence
    
    err = abs(F_uf-F_recycle);
    
    F_recycle = F_uf;
    PSD_recycle = PSD_uf;
    W_recycle = W_uf;
    
    if err < 1e-6
        break
    end
    
end

%% Pulp properties

Cw = F_mill/(F_mill+W_mill);

rho_p = 1/((Cw/rho_s)+((1-Cw)/rho_w));

%% Size metrics

cum_feed = cumsum(PSD_fresh);
cum_prod = cumsum(PSD_of);

F80 = interp1(cum_feed,size_classes,0.8);
P80 = interp1(cum_prod,size_classes,0.8);

%% Bond energy

W = 10*Wi*(1/sqrt(P80)-1/sqrt(F80));

Power = W*F_mill;

%% Circulating load

CL = F_recycle/F_fresh;

%% Results

fprintf('\n---- TD4.5 RESULTS ----\n')

fprintf('Fresh feed = %.2f t/h\n',F_fresh)
fprintf('Mill feed = %.2f t/h\n',F_mill)
fprintf('Product = %.2f t/h\n',F_of)
fprintf('Recycle = %.2f t/h\n',F_recycle)

fprintf('\nCirculating load = %.2f\n',CL)

fprintf('\nF80 = %.1f µm\n',F80)
fprintf('P80 = %.1f µm\n',P80)

fprintf('\nSpecific energy = %.2f kWh/t\n',W)
fprintf('Mill Power = %.1f kW\n',Power)

fprintf('\nSolids fraction = %.2f\n',Cw)
fprintf('Pulp density = %.1f kg/m3\n',rho_p)

%% Plot PSD

figure

bar(size_classes,[PSD_fresh;PSD_of;PSD_recycle]')

set(gca,'XScale','log')

xlabel('Particle size µm')
ylabel('Mass fraction')

legend('Fresh Feed','Product','Recycle')

title('Closed Circuit PSD')
grid on

%% Mill function

function PSD_out = run_mill(PSD_in,selection,B)

n = length(PSD_in);
PSD_out = zeros(1,n);

for j=1:n
    
    f = PSD_in(j);
    s = selection(j);
    
    unbroken = (1-s)*f;
    broken = s*f;
    
    PSD_out(j)=PSD_out(j)+unbroken;
    PSD_out = PSD_out + broken*B(:,j)';
    
end

PSD_out = PSD_out/sum(PSD_out);

end