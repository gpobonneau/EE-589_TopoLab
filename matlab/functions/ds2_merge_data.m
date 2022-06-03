function data = ds2_merge_data(nidaq_file, log_file, delay)
%READ_XPM_DATA Summary of this function goes here
%   Detailed explanation goes here

    % ATI acquisition rate
    TE_ATI = 1/120;
    TE_LOG = 1/5;

    % import load cell data and convert format
    temp = readmatrix(nidaq_file);
    temp(:, 4:end) = volt2load_ati(temp);
    temp = temp(1:end-2,:);

    % select relevant data
    data(:,1) = temp(:,2);
    data(:,2:7) = temp(:,4:end);

    % import arduino rpm data
    temp = readmatrix(log_file);
    temp(:,3) = filloutliers(temp(:,3), 'linear', 'movmedian', 10);

    % resample arduino rpm data
    temp2(:,1) = reshape(kron(temp(:, 2), ones(1,TE_LOG/TE_ATI))', 1, []);
    temp2(:,2) = reshape(kron(temp(:, 3), ones(1,TE_LOG/TE_ATI))', 1, []);

    % sync and merge data
    len_ati = length(data);
    len_log = length(temp2);   
    if (delay > 0)
        % skjhmfx
        if (len_log-delay >= len_ati) 
            data(:,8:9) = temp2(delay:len_ati+delay-1,:);
        else
            data = data(1:len_log-delay+1,:);
            data(:,8:9) = temp2(delay:end,:);
        end
    else
        % lsdmzs
        delay = -delay;
        if (len_ati-delay >= len_log) 
            data = data(delay:len_log+delay-1,:);
            data(:,8:9) = temp2;
        else
            data = data(delay:end,:);
            data(:,8:9) = temp2(1:len_ati-delay+1,:);
        end        
    end

end

