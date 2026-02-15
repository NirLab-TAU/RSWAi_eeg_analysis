function [all_sub] = sleep_group_cal(files_folder)
% sleep_group_cal - Calculates power spectra across frequency bands for all subjects in a given folder.
%
% Author: Saar Lanir-Azaria
% Date: 03/05/2023
%
% Input:
%   files_folder  - Full path to the directory containing subject .mat files
%
% Output:
%   all_sub       - Cell array containing frequency band power for all subjects
%
% Dependencies:
%   - FieldTrip toolbox (https://www.fieldtriptoolbox.org)
%   - scalp_regions, Fix_bad_Chann, Fix_Miss_Chann, reorder_chann, sleep_frequency_bands

%% Define channels and frequency bands
[~, ~, scalp] = scalp_regions(2);   % scalp = 193 scalp EEG channels
num_bands = 1:7;                    % Define number of frequency bands to store

%% Get list of .mat files in folder (recursive)
datafiles = dir(fullfile(files_folder, '**', '*.mat'));
nfiles = numel(datafiles);

%% Loop through subjects and calculate frequency band power
for Nsub = 1:nfiles
    cd(files_folder)
    load(datafiles(Nsub).name);  % Load 'all_post_ICA' structure

    % Assume REM sleep stage 
    data2use = Fix_bad_Chann(all_post_ICA);
    data2use = Fix_Miss_Chann(data2use);

    % Re-reference to average of scalp channels
    cfg = [];
    cfg.feedback = 'none';
    cfg.reref = 'yes';
    cfg.refmethod = 'avg';
    cfg.refchannel = scalp;
    data_reref = ft_preprocessing(cfg, data2use);

    % Reorder channels based on template
    data_reref = reorder_chann(data_reref);

    % Calculate frequency bands
    sub_freq = sleep_frequency_bands(data_reref);

    % Store results in output cell array
    for f = num_bands
        all_sub{1,f}{1,Nsub} = sub_freq{1,f};                 % Spectral values
        all_sub{1,f}{2,Nsub} = datafiles(Nsub).name;          % Subject filename
        if f == 1
            all_sub{2,f} = sub_freq{2,f};                     % Frequency axis
        end
    end

    % Clear temporary variables
    clear data2use data_reref sub_freq
end

disp('Power spectrum calculation complete.')

end
