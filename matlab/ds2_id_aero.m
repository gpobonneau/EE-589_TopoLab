%% INITIALISATION
clc;
clear;
close all;

% add paths
work_dir = pwd;
idx = strfind(work_dir, '\');
addpath(work_dir(1:idx(end))+"\_data\2022.04.28_logs");
addpath(work_dir(1:idx(end))+"\_data\2022.04.28_logs\nidaq");
addpath(work_dir(1:idx(end))+"\matlab\functions");
addpath(work_dir(1:idx(end))+"\matlab\simulink_model");

% flags
flag_plotall = false;

% set figures parameters
set(groot, "DefaultAxesFontSize", 14);
set(groot, "DefaultLineLineWidth", 1.5);
% reset(gcf);

%% CONSTANTS
NB_WIND = 5; % number of sampled wind conditions
NB_THROTTLE = 9; % nb of sampled throttles
ATI_TS = 1/120; % [s] sampling time of ATI load cell
LOG_TS = 200/1000; % [s] software sampling time at that moment
KV = 840*(2*pi/60); % [rad/s/V] value from motor datasheet
KE = 1/KV; % [Vs/rad]
NB_POLES = 17; % number pf electrical poles in motor

%% GROUP, MERGE AND CONVERT DATA
% format is {ati data; arduino data; approx delay between logs [samples]; data range[samples]; battery status [%]; wind speed [m/s]}

meta{5} = {"MS024MPT007_NIDAQ USB-6210_31683603.csv", "output_2022-04-29_17-35-20_w0_upto60.log", 1050, [30 30], 0.68, 0};
meta{1} = {"MS024MPT008_NIDAQ USB-6210_31683603.csv", "output_2022-04-29_17-40-31w50_upto80.log", -9330, [1300 30], 0.60, 6.4};
meta{2} = {"MS024MPT009_NIDAQ USB-6210_31683603.csv", "output_2022-04-29_17-46-37_w80_upto80.log", -2065, [1700 30], 0.535, 9.6};
meta{3} = {"MS024MPT010_NIDAQ USB-6210_31683603.csv", "output_2022-04-29_17-51-59_w90_upto80.log", -1675, [1300 1000], 0.44, 10.8};
meta{4} = {"MS024MPT011_NIDAQ USB-6210_31683603.csv", "output_2022-04-29_17-57-19_w100_upto80.log", -630, [1100 250], 0.365, 12.0};

% read and merge data
ms010msp{NB_WIND} = {};
for i = 1:5
    ms010msp{i} = ds2_merge_data(meta{i}{1}, meta{i}{2}, meta{i}{3}, 0);
    temp = ms010msp{i};
    
    % convert data
    temp(:,8) = temp(:,8)*10 + 1000; % [us] convert into pwm duty cycle 
    temp(:,9) = temp(:,9); % [Hz] signal freq of rpm sensor =/= rpm
    
    % plot
    if (flag_plotall==true)
        figure("Name", "Verify corase alignement of logs", "NumberTitle", "off");
        yyaxis left; plot(temp(:,1), temp(:,9)); ylabel('RPM sensor signal [Hz]'); yyaxis right; plot(temp(:,1), temp(:,8)); ylabel("Throttle duty cycle [us]"); xlabel("Time [s]"); xlim([0 temp(end,1)]);
    end

    % confirm changes
    ms010msp{i} = temp;
end

%% read and merge data
ms010msp_fil{NB_WIND} = {};
for i = 1:5
    ms010msp_fil{i} = ds2_merge_data(meta{i}{1}, meta{i}{2}, meta{i}{3}, 1);
    temp = ms010msp_fil{i};
    
    % convert data
    temp(:,8) = temp(:,8)*10 + 1000; % [us] convert into pwm duty cycle 
    temp(:,9) = temp(:,9); % [Hz] signal freq of rpm sensor =/= rpm
    
    % plot
    if (flag_plotall==true)
        figure("Name", "Verify corase alignement of logs", "NumberTitle", "off");
        yyaxis left; plot(temp(:,1), temp(:,9)); ylabel('RPM sensor signal [Hz]'); yyaxis right; plot(temp(:,1), temp(:,8)); ylabel("Throttle duty cycle [us]"); xlabel("Time [s]"); xlim([0 temp(end,1)]);
    end

    % confirm changes
    ms010msp_fil{i} = temp;
end

clear temp i;

%% SELECT RANGE OF CALIBRATION DATA
% plot
if (flag_plotall==true)
    idx = 1:6000;
    for i = 1:5
        SELECT = i;
        figure("Name", "Normalised data @ "+num2str(meta{i}{6})+" [m/s] wind", "NumberTitle", "off");
        hold on;
        plot(ms010msp{SELECT}(idx, 8)/max(abs(ms010msp{SELECT}(idx, 8))));
        plot(ms010msp{SELECT}(idx, 9)/max(abs(ms010msp{SELECT}(idx, 9))));
        plot(rms(ms010msp{SELECT}(idx,2:4), 2)/max(abs(rms(ms010msp{SELECT}(idx,2:4), 2))));
        plot(rms(ms010msp{SELECT}(idx,5:7), 2)/max(abs(rms(ms010msp{SELECT}(idx,5:7), 2))));
        legend("Throttle duty cycle [us]", 'RPM sensor signal [Hz]', "Torque [Nm]", "Thrust [N]", "Location", "best");
        ylabel("Normalised amplitude [-]");
        xlabel("Time [samples]");
    end

    figure("Name", "Thrust for all data sets", "NumberTitle", "off");
    hold on;
    for i = 1:5
        SELECT = i;
        plot(rms(ms010msp{SELECT}(:,2:4), 2));
    end
    legend("53% wind", "80% wind", "90% wind", "100% wind", "0% wind", "Location", "best");
    ylabel("Thrust [N]");
    xlabel("Time [samples]");
end

%% CALIBRATE DATA
MASK_CAL = {1:350; 550:1000; 200:600; 600:800; 1:1000};

ms010msp_cal = ms010msp;
ms010msp_fil_cal = ms010msp_fil;
for i = 1:5
    SELECT = i;
    % Calibrate ATI sensor for force and torque
    CALIB_VAL = mean(ms010msp{SELECT}(MASK_CAL{i}, 2:7), 1);
    ms010msp_cal{SELECT}(:,2:7) = ms010msp{SELECT}(:,2:7) - CALIB_VAL;
    CALIB_VAL = mean(ms010msp_fil{SELECT}(MASK_CAL{i}, 2:7), 1);
    ms010msp_fil_cal{SELECT}(:,2:7) = ms010msp_fil{SELECT}(:,2:7) - CALIB_VAL;
    % start time at zero
    ms010msp_cal{SELECT}(:,1) = ms010msp_cal{SELECT}(:,1) - ms010msp_cal{SELECT}(1,1);
    ms010msp_fil_cal{SELECT}(:,1) = ms010msp_fil_cal{SELECT}(:,1) - ms010msp_fil_cal{SELECT}(1,1);
    % select relevant data range for next computations
    ms010msp_cal{SELECT} = ms010msp_cal{SELECT}(meta{i}{4}(1):end-meta{i}{4}(2),:);
    ms010msp_fil_cal{SELECT} = ms010msp_fil_cal{SELECT}(meta{i}{4}(1):end-meta{i}{4}(2),:);
end

SELECT = 3;
% Before calibration
figure("Name", "Raw data @ "+meta{SELECT}{6}+" [m/s] wind", "NumberTitle", "off");
plot(ms010msp{SELECT}(:,1), ms010msp{SELECT}(:,2:7));
legend("x", "y", "z", "rx", "ry", "rz");
ylabel("Amplitude [-]");
xlabel("Time [s]");

% after calibration
figure("Name", "After calibration @ "+meta{SELECT}{6}+" [m/s] wind", "NumberTitle", "off");
plot(ms010msp_cal{SELECT}(:,1), ms010msp_cal{SELECT}(:,2:7));
legend("x", "y", "z", "rx", "ry", "rz");
ylabel("Amplitude [-]");
xlabel("Time [s]");

% after filtering
figure("Name", "After calibration and filtering @ "+meta{SELECT}{6}+" [m/s] wind", "NumberTitle", "off");
plot(ms010msp_fil_cal{SELECT}(:,1), ms010msp_fil_cal{SELECT}(:,2:7));
legend("x", "y", "z", "rx", "ry", "rz");
ylabel("Amplitude [-]");
xlabel("Time [s]");

% rms
figure("Name", "RMS signal after filtering @ "+meta{SELECT}{6}+" [m/s] wind", "NumberTitle", "off");
hold on;
plot(ms010msp_fil_cal{SELECT}(:,1), rms(ms010msp_fil_cal{SELECT}(:,2:4), 2));
plot(ms010msp_fil_cal{SELECT}(:,1), rms(ms010msp_fil_cal{SELECT}(:,5:7), 2));
legend("thrust", "torque");
ylabel("Amplitude [-]");
xlabel("Time [s]");
%% COMPUTE VALUES FROM DATA

w=zeros(NB_WIND*NB_THROTTLE, 1); % [rad/s] omega
w_var=zeros(NB_WIND*NB_THROTTLE, 1); % [rad/s] omega
j=zeros(NB_WIND*NB_THROTTLE, 1); % [m/rad] advance ratio wind/omega
t=zeros(NB_WIND*NB_THROTTLE, 1); % [Nm] thrust
t_var=zeros(NB_WIND*NB_THROTTLE, 1); % [Nm] variance of thrust
q=zeros(NB_WIND*NB_THROTTLE, 1); % [N] torque
q_var=zeros(NB_WIND*NB_THROTTLE, 1); % [N] variance of torque

for k = 1:NB_WIND
    
%     dataset = ms010msp_cal{k};
    dataset = ms010msp_fil_cal{k};

    % Compute data
    for i = 0:NB_THROTTLE-1

        idx = (k-1)*NB_THROTTLE+1+i;
        
        if i==0
            MASK = extract_vals(dataset(:,8), 1000, 1000);
        else
            MASK = extract_vals(dataset(:,8), 1000+i*100, 200);
        end

        data = rms(dataset(MASK,2:4), 2);
        torque = rms(dataset(MASK,5:7), 2);

        % compute values
        w(idx)=mean(dataset(MASK,9), 1); % [rad/s] omega
        w_var(idx)=var(dataset(MASK,9), 1);
        j(idx)=meta{k}{6}/w(idx); % [m/rad] w/omega
        t(idx)=mean(data, 1); % [N] thrust
        t_var(idx)=var(data, 1);
        q(idx)=mean(torque, 1); % [Nm] torque
        q_var(idx)=var(torque, 1);
        
        % verify mask position and data detrending
        if (flag_plotall==true)
            figure("Name", "Data overview and mask alignement @ "+meta{k}{6}+" [m/s] wind @ " +num2str(i*10)+"% throttle", "NumberTitle", "off");
            hold on; plot(dataset(:,2:7)./max(abs(dataset(:,2:7))), 'Handlevisibility', 'off'); plot(MASK); ylabel("Amplitude"); xlabel("Samples"); xlim([0 length(dataset)]);
        end
    end
end

% figure
k = 1; i = 6;
MASK = extract_vals(ms010msp_cal{k}(:,8), 1600, 200);
figure("Name", "Data overview and mask alignement @ "+meta{k}{6}+" [m/s] wind @ " +num2str(i*10)+"% throttle", "NumberTitle", "off");
hold on; plot(ms010msp_cal{k}(:,2:7)./max(abs(ms010msp_cal{k}(:,2:7)))); plot(MASK); ylabel("Normalised amplitude"); xlabel("Samples"); xlim([0 length(ms010msp_cal{k})]);
xlim([19000 22000]);
legend("x", "y", "z", "rx", "ry", "rz", "MASK");

%% PLOT DATA BEFORE PROCESSING
u=1000:100:1800;

% visualise all data
figure("Name", "Torque as function of propeller speed and advance ratio (100% ws = 12.0 [m/s])", "NumberTitle", "off");
hold on;
for k = 1:NB_WIND
    idx=(k-1)*NB_THROTTLE+1:(k)*NB_THROTTLE;
    scatter3(w(idx), j(idx), t(idx), 'filled');
end
xlabel('RPM sensor signal [Hz]'); 
ylabel('Pseudo advance ratio [m]');
zlabel('Thrust [N]');
legend("53% ws", "80% ws", "90% ws", "100% ws", "0% ws", "Location", "best");
grid on;

%% wind speed influence
fitType = {'x'};
reg_ws = fit(u(1:end-2)'-u(1), w(end-NB_THROTTLE+1:end-2), fitType); % fit data @ 0% wind speed

figure("Name", "Influence of wind conditions on propeller speed (100% ws = 12.0 [m/s])", "NumberTitle", "off");
hold on;
for i = 1:NB_WIND
    idx=(i-1)*NB_THROTTLE+1:i*NB_THROTTLE;
    errorbar(u, w(idx), w_var(idx));
end
plot(linspace(u(1), u(end), 100), linspace(0, u(end)-u(1), 100)*reg_ws.a, '--');
ylabel('RPM sensor signal [Hz]'); 
xlabel('Throttle duty cycle [us]');
legend("53% ws", "80% ws", "90% ws", "100% ws", "0% ws", "Location", "best");
grid on;

%% FIT DATA TO MODEL
% remove 0% wind speed values
w0=w(1:end-NB_THROTTLE);
w_var0=w_var(1:end-NB_THROTTLE);
j0=j(1:end-NB_THROTTLE);
t0=t(1:end-NB_THROTTLE);
t_var0=t_var(1:end-NB_THROTTLE);
q0=q(1:end-NB_THROTTLE);
q_var0=q_var(1:end-NB_THROTTLE);

% remove NaN values
w0=w(~isnan(w0));
j0=j(~isnan(j0));
t0=t(~isnan(t0));
q0=q(~isnan(q0));

fitType = {'x', 'y'}; % linear fit in x and y

% force
[sf_t, gdn_t] = fit([w0.^2, j0.*w0.^2], t0, fitType);
if (flag_plotall==true)
    figure("Name", "Force", "NumberTitle", "off");
    plot(sf_t, [w0.^2, j0.*w0.^2], t0);
    xlabel('\omega^2 [rad/s]^2'); 
    ylabel('J \cdot \omega^2 [m\cdots/rad3]');
    zlabel('thrust [N]');
end

% torque
[sf_q, gdn_q] = fit([w0.^2, j0.*w0.^2], q0, fitType);
if (flag_plotall==true)
    figure("Name", "Torque", "NumberTitle", "off");
    plot(sf_q,[w0.^2, j0.*w0.^2], q0);
    xlabel('\omega^2 [rad/s]'); 
    ylabel('J \cdot \omega^2 [m\cdots/rad3]');
    zlabel('Torque [Nm]');
end

% goddness of fit r^2 = 1 - ss_res/ss_tot;
disp("r squared for Thrust :");
disp(gdn_t.rsquare);
disp("r squared for Torque :");
disp(gdn_q.rsquare);
%% MAKE NICE PLOTS
load('params.mat');
CT0 = sf_t.a; disp(CT0);
CT1 = sf_t.b; disp(CT1);
CQ0 = sf_q.a; disp(CQ0);
CQ1 = sf_q.b; disp(CQ1);
save('params.mat','Td', 'Bf', 'Ra', 'Ke', 'Jt', 'La', 'CT0', 'CT1', 'CQ0', 'CQ1', '-double');
[X,Y] = meshgrid(0:50:1200,0:5e-3:0.1);

% thrust
figure("Name", "Thrust model with fitted data", "NumberTitle", "off");
hold on;
grid on; 
Z = CT0*X.^2 + CT1*Y.*X.^2;
surf(X, Y, Z);
scatter3(w0, j0, t0, 'MarkerEdgeColor', '#7E2F8E', 'MarkerFaceColor', '#7E2F8E');
xlabel('RPM sensor signal [Hz]'); 
ylabel('Pseudo advance ratio [m]');
zlabel('Thrust [N]');

% torque
figure("Name", "Torque model with fitted data", "NumberTitle", "off");
Z = CQ0*X.^2 + CQ1*Y.*X.^2;
hold on;
grid on; 
surf(X, Y, Z);
scatter3(w0, j0, q0, 'MarkerEdgeColor', '#D95319', 'MarkerFaceColor', '#D95319');
xlabel('RPM sensor signal [Hz]'); 
ylabel('Pseudo advance ratio [m]');
zlabel('Torque [Nm]');

%% EXPLOIT MODEL TO MAKE PREDICTION ON THRUST

SELECT = 1;
idx = (1:NB_THROTTLE)+(i-1)*NB_THROTTLE;

% compute signal using model
wt = ms010msp_cal{SELECT}(:, 9); 
jt = meta{SELECT}{6}./wt;
model = CT0*wt.^2 + CT1*jt.*wt.^2;

figure("Name", "Thrust model with fitted data @ "+meta{SELECT}{6}+" [m/s] wind", "NumberTitle", "off");
plot(ms010msp_cal{SELECT}(:,1), [rms(ms010msp_cal{SELECT}(:,2:4), 2), rms(ms010msp_fil_cal{SELECT}(:,2:4), 2), model]);
ylabel('Thrust [N]');
xlabel("Time [s]");
legend("raw data", "filtered data", "model");


%% EXPLOIT MODEL TO MAKE PREDICTION ON TORQUE
SELECT = 3;
dataset = ms010msp_cal{SELECT};
idx = (1:NB_THROTTLE)+(i-1)*NB_THROTTLE;

wt = dataset(:, 9); 
jt = meta{SELECT}{6}./wt;
model = CQ0*wt.^2 + CQ1*jt.*wt.^2;

data = rms(dataset(:,5:7), 2);

figure("Name", "Torque model with fitted data @ "+meta{SELECT}{6}+" [m/s] wind", "NumberTitle", "off");
plot(ms010msp_cal{SELECT}(:,1), [rms(ms010msp_cal{SELECT}(:,5:7), 2), rms(ms010msp_fil_cal{SELECT}(:,5:7), 2), model]);
ylabel('Torque [Nm]');
xlabel("Time [s]");
legend("raw data", "filtered data", "model");
