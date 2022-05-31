%% INITIALISATION
clc;
clear;
close all;

% add paths
work_dir = pwd;
% idx = strfind(work_dir, '\');
% addpath(work_dir(1:end)+"\functions");
% addpath(work_dir(1:end)+"\2022.05.15_logs");

% add flags
save_figs = false;

% set figures parameters
set(groot, "DefaultAxesFontSize", 10);
set(groot, "DefaultLineLineWidth", 1.5);

%% TRANSFERT FUNCTION
TE = 0.02;
% z = tf('z', TE);
% s = tf('s');

syms a b c;

Gc = tf(5, [5 5 1]);
Gd = c2d(Gc, TE, 'zoh');

present(Gd);

