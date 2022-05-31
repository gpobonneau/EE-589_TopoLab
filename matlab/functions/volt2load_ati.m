function [loads] = Gamma_volt_to_load(voltages)

%Calibration matrix from ATI for the Gamma loadcell
%FT29366.cal file
CAL = [-0.25700   0.01517   0.45794 -13.68147  -0.35212  14.13572;
    -0.22714  16.59830  -0.20065  -7.82922   0.48140  -8.20977;
    25.17453  -0.25609  24.88968  -0.64352  25.31836  -0.11185;
    -0.00073   0.20290  -0.73248  -0.07961   0.74013  -0.10146;
    0.83129  -0.00618  -0.42229   0.17569  -0.42258  -0.17038;
    0.01193  -0.45918   0.01022  -0.43584   0.00828  -0.45126];

loads=zeros(size(voltages,1),6);

%multiply by calibration matrix to convert, transposes are used to make sure the vectors are correctly formatted.
for i=1:1:size(voltages,1)     
    volts_trans = transpose(voltages(i,4:end));
    loads_trans = CAL * volts_trans;
    loads(i,:)=transpose(loads_trans);
end

end

