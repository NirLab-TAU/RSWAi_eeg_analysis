%% REM_GroupSpectralStats_Main.m
% Author: Saar Lanir-Azaria
% Date: 03/05/2023
%
% Group spectral statistics and plots for REM EEG
%
% Description:
% Loads group-level REM spectral outputs (freq_control, freq_PD) created by
% sleep_group_cal(), then runs statistical comparisons and generates figures.
% All plotting/stats functions are modular and edited separately.
% Note:
% - Inside the downstream analysis functions, the PD group data is further
%   subdivided into PD+RSWA and PD−RSWA groups using a dedicated splitting function.
% - Ensure the splitting function is available and correctly implemented.
%
% Requirements:
% - FieldTrip toolbox
% - Outputs saved from sleep_group_cal(): variables named freq_control, freq_PD
% - Helper functions: topo_SpectralBands_3groups_multiFig, Tmaps_3groups_multiFig,
%   daviolinplot_3groups, FDR_corrSaar
% - A channel/layout definition to set statistics_pref.chan2use
%
% NOTE: Paths are placeholders; set <YOUR_PATH> accordingly.

%% --- Setup (edit paths) ---
data_path = '<YOUR_PATH>';% <-- set your base path
layouts_path =  '<YOUR_PATH>';% <-- set your base path

%% --- Load REM group spectral data ---
% Expect files to contain variables: freq_control, freq_PD
cd(data_path)
load('REM_freq_PD.mat', 'freq_PD')                 % <-- rename to your saved filename
load('REM_freq_control.mat', 'freq_control')       % <-- rename to your saved filename
cd(layouts_path)
load('layout.mat');

%% --- Statistics/plot preferences ---
statistics_pref = struct();
statistics_pref.to_plot = 1;           % 1=produce figures, 0=stats only
statistics_pref.to_norm = 1;           % normalize spectra within-subject
statistics_pref.to_log  = 0;           % log10 power
statistics_pref.method  = 2;           % spectral method id (for downstream fns, if used)
statistics_pref.threshold = 1;         % cluster/voxel threshold (function-specific)
statistics_pref.chan2use = chan2use;   %  Provide chan2use (e.g., scalp channels or full layout labels)
statistics_pref.band_of_intrest = [0.5 45];
statistics_pref.colors = [0.07 0.20 0.14; 0.60 0.08 0.20; 0.90 0.70 0.10]; % control, PD, (optional 3rd)
statistics_pref.keepindividual = 'yes'; % keep individual subjects when plotting

%% --- Run analyses & plots ---
% Topographic spectral bands comparison
fig_topo = topo_SpectralBands_3groups_multiFig(freq_control, freq_PD, statistics_pref);
[statANOVA] = ANOVA_3group_freq(freq_control{1,1}, freq_PD{1, 1},statistics_pref);

% T-maps across channels/frequencies
stat_tmaps = Tmaps_3groups_multiFig(freq_control, freq_PD, statistics_pref);

% Violin plots per band
[fig_violin,stat_T,rejected_p,statANOVA_violin] = daviolinplot_3groups_singleROI(freq_control, freq_PD, statistics_pref);


%% --- Save figures (optional) ---
% saveas(fig_topo, fullfile(results_path, 'REM_topo_bands.png'))
% saveas(fig_violin, fullfile(results_path, 'REM_violin_bands.png'))

