%% INITIALISATION
clc;
clear;
close all;

% add paths
work_dir = pwd;
idx = strfind(work_dir, '\');
addpath(work_dir(1:end)+"\functions");
addpath(work_dir(1:end)+"\2022.04.28_logs");

% set figures parameters
set(groot, "DefaultAxesFontSize", 14);
set(groot, "DefaultLineLineWidth", 1.5);
% reset(gcf);

%% CONSTANTS
NB_DS = 5; % number of datasets
NB_MAX = 9; % nb of points in each dataset
ATI_TS = 1/120; % [s] sampling time of ATI load cell
LOG_TS = 200/1000; % [s] software sampling time at that moment
KV = 840*(2*pi/60); % [rad/s/V] value from motor datasheet
KE = 1/KV; % [Vs/rad]
NB_POLES = 17; % number pf electrical poles in motor

%% GROUP, MERGE AND CONVERT DATA
% format is {ati data; log data; delay; edges; battery status; wind speed}

meta{5} = {"MS024MPT007_NIDAQ USB-6210_31683603.csv", "output_2022-04-29_17-35-20_w0_upto60.log", 1050, [30 30], 0.68, 0};
meta{1} = {"MS024MPT008_NIDAQ USB-6210_31683603.csv", "output_2022-04-29_17-40-31w50_upto80.log", -9330, [1300 30], 0.60, 6.4};
meta{2} = {"MS024MPT009_NIDAQ USB-6210_31683603.csv", "output_2022-04-29_17-46-37_w80_upto80.log", -2065, [1700 30], 0.535, 9.6};
meta{3} = {"MS024MPT010_NIDAQ USB-6210_31683603.csv", "output_2022-04-29_17-51-59_w90_upto80.log", -1675, [1300 1000], 0.44, 10.8};
meta{4} = {"MS024MPT011_NIDAQ USB-6210_31683603.csv", "output_2022-04-29_17-57-19_w100_upto80.log", -630, [1100 250], 0.365, 12.0};

% read and merge data
ms010msp{NB_DS} = {};
for i = 1:5
    ms010msp{i} = ds2_merge_data(meta{i}{1}, meta{i}{2}, meta{i}{3});
    
    % select data range
    temp = ms010msp{i};
%     temp = temp(meta{i}{4}(1):end-meta{i}{4}(2),:);
    
    % convert data
    temp(:,8) = temp(:,8)*10 + 1000; % [us] convert into pwm duty cycle 
    temp(:,9) = temp(:,9)*NB_POLES/2*(2*pi/60); % [rad/s ]convert into rad/s
    
    % start time at zero
    temp(:,1) = temp(:,1) - temp(1,1);
    
    % plot
%     figure; yyaxis left; plot(temp(:,9)); yyaxis right; plot(temp(:,8));
    
    % confirm changes
    ms010msp{i} = temp;
end

clear temp i;

%%
for i = 1:5
    SELECT =i; figure; hold on; plot((ms010msp{SELECT}(:,8)-1e3)/1e3); plot(ms010msp{SELECT}(:,5)); plot(ms010msp{SELECT}(:,2));
end

%% COMPUTE VALUES FROM DATA

x=zeros(NB_DS*NB_MAX, 1); % [rad/s] omega
x_var=zeros(NB_DS*NB_MAX, 1); % [rad/s] omega
y=zeros(NB_DS*NB_MAX, 1); % [m/rad] advance ratio wind/omega
t=zeros(NB_DS*NB_MAX, 1); % [Nm] thrust
t_var=zeros(NB_DS*NB_MAX, 1); % [Nm] variance of thrust
q=zeros(NB_DS*NB_MAX, 1); % [N] torque
q_var=zeros(NB_DS*NB_MAX, 1); % [N] variance of torque
for j = 1:NB_DS
    
    SELECT = j;
    dataset = ms010msp{SELECT};

    % Calibrate ATI sensor for force and torque
    MASK = extract_vals(dataset(:,8), 1000, 1000);
    CALIB = mean(dataset(MASK,2:7), 1); % CALIB IS FALSE
    dataset(:,2:7) = dataset(:,2:7) - CALIB;

    % Compute data
    for i = 0:NB_MAX-1

        idx = (j-1)*NB_MAX+1+i;
        
        if i==0
            MASK = extract_vals(dataset(:,8), 1000, 1000);
        else
            MASK = extract_vals(dataset(:,8), 1000+i*100, 200);
        end

        trust = rms(dataset(MASK,2:4), 2);
        torque = rms(dataset(MASK,5:7), 2);

        % compute values
        x(idx)=mean(dataset(MASK,9), 1); % [rad/s] omega
        x_var(idx)=var(dataset(MASK,9), 1);
        y(idx)=meta{j}{6}/x(idx); % [m/rad] w/omega
        t(idx)=mean(trust, 1); % [N] thrust
        t_var(idx)=var(trust, 1);
        q(idx)=mean(torque, 1); % [Nm] torque
        q_var(idx)=var(torque, 1);
        
        % verify mask position and data detrending
%         figure("Name", "Data overview and mask alignement @ "+meta{j}{6}+" [m/s] wind @ " +num2str(i*10)+"% throttle", "NumberTitle", "off");
%         hold on; plot(dataset(:,2:7)./max(abs(dataset(:,2:7)))); plot(MASK); ylabel("Amplitude"); xlabel("Samples"); xlim([0 length(dataset)]);

    end
end

%% ADD ADDITIONNAL DATA
% TODO

%% PLOT DATA BEFORE PROCESSING
u=0:10:80;

% visualise all data
figure("Name", "Torque as function of propeller speed and advance ratio (100% ws = 12.0 [m/s])", "NumberTitle", "off");
hold on;
for j = 1:NB_DS
    idx=(j-1)*NB_MAX+1:(j)*NB_MAX;
    scatter3(x(idx), y(idx), t(idx));
end
xlabel('Propeller speed [rad/s]'); 
ylabel('Advance ratio [m/rad]');
zlabel('Thrust [N]');
legend("53% ws", "80% ws", "90% ws", "100% ws", "0% ws", "Location", "best");
grid on;

% wind speed influence
fitType = {'x'};
reg_ws = fit(u(1:end-2)', x(end-NB_MAX+1:end-2), fitType);

figure("Name", "Influence of wind conditions on propeller speed (100% ws = 12.0 [m/s])", "NumberTitle", "off");
hold on;
for i = 1:NB_DS
    idx = (1:NB_MAX)+(i-1)*NB_MAX;
    errorbar(u, x(idx), x_var(idx));
end
plot(reg_ws, '--');
plot(u(1:end)', reg_ws(u(1:end))-[x(end-NB_MAX+1:end-2); x(NB_MAX-1:NB_MAX)]);
ylabel('Propeller speed [rad/s]'); 
xlabel('Throttle [%]');
legend("53% ws", "80% ws", "90% ws", "100% ws", "0% ws", "Location", "best");
grid on;

%% FIT DATA TO MODEL
% remove 0% wind speed values
x=x(1:end-NB_MAX);
x_var=x_var(1:end-NB_MAX);
y=y(1:end-NB_MAX);
t=t(1:end-NB_MAX);
t_var=t_var(1:end-NB_MAX);
q=q(1:end-NB_MAX);
q_var=q_var(1:end-NB_MAX);

fitType = {'x', 'y'}; % linear fit in x and y

% force
figure("Name", "Force", "NumberTitle", "off");
[sf_t, gdn_t] = fit([x.^2, y.*x.^2], t, fitType);
plot(sf_t, [x.^2, y.*x.^2], t);
xlabel('\omega^2 [rad/s]^2'); 
ylabel('J \cdot \omega^2 [m\cdots/rad3]');
zlabel('thrust [N]');

% torque
figure("Name", "Torque", "NumberTitle", "off");
[sf_q, gdn_q] = fit([x.^2, y.*x.^2], q, fitType);
plot(sf_q,[x.^2, y.*x.^2], q);
xlabel('\omega^2 [rad/s]'); 
ylabel('J \cdot \omega^2 [m\cdots/rad3]');
zlabel('Torque [Nm]');

%% MAKE NICE PLOTS
load('model/params.mat');
CT0 = sf_t.a;
CT1 = sf_t.b;
CQ0 = sf_q.a;
CQ1 = sf_q.b;
save('model/params.mat','Td', 'Bf', 'Ra', 'Ke', 'Jt', 'La', 'CT0', 'CT1', 'CQ0', 'CQ1', '-double');
[X,Y] = meshgrid(0:50:1200,0:5e-3:0.1);

% thrust
figure("Name", "Thrust model with fitted data", "NumberTitle", "off");
hold on;
grid on; 
Z = CT0*X.^2 + CT1*Y.*X.^2;
surf(X, Y, Z);
scatter3(x, y, t, 'MarkerEdgeColor', '#EDB120', 'MarkerFaceColor', '#EDB120');
xlabel('\omega [rad/s]'); 
ylabel('J [m/rad]');
zlabel('Thrust [N]');

% torque
figure("Name", "Torque model with fitted data", "NumberTitle", "off");
Z = CQ0*X.^2 + CQ1*Y.*X.^2;
hold on;
grid on; 
surf(X, Y, Z);
scatter3(x, y, q, 'MarkerEdgeColor', '#D95319', 'MarkerFaceColor', '#D95319');
xlabel('\omega [rad/s]'); 
ylabel('J [m/rad]');
zlabel('Torque [Nm]');