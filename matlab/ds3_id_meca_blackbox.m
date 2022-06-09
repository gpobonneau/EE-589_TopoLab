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
ground_truth = readmatrix(meta{SELECT}{1});
ground_truth = ground_truth(meta{SELECT}{2}(1):end-meta{SELECT}{2}(2), :);
% estimation of battery voltage during experiment extrapolated from measured data
ground_truth(:, 2)=(ground_truth(:, 2)-1000)/1000.*linspace(meta{SELECT}{4}(1), meta{SELECT}{4}(2), length(ground_truth))'; % volt

% remove trends and scale data to avoid numerical errors
if mod(length(ground_truth), 2) == 1 % use even nb of points
    [u, MU, GU] = normalize(ground_truth(2:end,2), 'center', 'mean', 'scale', 'std');
    [y, MY, GY] = normalize(ground_truth(2:end,3), 'center', 'mean', 'scale', 'std');
%     u=temp(2:end,2);
%     y=temp(2:end,3);
else
    [u, MU, GU] = normalize(ground_truth(:,2), 'center', 'mean', 'scale', 'std');
    [y, MY, GY] = normalize(ground_truth(:,3), 'center', 'mean', 'scale', 'std');
%     u=temp(:,2);
%     y=temp(:,3);
end

% create time vector
NLGTH = length(u); % signal length in samples
UMAX = max(abs(u));
YMAX = max(abs(y));
TE = meta{SELECT}{3}; % sampling period
TF = (NLGTH-1)*TE; % Final time of the data
t = 0:TE:TF;

% plot
figure('Name','Plot whole data','NumberTitle','off');
yyaxis left;
plot(ground_truth(:,2));
ylim([0 max(ground_truth(:,2))]*1.1);
ylabel("voltage [V]");
yyaxis right;
plot(ground_truth(:,3));
ylim([0 max(ground_truth(:,3))]*1.1);
ylabel("\omega [rad/s]");
xlabel("samples");

%% Plot data
% TIME DOMAIN
figure('Name','Data','NumberTitle','off');
% first figure
subplot(3,1,1);
plot([u,y]);
xlim([0 NLGTH]);
xlabel('samples');
ylabel('data');
legend('u', 'y');
% second figure
subplot(3,1,2);
stairs(t,u);
xlabel('Time (s)')
ylabel('Input Signal')
xlim([NLGTH/2*TE (NLGTH/2+300)*TE]); % plot 300 samples in the middle of the data
ylim([-1.1*UMAX 1.1*UMAX]);
% second figure
subplot(3,1,3);
stairs(t, y);
xlabel('Time (s)')
ylabel('Output Signal')
xlim([NLGTH/2*TE (NLGTH/2+300)*TE]); % plot 300 samples in the middle of the data
ylim([-1.1*YMAX 1.1*YMAX]);

% FREQUENCY DOMAIN
figure('Name','Frequency content','NumberTitle','off');
w = (0:NLGTH/2)/TE/NLGTH; % omega frequency vector
% first figure
subplot(2,1,1);
temp = abs(fft(u)/NLGTH);
temp = temp(1:NLGTH/2+1);
temp(2:end-1) = 2*temp(2:end-1);
f_max = max(temp);
plot(w, temp, 'Linewidth', 1.5);
ylim([0 1.1*f_max]);
xlabel('rad/s');
title('Input signal');
grid on;
% second figure
subplot(2,1,2);
temp = abs(fft(y)/NLGTH);
temp = temp(1:NLGTH/2+1);
temp(2:end-1) = 2*temp(2:end-1);
f_max = max(temp);
plot(w, temp, 'Linewidth', 1.5);
ylim([0 1.1*f_max])
xlabel('rad/s')
title('Output signal');
grid on; 

%% Periodicity check
% if not peridioc, estimate of correlation
[Ruu, lags] = xcorr(u-mean(u), 'biased');
Ryu = xcorr(y-mean(y), u-mean(u), 'biased');
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

%% Data preparation and separation
if PLGTH*PNB ~= NLGTH
    PNB = PNB-1;
    u = u(1:PLGTH*(PNB));
    y = y(1:PLGTH*(PNB));
    NLGTH = PLGTH*(PNB);
end

figure('Name','Check data periodicity and noise','NumberTitle','off');
plot(reshape(y, [], PNB));
xlim([0 PLGTH]);
legend;
xlabel("Time [samples]");
ylabel("Amplitude [-]");

CUT = floor(2/3*PNB)*PLGTH;

