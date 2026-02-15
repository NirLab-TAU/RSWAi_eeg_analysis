%% sleep_frequency_bands.m
% Author: Saar Lanir-Azaria
% Date: 03/05/2023
%
% This function calculates power spectral density (PSD) over common frequency bands for REM sleep EEG data.
% It uses FieldTrip's ft_freqanalysis function with different methods (e.g., Hanning, Morlet, multitaper).
%
% Dependencies:
% - FieldTrip toolbox: https://www.fieldtriptoolbox.org
% - EEG data in FieldTrip format
%
% Output:
% - AllSpct_power: 1x7 cell array of power spectrum structures for each frequency band
%   {1,f} - frequency band data
%   {2,f} - frequency band name

function [AllSpct_power] = sleep_frequency_bands(data)

    % Define spectral analysis method
    method = 2;  % 1 = boxcar, 2 = hanning, 3 = dpss, 4 = morlet, 5 = mtmconvol (avg time), 6 = mtmconvol (avg trial)

    % Define frequency bands
    bands =  [  0.5  40 ; 0.5  4 ;  4  8 ;    8  12 ;   12 15 ;  15 25 ;  25 45 ];
    titles = {'AllSpct', 'delta', 'theta', 'alpha', 'sigma', 'beta', 'gamma'};

    for f = 1:7
        AllSpct_power{1,f}   = frequency_bands_cal(data, method, bands(f,:));
        AllSpct_power{2,f}   = titles{f};
    end
end


