%% INITIALISATION
clc;
clear;
close all;

% add paths
work_dir = pwd;
idx = strfind(work_dir, '\');
addpath(work_dir(1:end)+"\functions");
addpath(work_dir(1:end)+"\2022.05.23_logs");
addpath(work_dir(1:end)+"\2022.05.24_logs");

% set figures parameters
set(groot, "DefaultAxesFontSize", 10);
set(groot, "DefaultLineLineWidth", 1.5);

%% CONSTANTS
KV = 840; % [rpm/V]
NB_POLES = 17; % number pf electrical poles in motor

%% READ DATA
SELECT = 6; % select set of data to work with

% format : arduino data file name; pixhawk data file name; data range to use; sampling time
% meta{1} = {"output_2022-05-23_18-24-44_prbs3.log", "log_57_2022-5-21-04-33-40_battery_status_0.csv", [1 0], 0.01};
% meta{2} = {"output_2022-05-23_18-28-42_10to60.log", "log_58_2022-5-21-04-38-46_battery_status_0.csv", [1 0], 0.01};
% meta{3} = {"output_2022-05-23_18-38-59_prbs4.log", "log_59_2022-5-21-10-08-12_battery_status_0.csv", [500 500], 0.1};
% meta{4} = {"output_2022-05-23_18-44-35_steps.log", "log_60_2022-5-21-13-56-08_battery_status_0.csv", [1 0], 0.01};
% meta{5} = {"output_2022-05-24_12-17-33.log", "17_07_27_battery_status_0.csv", [1 0], 0.01};
meta{6} = {"output_2022-05-24_13-11-22_full.log", "17_07_27_battery_status_0.csv", [1 0], 0.01};

% read pixhawk log
temp=readmatrix(meta{SELECT}{2});
v=temp(:,3); % [V] battery voltage
tv=(temp(:,1)-temp(1,1))/1e6;

% read arduino log 
temp = readmatrix(meta{SELECT}{1});
TE=meta{SELECT}{4};
u=(temp(:,2)-1e3)/1e3*16; % [%] throttle
y=temp(:,3)*NB_POLES/2*(2*pi/60); % [rad/s] propeller speed
tu=(0:length(u)-1)*TE;
MU = mean(u);
MY = mean(y);

% remove outliers in measured rpm
if sum(y>1600 | y<35) > 0
    idx = y>1600 | y<35;
    y(idx)=0;
end

%% SYNC DATA
idx = find(tu>1.2);
u=u(1+idx(1):end);
y=y(1+idx(1):end);
tu=tu(1+idx(1):end)-tu(1+idx(1));

idx = find(tv>tu(end));
v=v(1:idx(1));
tv=tv(1:idx(1));
v=interp1(tv, v, tu);

% plot synced data
figure;  plot(tu, y/9.5e1); hold on; plot(tu, v*10-150); plot(tu, u); xlabel("time"); ylabel("Amplitude"); legend("measured rpm", "voltage", "throttle");
%% systemIdentification 

% quick gain estimation
gamma = rmoutliers(y(tu>550)./u(tu>550));
MG = mean(gain(~isnan(gamma)));
figure;
grid on;
plot(gain);
yline(MG, '--'); % 'HandleVisibility', 'off');
yline(840*2*pi/60, 'r');
ylim([0 110]);
legend("y/u", "mean = "+num2str(MG), "KV = 87.9 [rad/sV]", "Location", "best");

% select data range

% split data
zd=iddata(y(:), [u(:), y(:).^2], TE);
CUT=round(2/3*length(u));
zd = detrend(zd,0);               
zdi=zd([1:CUT]);
zdv=zd([CUT+1:end]);

% identify first order model
Opt = procestOptions;           
model_P1D = procest(zdi,'P1D', Opt);
present(model_P1D);

% identify second order model
model_P2DU = procest(zdi,'P2DU', Opt);
present(model_P2DU);

% parameter extraction
Ra = 0.1;
Ke = 60/(840*2*pi)/2;
Jm = 5e-5;
Jp = 60.077e-6; %kg*mm3 based on cad estimation
Jt = Jm + Jp;
Td = model_P1D.Td;

% parametric model
s=tf('s');
Gc=1/Ke/(Ra*Jm*s/Ke^2+1)*exp(-Td*s);

%% VALIDATION
figure;
compare(zdv, model_P1D, model_P2DU, Gc);

SELECT = 4;
% read arduino log and 
temp = readmatrix(meta{SELECT}{1});
u2=(temp(:,2)-1e3)/1e3*16;
y2=temp(:,3)*NB_POLES/2*(2*pi/60);
TE=meta{SELECT}{4};
tu2=(0:length(u2)-1)*TE;

% run simulation
yhat_P1D = lsim(model_P1D, u2(:), tu2(:));
yhat_P2DU = lsim(model_P2DU, u2(:), tu2(:));
yhat_Gc=lsim(Gc, u2(:), tu2(:));

figure;
hold on;
plot(tu2, y2);
plot(tu2, yhat_P1D);
plot(tu2, yhat_P2DU);
plot(tu2, yhat_Gc);
plot(tu2, u2*200);
legend("y", "P1D", "P2DU", "Gc", "K*u");
