%% INITIALISATION
clc;
clear;
close all;

% add paths
work_dir = pwd;
idx = strfind(work_dir, '\');
addpath(work_dir(1:idx(end))+"\_data\2022.05.15_logs");
addpath(work_dir(1:idx(end))+"\matlab\functions");

% add flags
save_figs = false;

% set figures parameters
set(groot, "DefaultAxesFontSize", 10);
set(groot, "DefaultLineLineWidth", 1.5);

%% OPEN DATA
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
    temp(:, 3) = temp(:, 3);
    temp = temp(meta{i}{2}(1):end-meta{i}{2}(2), :);

    u{i} = temp(:,2);
    y{i} = temp(:,3);
end

%% PLOT RPMS IN REGARD TO BATTERY LEVEL AT CONSTANT THROTTLE 
% plot experience 2, 40% throttle, no wind
SELECT = 2;
MASK = extract_vals(u{SELECT}, 1400, 500);
t = meta{SELECT}{3}*(0:length(y{SELECT}(MASK))-1).';
reg_1 = fit(t, y{SELECT}(MASK), 'poly1');
% plot
figure("Name", "Influence of battery discharging starting @75% charge", "NumberTitle", "off");
hold on;
plot(t, y{SELECT}(MASK));
plot(reg_1);
disp(reg_1.p1);
xlabel("time [s]");
ylabel('RPM sensor signal [Hz]');
% ylim(1.2*[0 max(y{SELECT}(MASK))]);
xlim([0 t(end)]);

% plot experience 6, 40% throttle, no wind
SELECT = 6;
MASK = extract_vals(u{SELECT}, 1400, 500);
t = meta{SELECT}{3}*(0:length(y{SELECT}(MASK))-1).';
reg_2 = fit(t, y{SELECT}(MASK), 'poly1');
% plot
figure("Name", "Influence of battery discharging starting @45% charge", "NumberTitle", "off");
hold on;
plot(t, y{SELECT}(MASK));
plot(reg_2);
disp(reg_2.p1);
xlabel("time [s]");
ylabel('RPM sensor signal [Hz]');
% ylim(1.2*[0 max(y{SELECT}(MASK))]);
xlim([0 t(end)]);