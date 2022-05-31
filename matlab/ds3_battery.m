%% INITIALISATION
clc;
clear;
close all;

% add paths
work_dir = pwd;
idx = strfind(work_dir, '\');
addpath(work_dir(1:end)+"\functions");
addpath(work_dir(1:end)+"\2022.05.15_logs");

% add flags
save_figs = false;

% set figures parameters
set(groot, "DefaultAxesFontSize", 10);
set(groot, "DefaultLineLineWidth", 1.5);

%% OPEN DATA
KK = 8.5387; % value from ds3_bemf_coeff

% select data and add metadata
meta{1} = {"output_2022-05-15_12-58-16_rpm-tests10-20.log", [1 0], 0.01};
meta{2} = {"output_2022-05-15_14-39-22_rpm-tests-25-40.log", [1 0], 0.01};
meta{3} = {"output_2022-05-15_15-17-15-motor-voltage.log", [1 0], 0.01};
meta{4} = {"output_2022-05-15_16-39-40-prbs1.log", [2500 2000], 0.01};
meta{5} = {"output_2022-05-15_16-47-21-prbs2.log", [600 300], 0.02};
meta{6} = {"output_2022-05-15_16-59-29-battery-test2.log", [1 0], 0.01};

for i = 1:6
    % read data
    temp = readmatrix(meta{i}{1});
    temp(:, 3) = temp(:, 3)*KK*(2*pi/60); % convert into rad/s
    temp = temp(meta{i}{2}(1):end-meta{i}{2}(2), :);

    u{i} = temp(:,2);
    y{i} = temp(:,3);
end

%% CONCLUSION
mask = extract_vals(u{2}, 1400, 500);
t = meta{2}{3}*(0:length(y{2}(mask))-1).';
reg_1 = fit(t, y{2}(mask), 'poly1');
% plot
figure("Name", "Voltage drop rate @75% charge", "NumberTitle", "off");
hold on;
plot(t, y{2}(mask));
plot(reg_1);
disp(reg_1.p1);
xlabel("time [s]");
ylabel("\omega [rad/s]");
ylim(1.2*[0 max(y{2}(mask))]);
xlim([0 t(end)]);

mask = extract_vals(u{6}, 1400, 500);
t = meta{6}{3}*(0:length(y{6}(mask))-1).';
reg_2 = fit(t, y{6}(mask), 'poly1');
% plot
figure("Name", "Voltage drop rate @45% charge", "NumberTitle", "off");
hold on;
plot(t, y{6}(mask));
plot(reg_2);
disp(reg_2.p1);
xlabel("time [s]");
ylabel("\omega [rad/s]");
ylim(1.2*[0 max(y{6}(mask))]);
xlim([0 t(end)]);