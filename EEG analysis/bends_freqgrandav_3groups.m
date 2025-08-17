function [avg_spect, indi_spect] = bends_freqgrandav_3groups(freq_control, PD_noRBD, PD_RBD, statistics_pref)
% bends_norm_freqgrandav_3groups
% Author: Saar Lanir-Azaria
% Date: 03/05/2023
%
% Purpose
% --------
% Compute grand-average spectra (FieldTrip freq structures) for three groups:
%   Control, PD−RSWA, PD+RSWA across predefined bands.
%
% Inputs
% ------
% freq_control : 1xB cell, each {1,b} is a 1xNsub cell of FieldTrip freq structs (Control)
% PD_noRBD     : 1xB cell, PD−RSWA (same structure)
% PD_RBD       : 1xB cell, PD+RSWA (same structure)
% statistics_pref.to_log : (0/1) optional log10 transform per subject before averaging
%
% Outputs
% -------
% avg_spect : 1x3 cell, each {1,g}{1,b} is a FieldTrip freq struct averaged across subjects
% indi_spect: 1x3 cell, each {1,g}{1,b} keeps individual subjects ('keepindividual'='yes')
%
% Dependencies
% ------------
% FieldTrip (ft_freqgrandaverage)
% FUNCTIONS CALLED
% ----------------
% • ft_freqgrandaverage  (FieldTrip)
% • log_indi_spect       (project helper; only used when statistics_pref.to_log == 1)
%

% ---- Metadata for labeling
bands_titles = {'all freqs','delta','theta','alpha','sigma','beta','gamma'};
group_titles = {'control','PD_noRSWA','PD_RSWA'};

numBands = numel(freq_control);
numGroups = 3;

% Preallocate containers to avoid dynamic growth inside loops
organized_data = cell(1, numBands);            % per-band, per-group subject cells

% ---- Collect per-band, per-group spectra (optionally log-transform)
for b = 1:numBands
    % group_data is a 1x3 cell: {Control, PD−RSWA, PD+RSWA}
    group_data = {freq_control{1,b}, PD_noRSWA{1,b}, PD_RSWA{1,b}};

    % Preallocate spect_data for readability and performance
    spect_data = cell(1, numGroups);
    for g = 1:numGroups
        if isfield(statistics_pref,'to_log') && statistics_pref.to_log == 1
            % Apply log10 transform within each subject freq struct
            spect_data{1,g} = log_indi_spect(group_data{1,g});
        else
            spect_data{1,g} = group_data{1,g};
        end
    end
    % Store the grouped subject spectra for this band
    organized_data{1,b} = spect_data;
end

% ---- Grand-average for each group and band (powspctrm only)
% Preallocate outer cells for groups
avg_spect  = cell(2, numGroups);  % row 1: per-band structs, row 2: group title
indi_spect = cell(2, numGroups);

for g = 1:numGroups
    % Preallocate per-band cells for this group
    avg_spect{1,g}  = cell(1, numBands);
    indi_spect{1,g} = cell(1, numBands);

    for b = 1:numBands
        % Group-average over subjects (no individual retention)
        cfg = [];
        cfg.keepindividual = 'no';
        cfg.parameter      = {'powspctrm'};
        avg_spect{1,g}{1,b} = ft_freqgrandaverage(cfg, organized_data{1,b}{1,g}{1,:});
        avg_spect{1,g}{2,b} = bands_titles{b};

        % Keep individual subjects
        cfg.keepindividual = 'yes';
        indi_spect{1,g}{1,b} = ft_freqgrandaverage(cfg, organized_data{1,b}{1,g}{1,:});
        indi_spect{1,g}{2,b} = bands_titles{b};
    end

    % Store group titles
    avg_spect{2,g}  = group_titles{g};
    indi_spect{2,g} = group_titles{g};
end

end