% separate training and validation sets 
ui=u(1:CUT);
uv=u(CUT+1:end);
yi=y(1:CUT);
yv=y(CUT+1:end);

zi=iddata(yi, ui, TE);
zv=iddata(yv, uv, TE);
zt=iddata(y, u, TE);

set(zt, 'InputName', 'Throttle duty cycle', 'OutputName', 'RPM sensor signal', 'InputUnit', 'us', 'OutputUnit', 'Hz');
w = (0:(PLGTH-1))*2*pi/(TE*PLGTH);

%% FREQUENCY ANALYSIS
% Fourier transform analysis (ideal for periodic signals)
U1=fft(uv);
Y1=fft(yv);
PNB_V=length(yv)/PLGTH;
gf=Y1(1:PNB_V:end)./U1(1:PNB_V:end); % keep every nth sample
Gf=idfrd(gf(1:(PLGTH-1)/2), w(1:(PLGTH-1)/2), TE);
 
% Spectral analysis (ideal for random signals)
Gs = spa(zt, []);

% plots
figure('Name','Bode plot from fourrier and spectral analysis','NumberTitle','off');
hold on;
bodeplot(Gf); % h=bodeplot(Gf); showConfidence(h,2);
bodeplot(Gs); % h=bodeplot(Gs); showConfidence(h,2);
legend("Fourrier analysis", "Spectral analysis", "Location", "best");

%% Order estimation
% arx is used as is made by solving a least square probleme, ensuring "decroissance monotone"
N_MAX = 10;
clear C;
C=zeros(N_MAX, 1); % size allocation
for i=1:N_MAX
    model_arx=arx(zt, [i, i, 1]);
    C(i)=model_arx.estimationInfo.LossFcn;
end

figure('Name','Loss function','NumberTitle','off');
plot(C);
xlabel("Order of Autoregressive model with Extra Input");
ylabel("Loss [-]");

%% Zero/Pole cancellation

N_MIN = 4;
N_MAX = 7;

for i=N_MIN:N_MAX
    model_armax=armax(zt, [i,i,i,1]);
    figure('Name','Pole-Zero map','NumberTitle','off');
    h=iopzplot(model_armax);
    showConfidence(h, 2);
    axis(2*[-1 1 -1 1])
    title('Zero/Pole map for order ' + string(i));
    axis equal;
end

%% Delay identification
% count number of zero values for k~=1 to estimate NK
N = 5;
model_oe=oe(zt, [N N 1]); 

figure('Name','Delay identification','NumberTitle','off');
hold on;
errorbar(model_oe.b, 2*model_oe.db);
yline(0);
disp([model_oe.b ; 2*model_oe.db]);
xlabel("Ouput Error model coefficient order");
ylabel("Value of coefficient");

%% Estimation of nb & na
NK = 1;

clear C;
C=zeros(N, N-NK+1); % size allocation
for NA=1:N
    for NB=1:N-NK+1
        model_arx=arx(zt, [NA, NB, NK]);
        C(NA, NB)=model_arx.estimationInfo.LossFcn;
    end
end

figure
plot(C);
legend('nb=1', 'nb=2', 'nb=3', 'nb=4', 'nb=5'); %, 'nb=6');
xlabel('Autoregressive na model order');
ylabel('Loss [-]');
%% Compare with matlab order estimations
% m = NK + NB; n = NA; 1 <= NB <= N-NK+1
NA=3;
NB=5;

nn = struc(1:20, 1:20, 1:10);
v = arxstruc(zt, zt, nn);
% selstruc(v);
%% Parametric identification
NC=N; ND=N; NF=N;

model_arx = arx(zi, [NA NB NK]);
model_armax = armax(zi, [NA NB NC NK]);
model_iv4 = iv4(zi,[NA NB NK]);
model_oe = oe(zi,[NB NF NK]);
model_bj = bj(zi,[NB NC ND NF NK]);
model_ss = n4sid(zi, N); % ssest(zi);

%% Model validation
figure;
compare(zv, model_arx, model_armax, model_iv4, model_oe, model_bj, model_ss);
ylim(([0.9*min(yv) 1.1*max(yv)]));

figure;
compare(Gf, model_arx, model_armax, model_iv4, model_oe, model_bj, model_ss, Gs);

%% Statistical model validation

figure;
resid(zv, model_arx);
title('ARX');

figure;
resid(zv, model_armax);
title('ARMAX');

figure;
resid(zv, model_iv4);
title('IV4');

figure;
resid(zv, model_oe);
title('OE');

figure;
resid(zv, model_bj);
title('BJ');

figure;
resid(zv, model_ss);
title('SS');
