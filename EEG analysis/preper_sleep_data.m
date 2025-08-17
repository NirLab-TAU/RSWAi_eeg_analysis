%% EEG Preprocessing Function: preper_sleep_data.m
% Author: Saar Lanir-Azaria
% Date: 03/05/2023
%
% This function preprocesses EEG data recorded in EGI MFF format using FieldTrip toolbox functions.
% It performs segmentation, filtering (band-stop and band-pass), and resampling. The sleep stage scoring
% data is adjusted and synchronized with EEG epochs. The output data format (cfg) is compatible with FieldTrip.
%
% Required toolbox:
% - FieldTrip (credit to FieldTrip developers: https://www.fieldtriptoolbox.org)
%
% IMPORTANT: Replace placeholders with your local directories.

function [epoched_data, epoched_scoring] = preper_sleep_data(dataset_file, scoring)

%% Preprocessing Parameters
apply_filter = 1; % Set to 1 to apply filtering

%% Configure FieldTrip preprocessing
cfg = [];
cfg.dataset = dataset_file;
cfg.channel = 'all'; % Process all electrodes at once

%% Apply Band-stop (notch) Filter to remove line noise
if apply_filter
    cfg.dftfilter = 'yes';
    cfg.dftfreq = [50 100 150]; % Specify frequencies to remove (fundamental and harmonics)
    data = ft_preprocessing(cfg);
    %% Band-pass Filtering (0.5–45Hz)
    cfg = [];
    cfg.bpfilter = 'yes';
    cfg.bpfreq = [0.1 45];
    data = ft_preprocessing(cfg, data);
else
    data = ft_preprocessing(cfg);
end

%% Downsample to 250Hz (if needed)
if data.fsample == 1000
    cfg = [];
    cfg.resamplefs = 250;
    data = ft_resampledata(cfg, data);
end

%% Synchronize Scoring with EEG Data
if length(scoring) < length(data.time{1})
    addLostSeconds = ones(1, length(data.trial{1}) - length(scoring)) * scoring(end);
    scoring = [scoring'; addLostSeconds']; % Extend scoring
else
    scoring = scoring(1:length(data.time{1})); % Trim excess scoring
    scoring = scoring';
end

%% Segment EEG data into 30-second epochs
cfg = [];
cfg.length = 30; % epoch length in seconds
epoched_data = ft_redefinetrial(cfg, data);

%% Create epoched scoring
for e = 1:length(epoched_data.time)
    epoched_scoring(e, 1:2) = epoched_data.sampleinfo(e, :);
    epoched_scoring(e, 3) = scoring(epoched_data.sampleinfo(e, 1));
end

%% Embed Scoring into Data Structure
cfg = [];
cfg.trl = epoched_scoring;
epoched_data = ft_redefinetrial(cfg, epoched_data);
epoched_data.cfg.previous = [];

end
