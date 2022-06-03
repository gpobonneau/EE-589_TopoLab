airspeed_8 = importdata("raw_data_campaign3/logs_AP/MS024MPT008_airspeed_validated_0.csv");
airspeed_9 = importdata("raw_data_campaign3/logs_AP/MS024MPT009_airspeed_validated_0.csv");
airspeed_10 = importdata("raw_data_campaign3/logs_AP/MS024MPT010_airspeed_validated_0.csv");

motor_8 = importdata("raw_data_campaign3/logs_AP/MS024MPT008_battery_status_0.csv");
motor_9 = importdata("raw_data_campaign3/logs_AP/MS024MPT009_battery_status_0.csv");
motor_10 = importdata("raw_data_campaign3/logs_AP/MS024MPT010_battery_status_0.csv");

time_8_AS = (airspeed_8.data(:,1)-airspeed_8.data(1,1))/1e6;
time_8_m = (motor_8.data(:,1)-motor_8.data(1,1))/1e6;
time_9_AS = (airspeed_9.data(:,1)-airspeed_9.data(1,1))/1e6;
time_9_m = (motor_9.data(:,1)-motor_9.data(1,1))/1e6;
time_10_AS = (airspeed_10.data(:,1)-airspeed_10.data(1,1))/1e6;
time_10_m = (motor_10.data(:,1)-motor_10.data(1,1))/1e6;

% figure
% plot((airspeed_8.data(:,1)-airspeed_8.data(1,1))/1e6,airspeed_8.data(:,2))
% hold on
% plot((motor_8.data(:,1)-motor_8.data(1,1))/1e6,(motor_8.data(:,3)-15)*10,'b')
% plot((airspeed_9.data(:,1)-airspeed_9.data(1,1))/1e6 + (airspeed_8.data(end,1)-airspeed_8.data(1,1))/1e6,airspeed_9.data(:,2),'r')
% plot((motor_9.data(:,1)-motor_9.data(1,1))/1e6 + (motor_8.data(end,1)-motor_8.data(1,1))/1e6 ,(motor_9.data(:,3)-15)*10,'r')
% plot((airspeed_10.data(:,1)-airspeed_10.data(1,1))/1e6 + (airspeed_9.data(end,1)-airspeed_9.data(1,1))/1e6 + (airspeed_8.data(end,1)-airspeed_8.data(1,1))/1e6,airspeed_10.data(:,2),'k')
% plot((motor_10.data(:,1)-motor_10.data(1,1))/1e6 + (motor_8.data(end,1)-motor_8.data(1,1))/1e6 + (motor_9.data(end,1)-motor_9.data(1,1))/1e6,(motor_10.data(:,3)-15)*10,'k')

load('/home/pasquale/Downloads/Telegram Desktop/ms010msp.mat')
data_ati_8_V = readmatrix("raw_data_campaign3/28and29_04_2022/MS024MPT008_NIDAQ USB-6210_31683603.csv");
data_ati_9_V = readmatrix("raw_data_campaign3/28and29_04_2022/MS024MPT009_NIDAQ USB-6210_31683603.csv");
data_ati_10_V = readmatrix("raw_data_campaign3/28and29_04_2022/MS024MPT010_NIDAQ USB-6210_31683603.csv");

data_ati_8 = data_ati_8_V;
data_ati_9 = data_ati_9_V;
data_ati_10 = data_ati_10_V;

data_ati_8(:,4:9)=Gamma_volt_to_load(data_ati_8_V);
data_ati_9(:,4:9)=Gamma_volt_to_load(data_ati_9_V);
data_ati_10(:,4:9)=Gamma_volt_to_load(data_ati_10_V);

time_8_align_rpm = 76;
time_8_align_LC = 2;
time_9_align_LC = 3;
time_10_align_LC = 2.5;

figure
plot(time_8_AS,airspeed_8.data(:,2))
hold on
plot(time_8_m,(motor_8.data(:,3)-15)*10,'b')
% plot(ms010msp{2}(:,1)+time_8_align,(ms010msp{2}(:,9)-200)/25)
plot(data_ati_8(:,2)+time_8_align_LC,data_ati_8(:,4))
plot(time_8_AS(end) + time_9_AS,airspeed_9.data(:,2),'r')
plot(time_8_m(end) + time_9_m ,(motor_9.data(:,3)-15)*10,'r')
plot(time_8_m(end) + data_ati_9(:,2)+time_9_align_LC,data_ati_9(:,4))
plot(time_8_AS(end) + time_9_AS(end) + time_10_AS,airspeed_10.data(:,2),'k')
plot(time_8_m(end) + time_9_m(end) + time_10_m,(motor_10.data(:,3)-15)*10,'k')
plot(time_8_m(end) + time_9_m(end) + data_ati_10(:,2)+time_10_align_LC,data_ati_10(:,4))

