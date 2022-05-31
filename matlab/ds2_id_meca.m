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
SELECT = 4;

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
    temp = temp(meta{i}{4}(1):end-meta{i}{4}(2),:);
    
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
load('model/params.mat');
dataset = ms010msp{SELECT};

MASK = extract_vals(dataset(:,8), 1000, 1000);

u =  (dataset(:, 8)-1e3)/1e3;
w = dataset(:, 9);
j = meta{SELECT}{6}./w;
qe1 = rms(dataset(:,5:7), 2)-mean(rms(dataset(MASK,5:7), 2)); % measured torque 
qe2 = -(CQ0*w(:).^2 + CQ1*j(:).*w(:).^2); % torque applied on motor
qe2 = qe2 - mean(qe2(MASK));
% qm = qtot(:) + qe; % torque produced by motor

plot(dataset(:,1), [qe1(:), qe2(:), u(:)]); legend("data", "model", "u"); xlabel("time"); ylabel("amplitude");

%% systemIdentification
CUT = round(2/3*length(u));
zd=iddata(u(:), qe1(:), ATI_TS);
zdi=zd([1:CUT]);
zdv=zd([CUT+1:end]);

np = 2;                                                    
nz = 1;                                                    
num = arrayfun(@(x)NaN(1,x), nz+1,'UniformOutput',false);  
den = arrayfun(@(x)[1, NaN(1,x)],np,'UniformOutput',false);

% Prepare input/output delay                               
iodValue = 0;                                              
iodFree = true;                                            
iodMin = 0;                                                
iodMax = 0.25;                                         
sysinit = idtf(num, den, 0);                               
iod = sysinit.Structure.ioDelay;                           
iod.Value = iodValue;                                      
iod.Free = iodFree;                                        
iod.Maximum = iodMax;                                      
iod.Minimum = iodMin;                                      
sysinit.Structure.ioDelay = iod;                           

% Perform estimation using "sysinit" as template           
tf1 = tfest(zdi, sysinit);

%% VALIDATION
figure;
compare(zdv, tf1);

figure;
compare(zdi, tf1);

figure;
resid(zdv, tf1);
present(tf1);
