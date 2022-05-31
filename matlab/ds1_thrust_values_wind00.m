%% INITIALISATION
clc;
clear;
close all;

% add paths
work_dir = pwd;
idx = strfind(work_dir, '\');
addpath(work_dir(1:end)+"\functions");
addpath(work_dir(1:end)+"\2022.04.28_logs");
save_figs = false;

% set figures parameters
set(groot, "DefaultAxesFontSize", 14);
set(groot, "DefaultLineLineWidth", 1.5);

%% PREPROCESSING DATA
% read files
ms010msp003_ati = readmatrix('nidaq\MS010MPT003_NIDAQ USB-6210_31683603.csv');
ms010msp003_ati(:, 4:end) = volt2load_ati(ms010msp003_ati); %convert from voltages to loads
ms010msp_calib{1} = [ms010msp003_ati(1:2000,4:6); ms010msp003_ati(8500:end-200,4:6)];
ms010msp_thurst{1} = [ms010msp003_ati(4300:5100,4:6); ms010msp003_ati(6700:7600,4:6)];

ms010msp004_ati = readmatrix('nidaq\MS010MPT004_NIDAQ USB-6210_31683603.csv');
ms010msp004_ati(:, 4:end) = volt2load_ati(ms010msp004_ati); %convert from voltages to loads
ms010msp_calib{2} = ms010msp004_ati(1:1600,4:6);
ms010msp_thurst{2} = [ms010msp004_ati(3800:4700,4:6); ms010msp004_ati(6200:7000,4:6)];

ms010msp005_ati = readmatrix('nidaq\MS010MPT005_NIDAQ USB-6210_31683603.csv');
ms010msp005_ati(:, 4:end) = volt2load_ati(ms010msp005_ati); %convert from voltages to loads
ms010msp_calib{3} = [ms010msp005_ati(1:1500,4:6); ms010msp005_ati(8000:end-500,4:6)];
ms010msp_thurst{3} = [ms010msp005_ati(3800:4800,4:6); ms010msp005_ati(6200:7200,4:6)];

ms010msp006_ati = readmatrix('nidaq\MS010MPT006_NIDAQ USB-6210_31683603.csv');
ms010msp006_ati(:, 4:end) = volt2load_ati(ms010msp006_ati); %convert from voltages to loads
ms010msp_calib{4} = [ms010msp006_ati(1:500,4:6); ms010msp006_ati(4400:4900,4:6)];
ms010msp_thurst{4} = [ms010msp006_ati(2700:3700,4:6); ms010msp006_ati(5100:6100,4:6)];

ms010msp007_ati = readmatrix('nidaq\MS010MPT007_NIDAQ USB-6210_31683603.csv');
ms010msp007_ati(:, 4:end) = volt2load_ati(ms010msp007_ati); %convert from voltages to loads
ms010msp_calib{5} = [ms010msp007_ati(50:1800,4:6); ms010msp007_ati(5700:6300,4:6)];
ms010msp_thurst{5} = [ms010msp007_ati(4300:5100,4:6); ms010msp007_ati(6500:7300,4:6)];

% compute
force_mean = zeros(1,5);
force_var = zeros(1,5);
force_mag = cell(1,5);

for i = 1:5
    force_mag{i} = rms(ms010msp_thurst{i}-mean(ms010msp_calib{i},1), 2);
    force_mean(i) = mean(force_mag{i});
    force_var(i) = var(force_mag{i});
    temp = smooth(force_mag{i});
    force_mag{i} = temp(5:end);
    clear temp;
end

% plot thrust
figure;
hold on;
plot([zeros(1500, 1); force_mag{1}; force_mag{2}; force_mag{3}; force_mag{4}; force_mag{5}]);
yline(force_mean);

xlabel('Time (samples @ 120Hz)');
ylabel('Thrust (N)');

% 
rpm = (5000*[0 20 30 40 50 60]./100).^2;
fig1 = figure("Name", "Thrust in regard to rmp, no wind", "NumberTitle", "off");
hold on;
errorbar(rpm, [0 force_mean], [0 force_var]);
xlim([0 1.1*max(rpm)]);

ft_type = fittype({'x'});
regression = fit(rpm.', [0 force_mean].' , ft_type);
plot(regression);

xlabel('\omega^2 (rpm)');
ylabel('Thrust (N)');