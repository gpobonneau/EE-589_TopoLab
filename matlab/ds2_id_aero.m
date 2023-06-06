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
PROP_DIAM = 10*0.254; % [m] 10 inches 
AIR_DENSITY = 1.162; % [kg/m3]
BATTERY_VOLTAGE = 16; % [V]

%% GROUP, MERGE AND CONVERT DATA
% format is {ati data; arduino data; approx delay between logs [samples]; data range[samples]; battery status [%]; wind speed [m/s]}

metadata{5} = {"MS024MPT007_NIDAQ USB-6210_31683603.csv", "output_2022-04-29_17-35-20_w0_upto60.log", 1050, [30 30], 0.68, 0};
metadata{1} = {"MS024MPT008_NIDAQ USB-6210_31683603.csv", "output_2022-04-29_17-40-31w50_upto80.log", -9330, [1300 30], 0.60, 6.4};
metadata{2} = {"MS024MPT009_NIDAQ USB-6210_31683603.csv", "output_2022-04-29_17-46-37_w80_upto80.log", -2065, [1700 30], 0.535, 9.6};
metadata{3} = {"MS024MPT010_NIDAQ USB-6210_31683603.csv", "output_2022-04-29_17-51-59_w90_upto80.log", -1675, [1300 1000], 0.44, 10.8};
metadata{4} = {"MS024MPT011_NIDAQ USB-6210_31683603.csv", "output_2022-04-29_17-57-19_w100_upto80.log", -630, [1100 250], 0.365, 12.0};

% read and merge data
ms010msp{NB_WIND} = {};
for i = 1:5
    ms010msp{i} = ds2_merge_data(metadata{i}{1}, metadata{i}{2}, metadata{i}{3}, 0);
    temp = ms010msp{i};
    
    % convert data
    temp(:,8) = temp(:,8)*10 + 1000; % [us] convert into pwm duty cycle 
    temp(:,9) = temp(:,9); % [Hz] signal freq of rpm sensor =/= rpm
    
    % plot
    if (flag_plotall==true)
        figure("Name", "Verify corase alignement of logs", "NumberTitle", "off");
        yyaxis left; plot(temp(:,1), temp(:,9)); ylabel('Output Propeller Speed [Hz]'); yyaxis right; plot(temp(:,1), temp(:,8)); ylabel("Throttle duty cycle [us]"); xlabel("Time [s]"); xlim([0 temp(end,1)]);
    end

    % confirm changes
    ms010msp{i} = temp;
end

%% read and merge data
ms010msp_fil{NB_WIND} = {};
for i = 1:5
    ms010msp_fil{i} = ds2_merge_data(metadata{i}{1}, metadata{i}{2}, metadata{i}{3}, 1);
    temp = ms010msp_fil{i};
    
    % convert data
    temp(:,8) = temp(:,8)*10 + 1000; % [us] convert into pwm duty cycle 
    temp(:,9) = temp(:,9); % [Hz] signal freq of rpm sensor =/= rpm
    
    % plot
    if (flag_plotall==true)
        figure("Name", "Verify corase alignement of logs", "NumberTitle", "off");
        yyaxis left; plot(temp(:,1), temp(:,9)); ylabel('Output Propeller Speed [Hz]'); yyaxis right; plot(temp(:,1), temp(:,8)); ylabel("Throttle duty cycle [us]"); xlabel("Time [s]"); xlim([0 temp(end,1)]);
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
        figure("Name", "Normalised data @ "+num2str(metadata{i}{6})+" [m/s] wind", "NumberTitle", "off");
        hold on;
        plot(ms010msp{SELECT}(idx, 8)/max(abs(ms010msp{SELECT}(idx, 8))));
        plot(ms010msp{SELECT}(idx, 9)/max(abs(ms010msp{SELECT}(idx, 9))));
        plot(rms(ms010msp{SELECT}(idx,2:4), 2)/max(abs(rms(ms010msp{SELECT}(idx,2:4), 2))));
        plot(rms(ms010msp{SELECT}(idx,5:7), 2)/max(abs(rms(ms010msp{SELECT}(idx,5:7), 2))));
        legend("Throttle duty cycle [us]", 'Output Propeller Speed [Hz]', "Torque [Nm]", "Thrust [N]", "Location", "best");
        ylabel("Normalised amplitude [-]");
        xlabel("Time [samples]");
    end

    figure("Name", "Thrust for all data sets", "NumberTitle", "off");
    hold on;
    for i = 1:5
        SELECT = i;
        plot(rms(ms010msp{SELECT}(:,2:4), 2));
    end
    legend(sprintf('%4.1f [m/s]', metadata{5}{6}), sprintf('%4.1f [m/s]', metadata{1}{6}), sprintf('%4.1f [m/s]', metadata{2}{6}), sprintf('%4.1f [m/s]', metadata{3}{6}), sprintf('%4.1f [m/s]', metadata{4}{6}), "Location", "best");
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
    ms010msp_cal{SELECT} = ms010msp_cal{SELECT}(metadata{i}{4}(1):end-metadata{i}{4}(2),:);
    ms010msp_fil_cal{SELECT} = ms010msp_fil_cal{SELECT}(metadata{i}{4}(1):end-metadata{i}{4}(2),:);
