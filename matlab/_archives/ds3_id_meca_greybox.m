%% INITIALISATION
clc;
clear;
close all;

% add paths
work_dir = pwd;
idx = strfind(work_dir, '\');
addpath(work_dir(1:idx(end-1))+"\_data\2022.05.15_logs");
addpath(work_dir(1:idx(end-1))+"\_data\2022.05.23_logs");
addpath(work_dir(1:idx(end-1))+"\matlab\functions");
addpath(work_dir(1:idx(end-1))+"\matlab\simulink_model");

% set figures parameters
set(groot, "DefaultAxesFontSize", 10);
set(groot, "DefaultLineLineWidth", 1.5);

%% COMPUTE MODDEL
syms Ra La Jm Bf Ke Jl Jt;
syms z zi TE;

GAMMA1 = Ke/(Ra*Bf+Ke*Ke);
TAU1 = (Ra*Jm+La*Bf)/(Ra*Bf+Ke*Ke);
TAU2 = Jm*La/(Ra*Bf+Ke*Ke);

GAMMA2 = 1/Ke;
TAU3= Ra*Jm/Ke/Ke;

z = 1/zi; % zi is z inverse 1/z
s = TE/2*(z-1)/(z+1); % tustin discretisation

% first order model
[num, den] = numden(GAMMA2/(TAU3*s+1));
num = collect(num, zi);
den = collect(den, zi);
Gm1 = num/den;
disp(Gm1);

% seconde order model
[num, den] = numden(GAMMA1/(TAU2*s^2+TAU1*s+1));
num = collect(num, zi);
den = collect(den, zi);
Gm2 = num/den;
disp(Gm2);

%% OPEN DATA
SELECT = 5;
NB_POLES = 17; % value from ds3_bemf_coeff

% select data and add metadata
meta{1} = {"output_2022-05-15_12-58-16_rpm-tests10-20.log", [1 0], 0.01, [16.72, 16.58]};
meta{2} = {"output_2022-05-15_14-39-22_rpm-tests-25-40.log", [1 0], 0.01, [16.59, 15.98]};
meta{3} = {"output_2022-05-15_15-17-15-motor-voltage.log", [1 0], 0.01, [16.00, 15.90]};
meta{4} = {"output_2022-05-15_16-39-40-prbs1.log", [2500 2000], 0.01, [15.82, 15.75]};
meta{5} = {"output_2022-05-15_16-47-21-prbs2.log", [600 300], 0.02, [15.75, 15.66]};
meta{6} = {"output_2022-05-15_16-59-29-battery-test2.log", [1 0], 0.01, [15.69, 15.16]};

% read data
temp = readmatrix(meta{SELECT}{1});
temp(:, 2)=temp(:, 2); % duty cycle
temp(:, 3)=temp(:, 3); % [Hz]
temp = temp(meta{SELECT}{2}(1):end-meta{SELECT}{2}(2), :);

[un, MU, GU] = normalize(temp(:,2), 'center', 'mean' , 'scale', 'std');
[yn, MY, GY] = normalize(temp(:,3), 'center', 'mean' , 'scale', 'std');
u = temp(:,2);
y = temp(:,3);
TE = meta{SELECT}{3};
NLGTH=length(u);

%% PERIODICITY CHECK
% if not peridioc, estimate of correlation
[Ruu, lags] = xcorr(un, 'biased');
Ryu = xcorr(yn, un, 'biased');
%plot
figure('Name','Estimate of correlation','NumberTitle','off');
stem([Ryu(NLGTH:end) Ruu(NLGTH:end)]);
legend('Ruu', 'Ryu');

% Check for periodicity
threshold = 10*mean(abs((rmoutliers(Ruu))));
[pk_size, pk_loc] = findpeaks(Ruu, 'MinPeakHeight', threshold);
PLGTH = mean(diff(pk_loc));
PNB = (length(pk_loc)+1)/2;
% plot
figure('Name','Find periodicity','NumberTitle','off');
hold on;
plot(lags, Ruu);
plot(lags(pk_loc), pk_size, 'vk', 'color', 'r')
legend('Autocorrelation', 'periodicity : '+string(PLGTH)+'x'+string(PNB));

%% DATA PREPARATION AND SEPARATION
zt=iddata(y, u, TE); % total set
set(zt, 'InputName', 'Throttle duty cycle', 'OutputName', 'RPM sensor signal', 'InputUnit', 'us', 'OutputUnit', 'Hz');

if PNB>1
    if PLGTH*PNB ~= NLGTH
        PNB = PNB-1;
        NLGTH = PLGTH*(PNB);
    end
    figure('Name','Check data periodicity and noise','NumberTitle','off');
    plot(reshape(yn(1:PLGTH*(PNB)), [], PNB));
    xlim([0 PLGTH]);
    legend;
    xlabel("Time [samples]");
    ylabel("Amplitude [-]");
end

% separate training and validation sets 
CUT = round(2/3)*NLGTH;
zi = detrend(zt([1:CUT]),0); % identification set
zv = detrend(zt([CUT+1:end]),0); % validation set

uv=u(CUT+1:end);
yv=y(CUT+1:end);

w =(0:(PLGTH-1))*2*pi/(TE*PLGTH);

%% IDENTIFICATION
% systemIdentification;
          
Opt = procestOptions;            
model_o1 = procest(zi, 'P1D', Opt);
present(model_o1);
model_o2 = procest(zi, 'P2DU', Opt);
present(model_o2);

figure('Name','Compare models to data','NumberTitle','off');
compare(zv, model_o1, model_o2);

%% TEST
% model 1
t=(0:(length(uv)-1))*TE;
yhat_o1a = lsim(model_o1, uv-MU, t);

figure; 
hold on;
plot(t, yhat_o1a+MY);
plot(t, yv);
legend("yhat", "y");

% model 2
t=(0:(length(uv)-1))*TE;
yhat_o2a = lsim(model_o2, uv-MU, t);

figure; 
hold on;
plot(t, yhat_o2a+MY);
plot(t, yv);
legend("yhat", "y");

%% COMPUTE AND SAVE PARAMETERS
load('params.mat');
% preliminary values
Bf = 1e-4;
Jl = 10*1/3*20.12e-3*(6.35e-3)^2;
Ra = 1;

Td = model_o2.Td;

% solve order 2
Ke = 1/model_o2.Kp;
Jm = model_o2.Zeta*model_o2.Tw*Ke^2/Ra;
La = model_o2.Tw^2*Ke^2/Jm;
Jt = Jm + Jl;

save('params.mat', 'Td', 'Bf', 'Ra', 'Ke', 'Jt', 'La', 'CT0', 'CT1', 'CQ0', 'CQ1', '-double');

%% VERIFY
SELECT = 2;
% compare bode plots
s = tf('s');
% compare in time domain
temp = readmatrix(meta{SELECT}{1});
temp(:, 2)=(temp(:, 2)-1000)/1000*(meta{SELECT}{4}(1)+meta{SELECT}{4}(1))/2; % volt
temp(:, 3)=temp(:, 3)*NB_POLES/2*(2*pi/60); % rad/s
temp = temp(meta{SELECT}{2}(1):end-meta{SELECT}{2}(2), :);

TE = meta{SELECT}{3};
u=temp(:,2);
y=temp(:,3);
t=(0:length(u)-1)*TE;

%% verify order 2 model
Gapprox_o2 = eval(GAMMA1)/(eval(TAU2)*s^2+eval(TAU1)*s+1)*exp(-Td*s);
Gsim_o2 = Ke/(La*s+Ra)/(Jm*s+Bf)/(1+Ke^2/(La*s+Ra)/(Jm*s+Bf))*exp(-Td*s);
% plot
figure; hold on; bode(model_o2); bode(Gapprox_o2); bode(Gsim_o2); legend;

yhat_o2a=lsim(Gapprox_o2, u(:), t(:));
yhat_o2s=lsim(Gsim_o2, u(:), t(:));
% plot
figure; hold on; plot(t, y); plot(t, yhat_o2a); plot(t, yhat_o2s); legend("data", "model app", "model sim"); ylim([0 1000]);


%% verify first order model
% solve first order
Td = model_o1.Td;
Ke = 1/model_o2.Kp;

Jm = model_o1.Tp1*Ke^2/Ra;
Gapprox_o1 = eval(GAMMA2)/(eval(TAU3)*s+1)*exp(-Td*s);
Gsim_o1 = Ke/Ra/Jm/s/(1+Ke^2/Ra/Jm/s)*exp(-Td*s);
% plot
figure; hold on; bode(model_o1); bode(Gapprox_o1); bode(Gsim_o1); legend;

yhat_o1a=lsim(Gapprox_o1, u(:), t(:));
yhat_o1s=lsim(Gsim_o1, u(:), t(:));
% plot
figure; hold on; plot(t, y); plot(t, yhat_o1a); plot(t, yhat_o1s); legend("data", "model app", "model sim"); ylim([0 1000]);