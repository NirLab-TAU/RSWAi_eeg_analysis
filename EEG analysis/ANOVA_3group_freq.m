function statANOVA = ANOVA_3group_freq(freq_control, freq_PD, statistics_pref)
% ANOVA_3group_freq
% Author: Saar Lanir-Azaria
% Date: 03/05/2023
%
% PURPOSE
% -------
% Perform an omnibus, one-way ANOVA across THREE groups (Control, PD−RSWA, PD+RSWA)
% on REM spectral power using FieldTrip's permutation framework (ft_freqstatistics)
% with an independent-samples F-statistic and cluster-based multiple-comparison control.
%
% INPUTS
% ------
% freq_control : 1xB cell; for each band b, a 1xNsub cell array of FieldTrip freq structs
% freq_PD      : 1xB cell; same structure for the PD (mixed) group
% statistics_pref : struct with optional fields
%   • band_index      : integer band index to analyze (default 3)
%   • freq_window     : [fmin fmax] Hz to average within the selected band (default [4 8])
%   • chan2use        : cellstr of channel labels to include (default = all available)
%   • parameter       : FieldTrip parameter to analyze (default 'powspctrm')
%   • neighbours_path : folder containing neighbour .mat (optional)
%   • neighbours_file : filename of neighbour .mat (default 'neighbour257.mat')
%   • layout_path     : folder containing layout .mat (optional; used only to derive labels)
%   • layout_file     : filename of layout .mat (default 'lay_161.mat')
%   • alpha           : significance level for permutation testing (default 0.05)
%
% OUTPUT
% ------
% statANOVA : FieldTrip statistics structure returned by ft_freqstatistics
%
% FUNCTIONS CALLED
% ----------------
% • select_bands_nonRBD, select_bands_RBD    (split PD into PD−RSWA / PD+RSWA)
% • bends_norm_freqgrandav_3groups           (collect individual spectra per group & band)
% • ft_selectdata, ft_freqstatistics         (FieldTrip)
%
% NOTES
% -----
% • This is an omnibus test intended to justify post‑hoc pairwise analyses.
% • Spectra are treated as power ('powspctrm' by default).
% • Cluster-based correction is applied across channels; set neighbours accordingly.

% -------------------- Defaults --------------------
band_index   = getfield(statistics_pref, 'band_index', 3); 
freq_window  = getfield(statistics_pref, 'freq_window', [4 8]);
param        = getfield(statistics_pref, 'parameter', 'powspctrm');
alpha        = getfield(statistics_pref, 'alpha', 0.05);
numrand      = getfield(statistics_pref, 'numrandomization', 4000);%
minnbchan    = getfield(statistics_pref, 'minnbchan', 2);

neigh_path   = getfield(statistics_pref, 'neighbours_path', '');
neigh_file   = getfield(statistics_pref, 'neighbours_file', 'neighbour257_new.mat');
layout_path  = getfield(statistics_pref, 'layout_path', '');
layout_file  = getfield(statistics_pref, 'layout_file',  'lay_161.mat');

% ---------------- Split PD and gather individuals ----------------
PD_noRSWA = select_nonRSWA(freq_PD);
PD_RSWA   = select_RSWA(freq_PD);
[~, indi_spect] = bends_freqgrandav_3groups(freq_control, PD_noRSWA, PD_RSWA, statistics_pref);

% Use the selected band (keepindividual='yes' structures)
group_spect = { indi_spect{1,1}{1,band_index}, ... % Control
                indi_spect{1,2}{1,band_index}, ... % PD−RSWA
                indi_spect{1,3}{1,band_index}  };  % PD+RSWA

% ---------------- Channel set ----------------
chan2use = [];
if isfield(statistics_pref, 'chan2use') && ~isempty(statistics_pref.chan2use)
    chan2use = statistics_pref.chan2use(:);
else
    % Try to get labels from a layout file, otherwise from data
    if ~isempty(layout_path)
        layfile = fullfile(layout_path, layout_file);
        if exist(layfile, 'file')
            S = load(layfile);
            if isfield(S, 'lay2'); chan2use = S.lay2.label(:); end
            if isempty(chan2use) && isfield(S, 'lay'); chan2use = S.lay.label(:); end
        end
    end
    if isempty(chan2use)
        try
            chan2use = group_spect{1}.label(:);
        catch
            error('Could not determine channels to use. Provide statistics_pref.chan2use or a layout file.');
        end
    end
end

% ---------------- Build per-group freq structs averaged over freq window ----------------
mean_spect = cell(1,3);
for g = 1:3
    cfg = [];
    cfg.parameter   = param;
    cfg.avgoverchan = 'no';            % per-channel test (topography)
    cfg.channel     = chan2use;
    cfg.frequency   = freq_window;
    cfg.avgoverfreq = 'yes';           % average across the FOI
    mean_spect{g} = ft_selectdata(cfg, group_spect{g});
end

% ---------------- Design matrix (independent samples) ----------------
% Two rows: 1) group index, 2) subject index within that group
Nsub = [ size(mean_spect{1}.(param),1), ...
         size(mean_spect{2}.(param),1), ...
         size(mean_spect{3}.(param),1) ];

design = zeros(2, sum(Nsub));
ix = 1;
for g = 1:3
    rng = ix : ix + Nsub(g) - 1;
    design(1, rng) = g;              % group id
    design(2, rng) = 1:Nsub(g);      % subject id within group
    ix = ix + Nsub(g);
end

% ---------------- Neighbours (for clustering) ----------------
neighbours = [];
if ~isempty(neigh_path)
    nfile = fullfile(neigh_path, neigh_file);
    if exist(nfile, 'file')
        S = load(nfile);
        if isfield(S, 'neighbour257'); neighbours = S.neighbour257; end
        if isempty(neighbours)
            fn = fieldnames(S);
            neighbours = S.(fn{1}); % best effort: take the first variable
        end
    end
end
if isempty(neighbours)
    warning('Neighbours not provided/found. Cluster correction may fail or be disabled.');
end

% ---------------- ft_freqstatistics (permutation ANOVA) ----------------
cfg = [];
cfg.parameter        = param;
cfg.channel          = chan2use;
cfg.avgoverfreq      = 'no';         % we already averaged over freq above
cfg.computeprob      = 'yes';
cfg.design           = design;
cfg.ivar             = 1;            % independent variable: group id

cfg.method           = 'montecarlo';
cfg.statistic        = 'indepsamplesF';
cfg.tail             = 1;            % F is one-sided (right tail)

% Multiple-comparison correction (cluster across channels)
cfg.correctm         = 'cluster';
cfg.alpha            = alpha;
cfg.correcttail      = 'alpha';
cfg.neighbours       = neighbours;
cfg.minnbchan        = minnbchan;
cfg.numrandomization = numrand;
cfg.clusteralpha     = alpha;        % threshold for sample-specific tests
cfg.clusterstatistic = 'maxsum';
cfg.clusterthreshold = 'nonparametric_common';
cfg.clustertail      = cfg.tail;

statANOVA = ft_freqstatistics(cfg, mean_spect{1}, mean_spect{2}, mean_spect{3});

% ---------------- Optional: report count of significant channels ----------------
if isfield(statistics_pref,'verbose') && statistics_pref.verbose
    if isfield(statANOVA,'mask') && ~isempty(statANOVA.mask)
        num_sig = sum(any(statANOVA.mask,1));
        fprintf('ANOVA: # significant channels = %d\n', num_sig);
    end
end

end