end

SELECT = 3;
% Before calibration
figure("Name", "Raw data @ "+metadata{SELECT}{6}+" [m/s] wind", "NumberTitle", "off");
plot(ms010msp{SELECT}(:,1), ms010msp{SELECT}(:,2:7));
legend("x", "y", "z", "rx", "ry", "rz");
ylabel("Amplitude [-]");
xlabel("Time [s]");

% after calibration
figure("Name", "After calibration @ "+metadata{SELECT}{6}+" [m/s] wind", "NumberTitle", "off");
plot(ms010msp_cal{SELECT}(:,1), ms010msp_cal{SELECT}(:,2:7));
legend("x", "y", "z", "rx", "ry", "rz");
ylabel("Amplitude [-]");
xlabel("Time [s]");

% after filtering
figure("Name", "After calibration and filtering @ "+metadata{SELECT}{6}+" [m/s] wind", "NumberTitle", "off");
plot(ms010msp_fil_cal{SELECT}(:,1), ms010msp_fil_cal{SELECT}(:,2:7));
legend("x", "y", "z", "rx", "ry", "rz");
ylabel("Amplitude [-]");
xlabel("Time [s]");

% rms
figure("Name", "RMS signal after filtering @ "+metadata{SELECT}{6}+" [m/s] wind", "NumberTitle", "off");
hold on;
plot(ms010msp_fil_cal{SELECT}(:,1), rms(ms010msp_fil_cal{SELECT}(:,2:4), 2));
plot(ms010msp_fil_cal{SELECT}(:,1), rms(ms010msp_fil_cal{SELECT}(:,5:7), 2));
legend("thrust", "torque");
ylabel("Amplitude [-]");
xlabel("Time [s]");
%% COMPUTE VALUES FROM DATA

w=zeros(NB_WIND*NB_THROTTLE, 1); % [Hz] omega
w_var=zeros(NB_WIND*NB_THROTTLE, 1); % [Hz] omega
j=zeros(NB_WIND*NB_THROTTLE, 1); % [m/rad] advance ratio wind/omega/diam
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
        w(idx)=mean(dataset(MASK,9), 1); % [Hz] omega
        w_var(idx)=var(dataset(MASK,9), 1);
        j(idx)=metadata{k}{6}/w(idx)/PROP_DIAM*2*pi; % [1/rotations]
        t(idx)=mean(data, 1); % [N] thrust
        t_var(idx)=var(data, 1);
        q(idx)=mean(torque, 1); % [Nm] torque
        q_var(idx)=var(torque, 1);
        
        % verify mask position and data detrending
        if (flag_plotall==true)
            figure("Name", "Data overview and mask alignement @ "+metadata{k}{6}+" [m/s] wind @ " +num2str(i*10)+"% throttle", "NumberTitle", "off");
            hold on; plot(dataset(:,2:7)./max(abs(dataset(:,2:7))), 'Handlevisibility', 'off'); plot(MASK); ylabel("Amplitude"); xlabel("Samples"); xlim([0 length(dataset)]);
        end
    end
