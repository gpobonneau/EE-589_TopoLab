%% INITIALISATION
clc;
clear;
close all;


% add paths
work_dir = pwd;
idx = strfind(work_dir, '\');
addpath(work_dir(1:idx(end-1))+"\_data\2022.04.28_logs");

% load parameters
load('params.mat');
NB_POLES = 17;
TE = 0.2;

%%
Ke = 0.01;
Ra = 0.01;
Jm = 2.8e-5;
Jl = 60.8e-6;
Jt = Jm+Jl;
Bf = 5e-4;

%% OPEN REAL DATA
temp = readmatrix("output_2022-04-29_17-35-20_w0_upto60.log");

% read data
temp = temp(50:end-50, :);
temp(:, 1)=(temp(:, 1)-temp(1, 1))/1e3;
temp(:, 2)=temp(:, 2)*10+1e3; % pwm
temp(:, 3)=temp(:, 3)*NB_POLES/2*(2*pi/60); % rad/s
LGTH = length(temp);

u=temp(:,2);
y=temp(:,3);
y(y>2000) = 0; % remove outliers
y(y==0) = 20;
t=linspace(0, temp(end, 1), LGTH);

j=linspace(0, 0.5, LGTH); % advance ratio
v=linspace(16.5, 15.7, LGTH); % battery
w=5*ones(LGTH, 1);

t=t(:);
w=[t, w(:)];
u=[t, u(:)];
v=[t, v(:)];
j=[t, j(:)];

%% LAUNCH SIMULATION
% paramNameValStruct.SimulationMode = 'rapid';
% paramNameValStruct.AbsTol = '1e-5'; 

simOut = sim('model');
% COMPARE
figure;
hold on;
plot(t(1:length(simOut.rpm.Data)), simOut.rpm.Data);
plot(t(1:length(simOut.rpm.Data)), y(1:length(simOut.rpm.Data)));
plot(t(1:length(simOut.rpm.Data)), u(1:length(simOut.rpm.Data), 2));
legend("Simulink", "Measured data", "command");


