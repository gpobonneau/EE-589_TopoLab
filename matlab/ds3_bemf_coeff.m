%% INITIALISATION
clc;
clear;
close all;

% add paths
work_dir = pwd;
idx = strfind(work_dir, '\');
addpath(work_dir(1:idx(end))+"\_data\2022.05.15_logs");
addpath(work_dir(1:idx(end))+"\matlab\functions");

% flags
flag_plotall = true;

% set figures parameters
set(groot, "DefaultAxesFontSize", 10);
set(groot, "DefaultLineLineWidth", 1.5);

%% CONSTANTS
KV = 840; % [rpm/V]

%% OPEN DATA
% create metadata (file-name, remove-edges, sampling-rate, battery-level)
meta{1} = {"output_2022-05-15_12-58-16_rpm-tests10-20.log", [1 0], 0.01, [16.72, 16.58]};
meta{2} = {"output_2022-05-15_14-39-22_rpm-tests-25-40.log", [1 0], 0.01, [16.59, 15.98]};
meta{3} = {"output_2022-05-15_15-17-15-motor-voltage.log", [1 0], 0.01, [16.00, 15.90]};
meta{4} = {"output_2022-05-15_16-39-40-prbs1.log", [2500 2000], 0.01, [15.82, 15.75]};
meta{5} = {"output_2022-05-15_16-47-21-prbs2.log", [600 300], 0.02, [15.75, 15.66]};
meta{6} = {"output_2022-05-15_16-59-29-battery-test2.log", [1 0], 0.01, [15.69, 15.16]};

% read data
u{length(meta)} = {};
y{length(meta)} = {};
for i = 1:length(meta)
    % read data
    temp = readmatrix(meta{i}{1});
    temp = temp(meta{i}{2}(1):end-meta{i}{2}(2), :);

    u{i} = temp(:,2); % [us] pwm pulse high duration
    y{i} = temp(:,3); % [Hz] signal from rpm sensor
end

close all;

%% PREPROCESS DATA
md_tachy = [0 1410 2340 3060 3690 4290 5040 5640]'; % hand measured data
input_pwm = [1000, 1100:50:1400]';
LEN = length(input_pwm);

% estimation of battery voltage during experiment extrapolated from measured data
battery_level = linspace(meta{1}{4}(1), meta{2}{4}(2), LEN)'; 

% extract mean rpm
md_bemf = zeros(LEN, 2);
for i = 2:LEN
    idx = 1+(i>4); % take data from experiment 1 and 2
    mask = extract_vals(u{idx}, input_pwm(i), 1500);
    md_bemf(i,1) = mean(y{idx}(mask));
    md_bemf(i,2) = var(y{idx}(mask));
    
    % plotting
    if (flag_plotall==true)
        figure("Name", "Visualisation of mask used to compute average", "NumberTitle", "off");
        yyaxis left; plot(mask); ylim([0 1.1]); ylabel('Mask');
        yyaxis right; plot(y{idx}); ylim([0 1e3]); ylabel('RPM sensor signal [Hz]');
        xlable("time [samples]");
    end
end

%% COMPUTE MOTOR'S NUMBER OF ELECTRIC POLES
fitType = {'x'};
reg_p = fit(md_tachy(2:end), md_bemf(2:end, 1), fitType);
NB_POLES = round(2/reg_p.a);
txt = "nb\_poles/2 = "+num2str(1/reg_p.a);
disp(NB_POLES);

% plot
figure("Name", "Computing number of electrical pôles of BLCD motor", "NumberTitle", "off");
hold on; grid on; errorbar(md_tachy, md_bemf(:, 1), md_bemf(:, 2)); plot(reg_p); text(1100, 650, txt);
xlabel("Tachymeter measures [rpm]");
ylabel('RPM sensor signal [Hz]');
legend("data", "fitted curve", "Location", "best");

%% COMPARE KV MODEL TO MEASUREMENTS
figure("Name", "Linearity of RPM and verification of KV coefficient (no wind)", "NumberTitle", "off");
hold on;
grid on;
plot(input_pwm, md_tachy, '-o');
errorbar(input_pwm, md_bemf(:,1)*NB_POLES/2, md_bemf(:,2));
plot(input_pwm, KV*battery_level.*(input_pwm-1000)/1000);
ylabel("Propeller speed [rpm]");
xlabel("Throttle duty cycle [us]");
legend("manual tachymeter measures", "RPM sensor signal w/17 poles", "throttle [%] \cdot battery voltage [V] \cdot KV [rpm/V]", "Location", "Best");