end

% figure
k = 1; i = 6;
MASK = extract_vals(ms010msp_cal{k}(:,8), 1600, 200);
figure("Name", "Data overview and mask alignement @ "+metadata{k}{6}+" [m/s] wind @ " +num2str(i*10)+"% throttle", "NumberTitle", "off");
hold on; plot(ms010msp_cal{k}(:,2:7)./max(abs(ms010msp_cal{k}(:,2:7)))); plot(MASK); ylabel("Normalised amplitude"); xlabel("Samples"); xlim([0 length(ms010msp_cal{k})]);
xlim([19000 22000]);
legend("x", "y", "z", "rx", "ry", "rz", "MASK");

%% PLOT DATA BEFORE PROCESSING
u = (0:10:80)/100*KV*BATTERY_VOLTAGE; % [Hz]

% visualise all data
fig1 = figure("Name", "Torque as function of propeller speed and advance ratio (100% ws = 12.0 [m/s])", "NumberTitle", "off");
hold on;
for k = [5 1:NB_WIND-1]
    idx=(k-1)*NB_THROTTLE+1:(k)*NB_THROTTLE;
    scatter3(w(idx), j(idx), t(idx), 'filled');
end

xlabel('Output Propeller Speed [rad/s]'); 
ylabel('Advance ratio [-]');
zlabel('Thrust [N]');
legend(sprintf('%4.1f [m/s]', metadata{5}{6}), sprintf('%4.1f [m/s]', metadata{1}{6}), sprintf('%4.1f [m/s]', metadata{2}{6}), sprintf('%4.1f [m/s]', metadata{3}{6}), sprintf('%4.1f [m/s]', metadata{4}{6}), "Location", "best");
grid on;

saveas(fig1, 'figures/2023-05-28_data', 'png');
saveas(fig1, 'figures/2023-05-28_data', 'mfig');

