function [fig1, stat_T, rejected_p, statANOVA] = daviolinplot_3groups_singleROI(freq_control, freq_PD, statistics_pref)
% daviolinplot_3groups_singleROI
% Author: Saar Lanir-Azaria
% Date: 07/05/2024
%
% PURPOSE
% -------
% Create violin plots for a SINGLE ROI comparing three groups (Control, PD−RSWA, PD+RSWA)
% across two frequency windows (e.g., low vs high within a band) during REM sleep, and run
% per-window group statistics.
%
% PIPELINE
% --------
% 1) Split PD into PD−RSWA and PD+RSWA.
% 2) Extract individual-subject spectra (keepindividual='yes') for a target band.
% 3) For each frequency window (FOI), average power within ROI channels and FOI.
% 4) Plot distributions with violin plots.
% 5) Stats: per-FOI pairwise tests across groups + one-way ANOVA per FOI.
%
% INPUTS
% ------
% freq_control : 1xB cell. For each band b, a 1xNsub cell array of FieldTrip freq structs (Control)
% freq_PD      : 1xB cell. Same structure for the PD (mixed) group
% statistics_pref : struct with optional fields
%   • band_index  : integer band index to analyze (default 3)
%   • chan2use    : cellstr of ROI channel labels (REQUIRED for single ROI)
%   • foi_pairs   : 1xK cell of [fmin fmax] frequency windows (default {[4 6], [6 8]})
%   • foi_labels  : 1xK cell of labels for the FOIs (default {'low','high'})
%   • colors      : 3x3 RGB for groups (default preset)
%   • Ylim        : [ymin ymax] for plot (default auto)
%
% OUTPUTS
% -------
% fig1       : figure handle for the violin plot
% stat_T     : K x 6 matrix (K=#FOIs). Columns: [p12 p13 p23 s12 s13 s23]
%              where s** is the test statistic (t or z) depending on test used
% rejected_p : FDR mask (1=rejected) across all FOI×comparison p-values
% statANOVA  : 1xK cell outputs from simple_ANOVA_3group per FOI
%
% FUNCTIONS CALLED
% ----------------
% • select_nonRSWA, select_RSWA                     (project helpers)
% • bends_norm_freqgrandav_3groups                  (project helper; keeps individual spectra)
% • ft_selectdata                                   (FieldTrip)
% • daviolinplot                                    (Povilas Karvelis)
% • simple_ANOVA_3group                             (project helper)
% • FDR_corr                                        (project helper)
%
% NOTES
% -----
% • Spectra are treated as power ('powspctrm').
% • This analysis is intended as post‑hoc after a significant omnibus ANOVA for group effects.
%   Otherwise, interpret pairwise results with appropriate statistical restrictions.

% ---- Defaults
band2plot   = getfield(statistics_pref, 'band_index', 3); 
if ~isfield(statistics_pref, 'chan2use') || isempty(statistics_pref.chan2use)
    error('statistics_pref.chan2use (ROI channels) is required for the single-ROI analysis.');
end
ROI_channels = statistics_pref.chan2use(:);

foi_pairs  = getfield(statistics_pref, 'foi_pairs',  { [4 6], [6 8] });
foi_labels = getfield(statistics_pref, 'foi_labels', {'low','high'});
colors     = getfield(statistics_pref, 'colors', [0.04 0.04 0.74; 0.64 0.08 0.18; 0.93 0.69 0.13]);
Ylim       = getfield(statistics_pref, 'Ylim', []);

% Pairwise comparisons ordering: (Control vs PD−RSWA), (Control vs PD+RSWA), (PD−RSWA vs PD+RSWA)
Gcompars = [1 2; 1 3; 2 3];

% ---- Split PD and collect individual spectra for the target band
PD_noRSWA = select_nonRSWA(freq_PD);
PD_RSWA   = select_RSWA(freq_PD);
[~, indi_spect] = bends_norm_freqgrandav_3groups(freq_control, PD_noRSWA, PD_RSWA, statistics_pref);

% Individual spectra for selected band (keepindividual='yes')
group_spect = { indi_spect{1,1}{1,band2plot}, ... % Control
                indi_spect{1,2}{1,band2plot}, ... % PD−RSWA
                indi_spect{1,3}{1,band2plot}  };  % PD+RSWA

% Subject counts per group
Nsub = [ size(group_spect{1}.powspctrm,1), ...
         size(group_spect{2}.powspctrm,1), ...
         size(group_spect{3}.powspctrm,1) ];

% ---- Build data matrices per group (rows=subjects, cols=FOIs)
K = numel(foi_pairs);
 data = { nan(Nsub(1), K), nan(Nsub(2), K), nan(Nsub(3), K) };

for k = 1:K
    thisFOI = foi_pairs{k};
    for g = 1:3
        cfg = [];
        cfg.avgoverchan = 'yes';
        cfg.channel     = ROI_channels;
        cfg.frequency   = thisFOI;
        cfg.avgoverfreq = 'yes';
        mean_spect = ft_selectdata(cfg, group_spect{g});
        vec = squeeze(mean_spect.powspctrm);
        data{g}(:, k) = vec(:);
    end

    % One-way ANOVA per FOI (helper consumes FieldTrip freq + prefs)
    statistics_pref.band_of_intrest = thisFOI;
    statistics_pref.chan2use        = ROI_channels;
    statANOVA{1, k} = simple_ANOVA_3group( ...
        indi_spect{1,1}{1,band2plot}, ...
        indi_spect{1,2}{1,band2plot}, ...
        indi_spect{1,3}{1,band2plot}, ...
        statistics_pref);
end

% ---- Pairwise tests per FOI
stat_T = nan(K, 6); % [p12 p13 p23 s12 s13 s23]
for k = 1:K
    for c = 1:size(Gcompars,1)
        g1 = Gcompars(c,1); g2 = Gcompars(c,2);
        % Choose test: use t-test if both groups pass normality; otherwise ranksum
        v1 = data{g1}(:, k); v2 = data{g2}(:, k);
        ok1 = numel(v1) >= 4 && std(v1) > 0 && kstest((v1-mean(v1))/std(v1)) == 0;
        ok2 = numel(v2) >= 4 && std(v2) > 0 && kstest((v2-mean(v2))/std(v2)) == 0;
        if ok1 && ok2
            [~, p, ~, STAT] = ttest2(v1, v2);
            stat_T(k, c)   = p;
            stat_T(k, c+3) = STAT.tstat;
        else
            [p, ~, STAT]   = ranksum(v1, v2);
            stat_T(k, c)   = p;
            stat_T(k, c+3) = STAT.zval;
        end
    end
end

% ---- FDR across all FOI×comparison p-values
p_values   = reshape(stat_T(:, 1:3).', 1, []); % 1 x (K*3)
rejected_p = FDR_corr(p_values);

% ---- Violin plot
fig1 = figure('Position', [700 300 700 500], 'Color', 'w');
h = daviolinplot(data, ...
    'xtlabels', foi_labels, 'colors', colors, 'violinalpha', 1, 'violinwidth', 1, ...
    'box', 0, 'boxcolors', 'k', 'boxspacing', 1, ...
    'scatter', 2, 'jitter', 2, 'scattercolors', 'k', ...
    'scattersize', 20, 'bins', 12); 


ylabel('Power', 'Color', 'k', 'FontSize', 12);
set(gca, 'XColor', 'k', 'YColor', 'k', 'FontSize', 12);
if ~isempty(Ylim), ylim(Ylim); end
xlim([0.6, max(2.5, 0.6 + K + 0.4)]);

title(sprintf('Single ROI (%d ch) — Band %d; FOIs: %s', numel(ROI_channels), band2plot, strjoin(cellfun(@(r) sprintf('%g-%gHz', r(1), r(2)), foi_pairs, 'UniformOutput', false), ', ')));

end