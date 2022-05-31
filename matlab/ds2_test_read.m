%% INITIALISATION
clc;
clear;
close all;

% add paths
work_dir = pwd;
idx = strfind(work_dir, '\');
addpath(work_dir(1:end)+"\functions");
addpath(work_dir(1:end)+"\2022.05.15_logs");

% add flags
save_figs = false;

% set figures parameters
set(groot, "DefaultAxesFontSize", 10);
set(groot, "DefaultLineLineWidth", 1.5);

%% OPEN DATA
select = 7;

meta{1} = {"output_2022-04-28_18-50-09_motor-test.log", 1};
meta{2} = {"output_2022-04-28_19-17-01_r60%_w0%.log", 1};
meta{3} = {"output_2022-04-28_19-17-01_r60%_w50%.log", 1};
meta{4} = {"output_2022-04-28_19-17-01_r60%_w100%.log", 1};
meta{5} = {"output_2022-04-29_17-19-40_w0_70.log", 1};
meta{6} = {"output_2022-04-29_17-21-38_w0_80.log", 1};
meta{7} = {"output_2022-04-29_17-26-21_w0_90.log", 1};
meta{8} = {"output_2022-04-29_17-35-20_w0_upto60.log", 1};
meta{9} = {"output_2022-04-29_17-40-31w50_upto80.log", 1};
meta{10} = {"output_2022-04-29_17-46-37_w80_upto80.log", 1};
meta{11} = {"output_2022-04-29_17-51-59_w90_upto80.log", 1};
meta{12} = {"output_2022-04-29_17-57-19_w100_upto80.log", 1};

% remove outliers
temp = readmatrix(meta{select}{1});
temp(:, 3) = filloutliers(temp(:, 3),'linear', 'movmedian', 50);

% compute mean
mask = extract_vals(temp(:,2), max(temp(:, 2)), 6);
avg = mean(temp(mask,3), 1);
disp(avg);

figure;
yyaxis left;
plot(temp(:,2));
ylim(1.1*[0 max(temp(:,2))]);
yyaxis right;
plot(temp(:,3));