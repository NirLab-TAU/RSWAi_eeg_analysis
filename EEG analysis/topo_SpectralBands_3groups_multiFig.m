function fig = topo_SpectralBands_3groups_multiFig(freq_control, freq_PD, statistics_pref)
% topo_SpectralBands_3groups_multiFig
% Author: Saar Lanir-Azaria
% Date: 03/05/2023
%
% Purpose
% --------
% Create topographic maps of spectral power (by band) for three groups:
%   Control, PD−RSWA, PD+RSWA.
% PD subgroups are produced inside helper functions that split PD by RSWA:
%   - select_bands_nonRBD (PD−RSWA)
%   - select_bands_RBD    (PD+RSWA)
%
% Inputs
% ------
% freq_control : 1xB cell (FieldTrip freq structs per band) for Control
% freq_PD      : 1xB cell (FieldTrip freq structs per band) for PD (mixed)
% statistics_pref : struct with fields
%   • parameter           : FieldTrip parameter to plot (e.g., 'powspctrm' or 'powspctrm_norm')
%   • chan2use            : cellstr of channel labels to include
%   • colors              : (optional) colormap presets (unused here)
%   • band_of_intrest     : [fmin fmax] (unused here; plotting uses per-band data)
%   • layout_path         : (optional) path to .mat layout file(s)
%   • layout_name         : (optional) name of layout mat (default 'laySaar_161.mat')
%   • zlim                : (optional) Nx2 numeric; rows per band for color scaling
%
% Output
% ------
% fig : vector of figure handles, one per band (excluding the "all freqs" index 1)
%
% Notes
% -----
% • Expects the downstream split functions and the grand-average function:
%     select_bands_nonRBD, select_bands_RBD, bends_norm_freqgrandav_3groups
% • Channels are intersected with the provided layout labels to avoid mismatch.
% • Paths/layouts are generalized; user must set statistics_pref.layout_path if needed.

close all;

% ---------- Parameters & Layout ----------
param = getfield(statistics_pref, 'parameter', 'powspctrm_norm'); 
layout_path = 'layout_path';
layout_name = 'lay_161.mat';

% Titles & bands metadata
bands_titles = {'all freqs', 'delta', 'theta', 'alpha', 'sigma', 'beta', 'gamma'};
group_titles = {'Control', 'PD−RSWA', 'PD+RSWA'};

% Default z-limits per band (tunable); can be overridden via statistics_pref.zlim
zlim_default = [
    0   0;   % (unused for index 1 "all freqs" in this plotting loop)
    4.5 5.5; % delta
    1.8 2.8; % theta
    1.0 1.8; % alpha
    0.5 0.8; % sigma
    0.2 0.45;% beta
    0.04 0.10% gamma
];
if isfield(statistics_pref, 'zlim') && ~isempty(statistics_pref.zlim)
    zlim_all = statistics_pref.zlim;
else
    zlim_all = zlim_default;
end

% ---------- Split PD into PD−RSWA and PD+RSWA & grand-average ----------
PD_noRSWA = select_nonRSWA(freq_PD); % PD−RSWA
PD_RSWA   = select_RSWA(freq_PD);    % PD+RSWA
[avg_spect, ~] = bends_freqgrandav_3groups(freq_control, PD_noRSWA, PD_RSWA, statistics_pref);

% ---------- Channel set & layout resolution ----------
if isfield(statistics_pref, 'chan2use') && ~isempty(statistics_pref.chan2use)
    chan2use = statistics_pref.chan2use(:);
else
    % Try to infer from data
    try
        chan2use = freq_control{1,1}{1,1}.label(:);
    catch
        error('chan2use not provided and could not be inferred from data.');
    end
end

% If no layout loaded, synthesize a minimal layout struct with labels only
if isempty(layout)
    layout = struct('label', {chan2use});
end

% Intersect requested channels with layout labels
layout_labels = layout.label(:);
[common_labels, ia] = intersect(layout_labels, chan2use, 'stable');

% ---------- Figure grid positions ----------
pos = [
    0.00 0.45 0.30 0.38;  % top-left   (Control)
    0.35 0.45 0.30 0.38;  % top-middle (PD−RSWA)
    0.70 0.45 0.30 0.38;  % top-right  (PD+RSWA)
];

% ---------- Plot per band (skip index 1 if it represents full-band) ----------
numBands = numel(freq_control); % should be 7
fig = gobjects(0);
for fb = 2:numBands
    fig(end+1) = figure('Name', bands_titles{fb}, 'Color', 'w'); 
    for g = 1:3
        group_spect = avg_spect{1, g}{1, fb};

        % Reduce to common labels if needed
        if isfield(group_spect, param) && isfield(group_spect, 'label')
            [~, ib] = intersect(group_spect.label(:), common_labels, 'stable');
            if ~isempty(ib)
                % Create a shallow copy limited to intersecting channels
                tmp = group_spect;
                tmp.label = group_spect.label(ib);
                tmp.(param) = group_spect.(param)(:, ib);
            else
                tmp = group_spect; % fallback
            end
        else
            tmp = group_spect;
        end

        cfg = [];
        cfg.parameter = param;
        cfg.zlim      = zlim_all(fb, :);
        cfg.marker    = 'off';
        cfg.comment   = 'no';
        cfg.colormap  = 'jet';
        cfg.colorbar  = 'no';
        cfg.channel   = common_labels; % plot on intersected set
        cfg.layout    = layout;
        cfg.style     = 'straight';
        cfg.figure    = subplot('Position', pos(g, :));
        ft_topoplotER(cfg, tmp);
        title(group_titles{g});
    end
end

end
