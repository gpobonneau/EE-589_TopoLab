function mask = extract_vals(signal, thrust, nb_erode)
%EXTRACT_VALS Summary of this function goes here
%   Detailed explanation goes here

    nb_points = 11;
    
    % remove outliers
    mask = signal==thrust;
    mask = conv(ones(1, 2*nb_points), ~mask);
    mask = mask(nb_points:end-nb_points)==0;
    mask = conv(ones(1, 2*nb_points), mask);
    mask = ~mask(nb_points:end-nb_points)==0;

    % extend to encapsulate more or less
    if (nb_erode > 0)
        mask = conv(ones(1, 2*nb_erode), ~mask);
        mask = mask((1/2*nb_erode):(end-3/2*nb_erode))==0;
    else
        nb_erode = -nb_erode;
        mask = conv(ones(1, 2*nb_erode), mask);
        mask = mask((3/2*nb_erode):(end-1/2*nb_erode))~=0;
    end
    
end

