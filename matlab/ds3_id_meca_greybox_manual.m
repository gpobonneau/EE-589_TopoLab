%% INITIALISATION
clc;
clear;
close all;

% add paths
work_dir = pwd;
idx = strfind(work_dir, '\');
addpath(work_dir(1:end)+"\functions");
addpath(work_dir(1:end)+"\2022.05.15_logs");

% set figures parameters
set(groot, "DefaultAxesFontSize", 10);
set(groot, "DefaultLineLineWidth", 1.5);

%% INITIAL GUESS
load('model/params.mat');
NB_POLES = 17; % value from ds3_bemf_coeff

INI_Ra=Ra;      % [Ohm]
RGE_Ra=10;
INI_La=La;      % [H]
RGE_La=10;
INI_Jm=Jt;      % [kgm^2]
RGE_Jm=10;
INI_Bf=Bf;      % [-]
RGE_Bf=10;
INI_Ke=Ke;        % [rad/(Vs)] 
RGE_Ke=10;

syms Ra La Jm Bf Ke Jl Jt;

TAU1 = (Ra*Jm+La*Bf)/(Ra*Bf+Ke*Ke);
TAU2 = Jm*La/(Ra*Bf+Ke*Ke);
GAMMA1 = Ke/(Ra*Bf+Ke*Ke);

TAU3 = 1/Ke;
GAMMA2 = Ra*Jm/Ke*Ke;

%% COMPUTE MODDEL
syms z zi TE;

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

% select data and add metadata
meta{1} = {"output_2022-05-15_12-58-16_rpm-tests10-20.log", [1 0], 0.01, [16.72, 16.58]};
meta{2} = {"output_2022-05-15_14-39-22_rpm-tests-25-40.log", [1 0], 0.01, [16.59, 15.98]};
meta{3} = {"output_2022-05-15_15-17-15-motor-voltage.log", [1 0], 0.01, [16.00, 15.90]};
meta{4} = {"output_2022-05-15_16-39-40-prbs1.log", [2500 2000], 0.01, [15.82, 15.75]};
meta{5} = {"output_2022-05-15_16-47-21-prbs2.log", [600 300], 0.02, [15.75, 15.66]};
meta{6} = {"output_2022-05-15_16-59-29-battery-test2.log", [1 0], 0.01, [15.69, 15.16]};

% read data
temp = readmatrix(meta{SELECT}{1});
temp(:, 2)=(temp(:, 2)-1000)/1000*(meta{SELECT}{4}(1)+meta{SELECT}{4}(1))/2; % volt
temp(:, 3)=temp(:, 3)*NB_POLES/2*(2*pi/60); % rad/s
temp = temp(meta{SELECT}{2}(1):end-meta{SELECT}{2}(2), :);

[u, MU, GU] = normalize(temp(:,2), 'center', 'mean', 'scale', 'std');
[y, MY, GY] = normalize(temp(:,3), 'center', 'mean', 'scale', 'std');
TE = meta{SELECT}{3};

% plot
figure;
yyaxis left;
plot(temp(:,2));
ylim([0 max(temp(:,2))]*1.1);
ylabel("Voltage [V]");
yyaxis right;
plot(temp(:,3));
ylim([0 max(temp(:,3))]*1.1);
ylabel("\omega [rad/s]");
xlabel("samples");

%% FIT MODEL TO DATA
MODEL = 2; % select model 1, 2 or 3
clear temp;

% initialisation
temp{4} = -inf;
t = (0:length(u)-1)*meta{SELECT}{3};

% fit
for DELAY = 0:20
    
    if MODEL == 1          % Ra    Jm    Ke   
        err = @(x) costcalc4(x(1), x(2), x(3), DELAY, u, y, TE);
        X0 = [INI_Ra, INI_Jm, INI_Ke, INI_Ke];
        ub = X0.*[RGE_Ra, RGE_Jm, RGE_Ke, RGE_Ke];
        lb = X0./[RGE_Ra, RGE_Jm, RGE_Ke, RGE_Ke];
        [x, fval] = fmincon(err, X0, [], [], [], [], lb, ub);
        % [x, fval] = fmincon(err, x0);
        Gd = tf([zeros(1, DELAY), 2*x(1)*x(2)*x(4), 2*x(1)*x(2)*x(4)], [2*x(3)+TE, 2*x(3)-TE], TE, 'variable','z^-1');
    elseif MODEL == 2      % Ra    La    Jm    Bf    Ke  
        err = @(x) costcalc5(x(1), x(2), x(3), x(4), x(5), DELAY, u, y, TE);
        X0 = [INI_Ra, INI_La, INI_Jm, INI_Bf, INI_Ke, INI_Ke];
        ub = X0.*[RGE_Ra, RGE_La, RGE_Jm, RGE_Bf, RGE_Ke, RGE_Ke];
        lb = X0./[RGE_Ra, RGE_La, RGE_Jm, RGE_Bf, RGE_Ke, RGE_Ke];
        [x, fval] = fmincon(err, X0, [], [], [], [], lb, ub);
        % [x, fval] = fmincon(err, X0);
        Gd = tf([zeros(1, DELAY), 4*x(5), 8*x(5), 4*x(5)], [4*x(4)*x(1) + 4*x(5)*x(6) + 2*x(4)*x(2)*TE + 2*x(3)*x(1)*TE + x(3)*x(2)*TE^2, - 2*x(3)*x(2)*TE^2 + 8*x(4)*x(1) + 8*x(5)*x(6), 4*x(4)*x(1) + 4*x(5)*x(6) - 2*x(4)*x(2)*TE - 2*x(3)*x(1)*TE + x(3)*x(2)*TE^2], TE, 'variable','z^-1');
    elseif MODEL == 3      % a0    a1    a2    b0    b1    b2
        err = @(x) costcalc6(x(1), x(2), x(3), x(4), x(5), x(6), DELAY, u, y);
        X0 = ones(1,6);
        [x, fval] = fmincon(err, X0);
        Gd = tf([zeros(1, DELAY), x(4:6)], x(1:3), meta{SELECT}{3}, 'variable','z^-1');
    end
    
    % computations
    yhat = lsim(Gd, u, t);
    fit = 100*(1-norm(y-yhat)/norm(y-mean(y)));

    if fit > temp{4}
        temp = {Gd, x, DELAY, fit};
    end
    
    % plot
    figure("Name", "Delay = "+DELAY, "NumberTitle", "off");
    yyaxis left;
    stairs(t, yhat);
    yyaxis right;
    stairs(t, y);
    xlim([40 60]);
    legend("Model yhat", "Data y");
end

%% PRESENT RESULT
Gd = temp{1};
x = temp{2};
DELAY = temp{3};
fit = temp{4};
disp(temp);
present(Gd);

fit = 100*(1-norm(y-yhat)/norm(y-mean(y)));

% plot
figure;
hold on;
stairs(t, yhat);
stairs(t, y);
legend("Model", "Measured data");

%% EXTRACT PARAMETERS
if MODEL==1
    Ra=x(1);
    Jm=x(2);
    Ke=x(3);
    Ke=x(4);
    Gc = tf([eval(subs(GAMMA2))], [eval(subs(TAU3)) 1]);
    yhatc = lsim(Gc, u, t);
elseif MODEL==2
    Ra=x(1);
    La=x(2);
    Jm=x(3);
    Bf=x(4);
    Ke=x(5);
    Ke=x(6);
    Gc = tf([eval(subs(GAMMA1))], [eval(subs(TAU2)) eval(subs(TAU1)) 1]); % eval
    yhatc = lsim(Gc, u, t);
elseif MODEL==3
    Gc = d2c(Gd, TE, 'tustin');
    yhatc = lsim(Gc, u, t);
end

% plot
figure; 
yyaxis left;
plot(t, yhatc);
yyaxis right;
plot(t, y);

%% COST FUNCTIONS
% First order model
function cost = costcalc4(Ra, Jm, Ke, d, u, y, TE)

    u=u(:);
    y=y(:);
    d=ceil(abs(d));

    phi = [-y(2:(end-d-1)) u(3+d:end) u(2+d:end-1)];
    theta = [2*Ke - TE; 2*Jm*Ke*Ra; 2*Jm*Ke*Ra;]/(2*Ke + TE);
    cost = norm(y(3:end-d) - phi*theta);
end

% Second order model
function cost = costcalc5(Ra, La, Jm, Bf, Ke, d, u, y, TE)

    u=u(:);
    y=y(:);
    d=ceil(abs(d));

    phi = [-y(2:(end-d-1)) -y(1:(end-d-2)) u(3+d:end) u(2+d:end-1) u(1+d:end-2)];
    theta = [- 2*Jm*La*TE^2 + 8*Bf*Ra + 8*Ke*Ke; 4*Bf*Ra + 4*Ke*Ke - 2*Bf*La*TE - 2*Jm*Ra*TE + Jm*La*TE^2; 4*Ke; 8*Ke ; 4*Ke]/(4*Bf*Ra + 4*Ke*Ke + 2*Bf*La*TE + 2*Jm*Ra*TE + Jm*La*TE^2);
    cost = norm(y(3:end-d) - phi*theta);
end

% Black box model
function cost = costcalc6(a0, a1, a2, b0, b1, b2, d, u, y)

    u=u(:);
    y=y(:);
    d=ceil(abs(d));

    phi = [-y(2:(end-d-1)) -y(1:(end-d-2)) u(3+d:end) u(2+d:end-1) u(1+d:end-2)];
    theta = [a1; a2; b0; b1; b2]./a0;
    cost = norm(y(3:end-d) - phi*theta);
end



