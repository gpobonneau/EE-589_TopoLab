%% INITIALISATION
clc;
clear;
close all;

% add paths
work_dir = pwd;
idx = strfind(work_dir, '\');
addpath(work_dir(1:end)+"\functions");
addpath(work_dir(1:end)+"\2022.04.28_logs");

% add flags
save_figs = false;

% set figures parameters
set(groot, "DefaultAxesFontSize", 14);
set(groot, "DefaultLineLineWidth", 1.5);
% reset(gcf);

%%
syms alpha beta gamma s z zi TE;

z = 1/zi;
s = TE/2*(z-1)/(z+1); % tustin
[num, den] = numden(gamma/(alpha*s^2+beta*s+1));
num = collect(num, zi);
den = collect(den, zi);
Gd = num/den;
disp(Gd);
