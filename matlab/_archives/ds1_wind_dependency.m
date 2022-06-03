%% INITIALISATION
clc;
clear;
close all;

% add paths
work_dir = pwd;
idx = strfind(work_dir, '\');
addpath(work_dir(1:idx(end-1))+"\_data\2022.03.25_logs");
addpath(work_dir(1:idx(end-1))+"\matlab\saves");

% flags
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
    load('wind.mat');
    yvalue(1) = regression.a;
    xvalue(1) = 0;
    save('wind.mat', 'yvalue', 'xvalue', '-double');
    
    thrust_values_wind40
    load('wind.mat');
    yvalue(2) = regression.a;
    xvalue(2) = 40;
    save('wind.mat', 'yvalue', 'xvalue', '-double');
    
    thrust_values_wind80
    load('wind.mat');
    yvalue(3) = regression.a;
    xvalue(3) = 80;
    save('wind.mat', 'yvalue', 'xvalue', '-double');
    
    thrust_values_wind95
    load('wind.mat');
    yvalue(4) = regression.a;
    xvalue(4) = 95;
    save('wind.mat', 'yvalue', 'xvalue', '-double');
    
    close all;
    clearvars -except yvalue xvalue;
else
    load('wind.mat');
end

figure;
hold on;
plot(xvalue, yvalue*10^3, '-*');

ft_type = fittype({'x','1'});
regression = fit(xvalue.' , yvalue.'*10^3 , ft_type);
plot(regression);

xlabel('windspeed [%]');
ylabel('thrust coeff [?]');