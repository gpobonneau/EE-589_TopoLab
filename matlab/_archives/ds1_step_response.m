%% INITIALISATION
clc;
clear;
close all;

% add paths
work_dir = pwd;
idx = strfind(work_dir, '\');
addpath(work_dir(1:idx(end-1))+"\_data\2022.03.25_logs");
addpath(work_dir(1:idx(end-1))+"\matlab\functions");

run_sim = true;
save_figs = false;

% set figures parameters
set(groot, "DefaultAxesFontSize", 15);
set(groot, "DefaultLineLineWidth", 1.5);

%% PREPROCESSING DATA
% read files
ms010msp007_force = readmatrix('2022.03.25_logs/MS010MPT007_NIDAQ USB-6210_31683603.csv');
ms010msp007_force(:, 4:end) = volt2load_ati(ms010msp007_force); %convert from voltages to loads

% visual analysis
fig1 = figure("Name", "raw transduced", "NumberTitle", "off");
plot(ms010msp007_force(:,1), ms010msp007_force(:,4:6));

% split data
split = 3200;
ms010msp007_force_cal = ms010msp007_force(1:split,:);
ms010msp007_force_data = ms010msp007_force(split+1:end,:);

% compute thrust by removing bias
fig2 = figure("Name", "Force", "NumberTitle", "off");
force_mag = rms(ms010msp007_force_data(:,4:6) - mean(ms010msp007_force_cal(:,4:6),1),2);
% force_mag = smooth(force_mag);
plot(force_mag);
xlabel('samples (-)');
ylabel('thrust (N)');

% extract unique steps
split = 2700;
step_a = force_mag(1:split);
step_b = force_mag(split+1:end);

%% ANALYSIS
% select impulse
y = step_b;
NLGTH = length(y); % signal length in samples
YMAX = max(abs(y));
TE = 1/120; % sampling period
TF = (NLGTH-1)*TE; % Final time of the data
P_NB = 1; % period numbers un the data
t = 0:TE:TF;
w = 1/TE*(0:(NLGTH/2))/NLGTH; % omega frequency vector
% misc
P_LGTH = NLGTH;

u = zeros(1, NLGTH).';
u_start = 400;
u_len = 10/TE;
u(u_start:u_start+u_len) = 1200;

% Time domain plot
fig3 = figure("Name", "Time domain", "NumberTitle", "off");
hold on;
yyaxis left;
plot(t, y);
yyaxis right;
plot(t, u);

% Frequency domain
figure('Name','Frequency content','NumberTitle','off');
% first figure
subplot(2,1,1);
temp = abs(fft(u));
temp = temp(1:(NLGTH-1)/2+1); % temp = temp(1:fix((NLGTH-1)/2)+2);
temp(2:end-1) = 2*temp(2:end-1);
plot(w, temp);
ylim([0 1.1*max(temp)]);
xlabel('rad/s');
title('Input signal');
grid on;
% second figure
subplot(2,1,2);
temp = abs(fft(y));
temp = temp(1:(NLGTH-1)/2+1); % temp = temp(1:fix((NLGTH-1)/2)+2);
temp(2:end-1) = 2*temp(2:end-1);
plot(w, temp);
ylim([0 1.1*max(temp)]);
xlabel('rad/s');
ylabel('amplitude');
title('Output signal');
grid on;

figure('Name','Bode plot','NumberTitle','off');
hold on;

% Fourier transform analysis (WAIT FOR TRANSIENT TO END)
U1=fft(u);
Y1=fft(y);
g=Y1(1:P_NB:end)./U1(1:P_NB:end); % keep every nth sample
Gf=idfrd(g(1:(P_LGTH-1)/2), w(1:(P_LGTH-1)/2), TE);
bode(Gf);

% Spectral analysis with windowing
WINLGTH = 1500; % motivate this choice
fen=hann(2*WINLGTH);

Ruu = xcorr(u, 'unbiased');
Ryu = xcorr(y, u, 'unbiased');

Ruuw=Ruu(1:P_LGTH).*[fen(WINLGTH+1:2*WINLGTH); zeros(P_LGTH-WINLGTH,1)];
Ryuw=Ryu(1:P_LGTH).*[fen(WINLGTH+1:2*WINLGTH); zeros(P_LGTH-WINLGTH,1)];
phi_uu=fft(Ruuw);
phi_yu=fft(Ryuw);
gs=phi_yu./phi_uu;
Gs=idfrd(gs(1:(P_LGTH-1)/2), w(1:(P_LGTH-1)/2), TE);
bode(Gs);

%% SAVING FIGURES
if save_figs == true
    saveas(figX, 'figures/X','epsc');
end

% fig_name = sprintf('coil_d%.1f_l%.1f.bmp', coil_dext*10^3, coil_len*10^3);
% path = strcat(pwd, '\figures\', fig_name);