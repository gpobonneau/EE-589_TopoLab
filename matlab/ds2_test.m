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

%% GROUP MERGE AND CONVERT DATA
% format is {ati data; log data; delay; edges; battery; wind}

ATI_TS = 1/120;
LOG_TS = 200/1000;

metadata{1} = {"MS024MPT007_NIDAQ USB-6210_31683603.csv", "output_2022-04-29_17-35-20_w0_upto60.log", 1050, [30 30], 0.68, 0.00};
% wind = 50%; battery = 66%;
metadata{2} = {"MS024MPT008_NIDAQ USB-6210_31683603.csv", "output_2022-04-29_17-40-31w50_upto80.log", -9330, [1300 30], 0.60, 0.50};
% wind = 80%; battery = 54%;
metadata{3} = {"MS024MPT009_NIDAQ USB-6210_31683603.csv", "output_2022-04-29_17-46-37_w80_upto80.log", -2065, [1700 30], 0.535, 0.80};
% wind = 90%; battery = 47%;
metadata{4} = {"MS024MPT010_NIDAQ USB-6210_31683603.csv", "output_2022-04-29_17-51-59_w90_upto80.log", -1675, [1300 1000], 0.44, 0.90};
% wind = 100%; battery = 41%;
metadata{5} = {"MS024MPT011_NIDAQ USB-6210_31683603.csv", "output_2022-04-29_17-57-19_w100_upto80.log", -630, [1100 250], 0.365, 1.00};
% battery = 32%;

% read and merge data
for i = 1:5
    ms010msp{i} = ds2_merge_data(metadata{i}{1}, metadata{i}{2}, metadata{i}{3});
    
    % manual edge removal
    temp = ms010msp{i};
    temp = temp(metadata{i}{4}(1):end-metadata{i}{4}(2),:);
    temp(:,1) = temp(:,1) - temp(1,1);
    ms010msp{i} = temp;
end

clear edges temp i;

metadata = [0 50 80 90 100]/100; % wind

%% SELECT DATA SET
metadata = [0 50 80 90 100]/100; % wind
select = 1;
data_set = ms010msp{select};

% dataset preview
figure("Name", "All data", "NumberTitle", "off");
plot(data_set(:,1), normalize(data_set(:,2:9), 'norm'));
legend('x', 'y', 'z', 'rx', 'ry', 'ry', 'U', 'Y');

% plot data to verify alignement
figure("Name", "Verify coarse alignement @ "+metadata(2)*100+"% wind", "NumberTitle", "off");
hold on;
plot(normalize(data_set(:,2)));
plot(normalize(data_set(:,9)));

% Calibrate ATI sensor
mask = extract_vals(data_set(:,8), 0, 1000);
calib = mean(data_set(mask,2:7), 1);
data_set(:,2:7) = data_set(:,2:7) - calib;

% plot
figure("Name", "Force for calibration", "NumberTitle", "off");
subplot(2,1,1);
yyaxis right;
hold on;
plot(normalize(data_set(:,4)));
plot(normalize(data_set(:,9)), 'g');
yyaxis left;
plot(mask);
subplot(2,1,2);
plot(data_set(mask,2:7));

% Compute force
nb_max = 6; %max(data_set(:,8))

rpm_gt = (0:nb_max)/10;

force = zeros(1, nb_max);
force_var = zeros(1, nb_max);
torque = zeros(1, nb_max);
rpm_data = zeros(1, nb_max);
rpm_var = zeros(1, nb_max);

for i = 1:nb_max

    mask = extract_vals(data_set(:,8), i*10, 200);

    temp = data_set(mask,:);

    force(i) = mean(rms(temp(:,2:4), 2), 1);
    force_var(i) = var(rms(temp(:,2:4), 2), 1);
    torque(i) = mean(rms(temp(:,5:7), 2), 1);
    rpm_data(i) = mean(temp(:,9), 1);
    rpm_var(i) = var(temp((1:LOG_TS/ATI_TS:end)+1,9), 1);

    % plots
    figure("Name", "Thrust value = "+i*10+"%", "NumberTitle", "off");
    subplot(3,1,1);
    yyaxis right;
    hold on;
    plot(normalize(data_set(:,4)));
    plot(normalize(data_set(:,9)), 'g');
    yyaxis left;
    plot(mask);

    subplot(3,1,2);
    plot(data_set(mask,9));
    ylim(1.2*[0 max(data_set(mask,9))]);
    ylabel("RPM");
    
    subplot(3,1,3);
    plot(rms(data_set(mask,2:4), 2));
    ylim(1.2*[0 max(rms(data_set(mask,2:4), 2))]);
    ylabel("Force RMS");
end

% Plot rpm
figure("Name", "RPM vs RPM @ "+metadata(2)*100+"% wind", "NumberTitle", "off");
hold on;
errorbar(rpm_gt(2:end), rpm_data, rpm_var);
ft_type = fittype({'x', '1'});
regression = fit(rpm_gt(2:end).', rpm_data.', ft_type, 'Weight', 1./rpm_var.');
plot(regression);
xlabel('RPM Ground Thruth (%)');
ylabel('RPM Measured ');

disp("RPM Coeff");
disp(regression.a);
disp(regression.b);

% Plot regression
figure("Name", "Trust vs RPM @ "+metadata(2)*100+"% wind", "NumberTitle", "off");
hold on;
errorbar(rpm_gt, [0 force], [0 force_var]);
ft_type = fittype({'x^2'});
regression = fit(rpm_gt.', [0 force].', ft_type, 'Weight', [0 1./force_var].');
plot(regression);
xlabel('RPM (%)');
ylabel('Thrust (N)');

disp("Wind Coeff");
disp(regression.a);