%% wind speed influence
fitType = {'x'};
reg_ws = fit(u(1:end-2)'-u(1), w(end-NB_THROTTLE+1:end-2), fitType); % fit data @ 0% wind speed

fig2 = figure("Name", "Influence of wind conditions on propeller speed (100% ws = 12.0 [m/s])", "NumberTitle", "off");
hold on;
for i = [5 1:NB_WIND-1]
    idx=(i-1)*NB_THROTTLE+1:i*NB_THROTTLE;
    errorbar(u, w(idx), w_var(idx), 'LineWidth', 1.5);
end
% plot(linspace(u(1), u(end), 100), linspace(0, u(end)-u(1), 100)*reg_ws.a, '--');
plot(1.2*linspace(u(1), u(end), 100), 1.2*linspace(0, u(end), 100), 'k--', 'LineWidth', 1);
ylabel('Output Propeller Speed [rad/s]'); 
xlabel('Input Propeller Speed [rad/s]');
legend(sprintf('%4.1f [m/s]', metadata{5}{6}), sprintf('%4.1f [m/s]', metadata{1}{6}), sprintf('%4.1f [m/s]', metadata{2}{6}), sprintf('%4.1f [m/s]', metadata{3}{6}), sprintf('%4.1f [m/s]', metadata{4}{6}), "Location", "best");
grid on;
ylim([0 1200]);

saveas(fig2, 'figures/2023-05-28_windspeed', 'png');
saveas(fig2, 'figures/2023-05-28_windspeed', 'mfig');

%% FIT DATA TO MODEL
% remove 0% wind speed values
w0=w(1:end-NB_THROTTLE)/2/pi;
w_var0=w_var(1:end-NB_THROTTLE);
j0=j(1:end-NB_THROTTLE);
t0=t(1:end-NB_THROTTLE);
t_var0=t_var(1:end-NB_THROTTLE);
q0=q(1:end-NB_THROTTLE);
q_var0=q_var(1:end-NB_THROTTLE);

% remove NaN values
w0=w0(~isnan(w0));
j0=j0(~isnan(j0));
t0=t0(~isnan(t0));
q0=q0(~isnan(q0));

fitType = {'x', 'y'}; % linear fit in x and y

% force
[sf_t, gdn_t] = fit([w0.^2, j0.*w0.^2], t0, fitType);
if (flag_plotall==true)
    figure("Name", "Force", "NumberTitle", "off");
    plot(sf_t, [w0.^2, j0.*w0.^2], t0);
    xlabel('\rho \cdot D^4 \cdot \omega^2'); 
    ylabel('\rho \cdot D^4 \cdot J \cdot \omega^2');
    zlabel('thrust [N]');
end

% torque
[sf_q, gdn_q] = fit([w0.^2, j0.*w0.^2], q0, fitType);
if (flag_plotall==true)
    figure("Name", "Torque", "NumberTitle", "off");
    plot(sf_q,[w0.^2, j0.*w0.^2], q0);
    xlabel('\rho \cdot D^5 \cdot \omega^2'); 
    ylabel('\rho \cdot D^5 \cdot J \cdot \omega^2');
    zlabel('Torque [Nm]');
end

% goddness of fit r^2 = 1 - ss_res/ss_tot;
disp("r squared for Thrust :");
disp(gdn_t.rsquare);
disp("r squared for Torque :");
disp(gdn_q.rsquare);

%% MAKE NICE PLOTS
load('params.mat');
CT0 = sf_t.a/AIR_DENSITY/PROP_DIAM^4; disp(CT0);
CT1 = sf_t.b/AIR_DENSITY/PROP_DIAM^4; disp(CT1);
CQ0 = sf_q.a/AIR_DENSITY/PROP_DIAM^5; disp(CQ0);
CQ1 = sf_q.b/AIR_DENSITY/PROP_DIAM^5; disp(CQ1);
save('params.mat','Td', 'Bf', 'Ra', 'Ke', 'Jt', 'La', 'CT0', 'CT1', 'CQ0', 'CQ1', '-double');
[X,Y] = meshgrid(0:50:1200,0:0.0075:0.15);

% thrust
fig3 = figure("Name", "Thrust model with fitted data", "NumberTitle", "off");
hold on;
grid on; 
Z = CT0*AIR_DENSITY*PROP_DIAM^4*(X/2/pi).^2 + CT1*AIR_DENSITY*PROP_DIAM^4*Y.*(X/2/pi).^2;
surf(X, Y, Z, 'FaceColor', 'none');
scatter3(w0*2*pi, j0, t0, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'r');
xlabel('Output Propeller Speed [rad/s]'); 
ylabel('Advance ratio [-]');
zlabel('Thrust [N]');
view(-45,25);

% torque
fig4 = figure("Name", "Torque model with fitted data", "NumberTitle", "off");
Z = CQ0*AIR_DENSITY*PROP_DIAM^5*(X/2/pi).^2 + CQ1*AIR_DENSITY*PROP_DIAM^5*Y.*(X/2/pi).^2;
hold on;
grid on; 
surf(X, Y, Z, 'FaceColor', 'none');
scatter3(w0*2*pi, j0, q0, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'b');
xlabel('Output Propeller Speed [rad/s]'); 
ylabel('Advance ratio [-]');
zlabel('Torque [Nm]');
view(-45,25);

saveas(fig3, 'figures/2023-05-28_thurst', 'png');
saveas(fig3, 'figures/2023-05-28_thurst', 'mfig');
saveas(fig4, 'figures/2023-05-28_torque', 'png');
saveas(fig4, 'figures/2023-05-28_torque', 'mfig');

%% EXPLOIT MODEL TO MAKE PREDICTION ON THRUST

SELECT = 1;
% idx = (1:NB_THROTTLE)+(i-1)*NB_THROTTLE;

% compute signal using model
wt = ms010msp_cal{SELECT}(:, 9)/2/pi; % Hz (rotations/sec)
jt = metadata{SELECT}{6}./wt/PROP_DIAM; % -
model = CT0*AIR_DENSITY*PROP_DIAM^4*wt.^2 + CT1*AIR_DENSITY*PROP_DIAM^4*jt.*wt.^2;

mask = ones(size(wt));
mask(1:1000) = 0.3;
mask(2550:7000) = 0.3;
mask(7950:10800) = 0.3;
mask(12150:15800) = 0.3;
mask(16650:19400) = 0.3;
mask(20700:23850) = 0.3;
mask(25000:27850) = 0.3;
mask(29000:31050) = 0.3;
mask(32100:end) = 0.3;

fig5 = figure("Name", "Thrust model with fitted data @ "+metadata{SELECT}{6}+" [m/s] wind", "NumberTitle", "off");
plot(ms010msp_cal{SELECT}(:,1), [rms(ms010msp_cal{SELECT}(:,2:4), 2), rms(ms010msp_fil_cal{SELECT}(:,2:4), 2), model]);
ylabel('Thrust [N]');
xlabel("Time [s]");
legend("raw data", "filtered data", "model");
xlim([0 ms010msp_cal{SELECT}(end,1)]);

saveas(fig5, 'figures/2023-05-28_model-CT01', 'png');
saveas(fig5, 'figures/2023-05-28_model-CT01', 'mfig');

fig6 = figure("Name", "Thrust model with fitted data @ "+metadata{SELECT}{6}+" [m/s] wind", "NumberTitle", "off");
plot(ms010msp_cal{SELECT}(:,1), [rms(ms010msp_cal{SELECT}(:,2:4), 2), rms(ms010msp_fil_cal{SELECT}(:,2:4), 2), model].*mask);
ylabel('Thrust [N]');
xlabel("Time [s]");
legend("raw data", "filtered data", "model");
xlim([0 ms010msp_cal{SELECT}(end,1)]);

saveas(fig6, 'figures/2023-05-28_model-CT02', 'png');
saveas(fig6, 'figures/2023-05-28_model-CT02', 'mfig');

mask(mask==0.3) = nan;

fig7 = figure("Name", "Thrust model with fitted data @ "+metadata{SELECT}{6}+" [m/s] wind", "NumberTitle", "off");
plot(ms010msp_cal{SELECT}(:,1), [rms(ms010msp_cal{SELECT}(:,2:4), 2), rms(ms010msp_fil_cal{SELECT}(:,2:4), 2), model].*mask);
ylabel('Thrust [N]');
xlabel("Time [s]");
legend("raw data", "filtered data", "model");
xlim([0 ms010msp_cal{SELECT}(end,1)]);

saveas(fig7, 'figures/2023-05-28_model-CT03', 'png');
saveas(fig7, 'figures/2023-05-28_model-CT03', 'mfig');

temp1 = rms(ms010msp_cal{SELECT}(:,2:4), 2);
temp2 = rms(ms010msp_fil_cal{SELECT}(:,2:4), 2);
temp1(isnan(mask)) = [];
temp2(isnan(mask)) = [];
model(isnan(mask)) = [];

fig8 = figure("Name", "Thrust model with fitted data @ "+metadata{SELECT}{6}+" [m/s] wind", "NumberTitle", "off");
plot([temp1, temp2, model]);
ylabel('Thrust [N]');
xlabel("Samples [-]");
legend("raw data", "filtered data", "model");
xlim([0 length(model)-1]);

saveas(fig8, 'figures/2023-05-28_model-CT04', 'png');
saveas(fig8, 'figures/2023-05-28_model-CT04', 'mfig');

%% EXPLOIT MODEL TO MAKE PREDICTION ON TORQUE
SELECT = 3;
dataset = ms010msp_cal{SELECT};
% idx = (1:NB_THROTTLE)+(i-1)*NB_THROTTLE;

wt = dataset(:, 9)/2/pi; % Hz (rotations/sec)
jt = metadata{SELECT}{6}./wt/PROP_DIAM; % -
model = CQ0*AIR_DENSITY*PROP_DIAM^5*wt.^2 + CQ1*AIR_DENSITY*PROP_DIAM^5*jt.*wt.^2;

data = rms(dataset(:,5:7), 2);

mask = ones(size(wt));
mask(1:1700) = 0.2;
mask(3200:5800) = 0.2;
mask(6550:8100) = 0.2;
mask(9500:12000) = 0.2;
mask(12750:13800) = 0.2;
mask(14950:16800) = 0.2;
mask(17800:18800) = 0.2;
mask(20000:21400) = 0.2;
mask(22350:end) = 0.2;

fig9 = figure("Name", "Torque model with fitted data @ "+metadata{SELECT}{6}+" [m/s] wind", "NumberTitle", "off");
plot(ms010msp_cal{SELECT}(:,1), [rms(ms010msp_cal{SELECT}(:,5:7), 2), rms(ms010msp_fil_cal{SELECT}(:,5:7), 2), model]);
ylabel('Torque [Nm]');
xlabel("Time [s]");
legend("raw data", "filtered data", "model");
xlim([0 ms010msp_cal{SELECT}(end,1)]);

saveas(fig9, 'figures/2023-05-28_model-CQ01', 'png');
saveas(fig9, 'figures/2023-05-28_model-CQ01', 'mfig');

fig10 = figure("Name", "Torque model with fitted data @ "+metadata{SELECT}{6}+" [m/s] wind", "NumberTitle", "off");
plot(ms010msp_cal{SELECT}(:,1), [rms(ms010msp_cal{SELECT}(:,5:7), 2), rms(ms010msp_fil_cal{SELECT}(:,5:7), 2), model].*mask);
ylabel('Torque [Nm]');
xlabel("Time [s]");
legend("raw data", "filtered data", "model");
xlim([0 ms010msp_cal{SELECT}(end,1)]);

saveas(fig10, 'figures/2023-05-28_model-CQ02', 'png');
saveas(fig10, 'figures/2023-05-28_model-CQ02', 'mfig');

mask(mask==0.2) = nan;

fig11 = figure("Name", "Torque model with fitted data @ "+metadata{SELECT}{6}+" [m/s] wind", "NumberTitle", "off");
plot(ms010msp_cal{SELECT}(:,1), [rms(ms010msp_cal{SELECT}(:,5:7), 2), rms(ms010msp_fil_cal{SELECT}(:,5:7), 2), model].*mask);
ylabel('Torque [Nm]');
xlabel("Time [s]");
legend("raw data", "filtered data", "model");
xlim([0 ms010msp_cal{SELECT}(end,1)]);

saveas(fig11, 'figures/2023-05-28_model-CQ03', 'png');
saveas(fig11, 'figures/2023-05-28_model-CQ03', 'mfig');

temp1 = rms(ms010msp_cal{SELECT}(:,5:7), 2);
temp2 = rms(ms010msp_fil_cal{SELECT}(:,5:7), 2);
temp1(isnan(mask)) = [];
temp2(isnan(mask)) = [];
model(isnan(mask)) = [];

fig12 = figure("Name", "Torque model with fitted data @ "+metadata{SELECT}{6}+" [m/s] wind", "NumberTitle", "off");
plot([temp1, temp2, model]);
ylabel('Torque [Nm]');
xlabel("Samples [-]");
legend("raw data", "filtered data", "model");
xlim([0 length(model)-1]);

saveas(fig12, 'figures/2023-05-28_model-CQ04', 'png');
saveas(fig12, 'figures/2023-05-28_model-CQ04', 'mfig');