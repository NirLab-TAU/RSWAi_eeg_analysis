%% detect_nan_chan2.m
% Author: Saar Lanir-Azaria
% Date: 03/05/2023
%
% This function detects channels containing NaN values within specified trials
% and returns indices of good (clean) and artifact (NaN-containing) channels.
%
% INPUTS:
%   data        - EEG data structure (FieldTrip format)
%   trials2use  - indices of trials to evaluate; if empty, all trials are evaluated
%
% OUTPUTS:
%   good_chan       - indices of channels without NaNs
%   artifact_chan   - indices of channels containing NaNs

function [good_chan, artifact_chan] = detect_nan_chan(data, trials2use)

% Check if trials2use is provided, otherwise default to all trials
if isempty(trials2use)
    trials2use = 1:length(data.trial);
end

artifact_chan = [];
good_chan = [];

% Initialize counters
ind_arti = 1;
ind_good = 1;

% Check each channel for NaNs in the specified trials
for channel = 1:length(data.label)
    if any(isnan(data.trial{trials2use(1)}(channel, :)))
        artifact_chan(ind_arti) = channel;
        ind_arti = ind_arti + 1;
    else
        good_chan(ind_good) = channel;
        ind_good = ind_good + 1;
    end
end

end