%% INITIALISATION
clc;
clear;
close all;

addpath('functions');
save_figs = false;
run_comp = false;

% set figures parameters
set(groot, "DefaultAxesFontSize", 14);
set(groot, "DefaultLineLineWidth", 1.5);

if run_comp == true
    % create
    yvalue = zeros(1, 4);
    xvalue = yvalue;

    thrust_values_wind00
    load('saves\wind.mat');
    yvalue(1) = regression.a;
    xvalue(1) = 0;
    save('saves\wind.mat', 'yvalue', 'xvalue', '-double');
    
    thrust_values_wind40
    load('saves\wind.mat');
    yvalue(2) = regression.a;
    xvalue(2) = 40;
    save('saves\wind.mat', 'yvalue', 'xvalue', '-double');
    
    thrust_values_wind80
    load('saves\wind.mat');
    yvalue(3) = regression.a;
    xvalue(3) = 80;
    save('saves\wind.mat', 'yvalue', 'xvalue', '-double');
    
    thrust_values_wind95
    load('saves\wind.mat');
    yvalue(4) = regression.a;
    xvalue(4) = 95;
    save('saves\wind.mat', 'yvalue', 'xvalue', '-double');
    
    close all;
    clearvars -except yvalue xvalue;
else
    load('saves\wind.mat');
end

figure;
hold on;
plot(xvalue, yvalue*10^3, '-*');

ft_type = fittype({'x','1'});
regression = fit(xvalue.' , yvalue.'*10^3 , ft_type);
plot(regression);

xlabel('windspeed [%]');
ylabel('thrust coeff [?]');