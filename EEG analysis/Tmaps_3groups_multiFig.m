function stat = Tmaps_3groups_multiFig(freq_control, freq_PD, statistics_pref)
% Tmaps_3groups_multiFig
% Author: Saar Lanir-Azaria
% Date: 03/05/2023
%
% PURPOSE
% -------
% Compute and plot channel-wise t-statistic topographies ("t-maps") for three
% group comparisons across spectral bands:
%   1) Control vs PD−RSWA, 2) Control vs PD+RSWA, 3) PD−RSWA vs PD+RSWA.
% PD subgroups are created inside this function via dedicated split helpers.
%
% INPUTS
% ------
% freq_control : 1xB cell. For each band b, a 1xNsub cell array of FieldTrip
%                freq structs (per subject) for the Control group.
% freq_PD      : 1xB cell. Same structure for the PD (mixed) group.
% statistics_pref : struct with optional fields
%   • parameter   : FieldTrip parameter to treat as power (default 'powspctrm')
%   • layout_path : path to layout .mat files (optional)
%   • layout_name : layout filename (default 'lay_161.mat')
%   • zplim       : [min max] limits for plotting t-maps (default [-4 4])
%
% OUTPUTS
% -------
% stat : cell array of size (3 x B), each entry is a FieldTrip stat struct
%        from the Monte Carlo comparison per band and comparison.
%
% FUNCTIONS CALLED
% ----------------
% • select_nonRSWA   (project helper; returns PD−RSWA per band)
% • select_RSWA      (project helper; returns PD+RSWA per band)
% • bends_freqgrandav_3groups (project helper; grand-averages per group/band)
% • montecarlo_statistics3 (project helper; runs cluster/permutation statistics)
% • ft_topoplotER         (FieldTrip; used to visualize the t-stat maps)
%
% NOTES
% -----
% • This analysis is intended as a post‑hoc, pairwise comparison following a significant omnibus ANOVA for group effects.
%   Use only after ANOVA indicates group differences, or interpret results with appropriate statistical restrictions
%   (e.g., multiple-comparison control, increased Type I error risk).
% • This function assumes the provided spectra represent power.
% • A valid layout is required for plotting; set statistics_pref.layout_path/name.

close all;

% ---- Parameters & layout
param = getfield(statistics_pref, 'parameter', 'powspctrm'); 
layout_path = getfield(statistics_pref, 'layout_path', '');
layout_name = getfield(statistics_pref, 'layout_name', 'lay_161.mat');
zplim = getfield(statistics_pref, 'zplim', [-4 4]);

% Load layout
layout = [];
if ~isempty(layout_path)
    layfile = fullfile(layout_path, layout_name);
    if exist(layfile, 'file')
        S = load(layfile);
        if isfield(S, 'lay2'); layout = S.lay2; end
        if isempty(layout) && isfield(S, 'lay'); layout = S.lay; end
    end
end
if isempty(layout)
    error('Layout not found. Provide statistics_pref.layout_path and layout_name.');
end

% Band labels
bands_titles = {'all freqs','delta','theta','alpha','sigma','beta','gamma'};

% Figure panel positions
pos = [
    0.00 0.45 0.30 0.38;  % Control > PD−RSWA
    0.35 0.45 0.30 0.38;  % Control > PD+RSWA
    0.70 0.45 0.30 0.38;  % PD−RSWA > PD+RSWA
];

% ---- Split PD into PD−RSWA and PD+RSWA, grand-average per group/band
PD_noRSWA = select_nonRSWA(freq_PD);
PD_RSWA   = select_RSWA(freq_PD);
[avg_spect, indi_spect] = bends_norm_freqgrandav_3groups(freq_control, PD_noRSWA, PD_RSWA, statistics_pref);

% Group comparison index pairs (1=Control, 2=PD−RSWA, 3=PD+RSWA)
Gpairs = [1 2; 1 3; 2 3];

% ---- Loop bands (skip index 1 if it is full band)
numBands = numel(freq_control);
stat = cell(size(Gpairs,1), numBands);
for fb = 2:numBands
    figure('Name', bands_titles{fb}, 'Color', 'w');
    hold on;

    for cidx = 1:size(Gpairs,1)
        gA = Gpairs(cidx,1);
        gB = Gpairs(cidx,2);

        % Run Monte Carlo (or other) stats on individual spectra of the band
        stat{cidx, fb} = montecarlo_statistics3( ...
            indi_spect{1,gA}{1,fb}, ...
            indi_spect{1,gB}{1,fb}, ...
            statistics_pref);

        % Identify significant channels
        sig_ind  = find(stat{cidx, fb}.prob < 0.025);
        Csig_ind = find(stat{cidx, fb}.mask == 1);
        sig_ch   = stat{cidx, fb}.label(sig_ind);
        Csig_ch  = stat{cidx, fb}.label(Csig_ind);

        % Plot t-map with highlighted channels
        cfg = [];
        cfg.parameter        = 'stat';
        cfg.zlim             = zplim;
        cfg.marker           = 'off';
        cfg.comment          = 'no';
        cfg.colormap         = 'jet';
        cfg.colorbar         = 'no';
        cfg.layout           = layout;
        cfg.style            = 'straight';
        cfg.highlight        = 'on';
        cfg.highlightchannel = {sig_ch, Csig_ch};
        cfg.highlightcolor   = {'k','w'};
        cfg.highlightsize    = {4,4};
        cfg.highlightsymbol  = {'+','+'};
        cfg.figure           = subplot('Position', pos(cidx, :));
        ft_topoplotER(cfg, stat{cidx, fb});
        title(sprintf('%s vs %s', strrep(avg_spect{2,gA},'_','-'), strrep(avg_spect{2,gB},'_','-')));
    end
end

end
