%% Fix_bad_Chann.m
% Author: Saar Lanir-Azaria
% Date: 03/05/2023
%
% This function repairs EEG data by interpolating missing or bad channels using FieldTrip's channel repair methods.
% The function identifies channels with NaN values and repairs them using an average or spline interpolation method.
%
% INPUTS:
%   data - EEG data structure (FieldTrip format)
%
% OUTPUT:
%   fixed - EEG data structure with interpolated channels
%
% Required:
% - FieldTrip toolbox
% - neighbour257_new.mat (neighboring electrode information)
% - elec_all.mat (electrode location information)
%
% IMPORTANT: Set paths to your local template folder where the electrode layout and neighbor files are located.

function [fixed] = Fix_bad_Chann(data)

%% Set local path to template files (user must define this)
template_path = '<YOUR_PATH>/EEG_analysis/templates'; % <-- Set this before running

%% Load necessary electrode and neighbor information
load(fullfile(template_path, 'neighbour257_new.mat'));
load(fullfile(template_path, 'elec_all.mat'));

%% Set interpolation method
method = 'average'; % Alternatives: 'spline', 'weighted', 'slap'

%% Correct data labeling for 257 channels if necessary
if length(data.label) == 257
    data = Fix_label_E257(data);
end

%% Detect initial bad channels
[good_trials, ~] = detect_nan_trails(data);
[~, bad_chan] = detect_nan_chan(data, good_trials);

%% Perform channel interpolation if bad channels are detected
if ~isempty(bad_chan)
    cfg = [];
    cfg.method = method;
    cfg.badchannel = data.label(bad_chan);
    cfg.neighbours = neighbour257;
    cfg.trials = good_trials;
    cfg.elec = elec;
    fixed = ft_channelrepair(cfg, data);

 else
    fixed = data;
end

end
