%% INITIALISATION
clc;
clear;
close all;

addpath('functions');
save_figs = false;

% set figures parameters
set(groot, "DefaultAxesFontSize", 14);
set(groot, "DefaultLineLineWidth", 1.5);

%% PREPROCESSING DATA
% read files
ms010msp008_ati = readmatrix('2022.03.25_logs/MS010MPT008_NIDAQ USB-6210_31683603.csv');
ms010msp008_ati(:, 4:end) = Gamma_volt_to_load(ms010msp008_ati); %convert from voltages to loads
ms010msp008_ati = ms010msp008_ati(:, 4:6);

figure;
plot(rms(ms010msp008_ati, 2));
TE = 1/120;
start = 2800;

% compute
ms010msp_thrust = zeros(10/TE+2, 3, 5);
ms010msp_calib = zeros(7/TE+2, 3, 5);
force_mag = zeros(10/TE+2, 5);
force_mean = zeros(1,5);
force_var = zeros(1,5);
for i = 1:4
    pos = start+(i-1)*35/TE;
    ms010msp_thrust(:,:,i) = [ms010msp008_ati(pos+3/TE:pos+8/TE, :); ms010msp008_ati(pos+18/TE:pos+23/TE, :)];
    ms010msp_calib(:,:, i) = [ms010msp008_ati(pos+12/TE:pos+13/TE, :); ms010msp008_ati(pos+27/TE:pos+33/TE, :)];

    force_mag(:,i) = rms(ms010msp_thrust(:,:,i)-mean(ms010msp_calib(:,:,i),1), 2);
    force_mean(i) = mean(force_mag(:,i));
    force_var(i) = var(force_mag(:,i));
    force_mag(:,i) = smooth(force_mag(:,i));    
end

% plot thrust
figure;
hold on;
plot([zeros(10/TE+2, 1); reshape(force_mag,[],1)]);
yline(force_mean);

% 
rpm = [0 20 30 40 50 60].^2;
fig1 = figure("Name", "Force", "NumberTitle", "off");
hold on;
errorbar(rpm, [0 force_mean(1:end-1) 4.5], [0 force_var]);
xlim([0 65].^2);
xlabel('max rpm ^2 (%)');
ylabel('thrust (N)');

ft_type = fittype({'x'});
regression = fit(rpm.', [0 force_mean(1:end-1) 4.5].' , ft_type);
plot(regression);