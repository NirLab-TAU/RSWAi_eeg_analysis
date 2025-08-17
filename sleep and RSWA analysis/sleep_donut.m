function figs = sleep_donut()
% sleep_donut
% Author: Saar Lanir-Azaria
% Date: 03/05/2023
%
% PURPOSE
% -------
% Visualize the distribution of sleep stages as donut charts for two groups
% (Control and PD). Percentages are computed relative to total sleep time.
%
% WHAT IT DOES
% ------------
% • Loads group-level sleep metrics via project helper `group_sleep_var(group)`.
% • Computes %REM, %N1, %N2, %N3 per group relative to a total sleep metric.
% • Plots donut charts (one per group) using `donutchart`.
%
% OUTPUTS
% -------
% figs : 1x2 array of figure handles [ControlFig, PDFig]
%
% DEPENDENCIES (project helpers / utilities)
% -----------------------------------------
% • group_sleep_var(group)  -> returns sleep metrics in a 2-row cell array:
%       row 1: numeric vectors (1 x Nsubjects) for each metric index
%       row 2: label strings for each metric index
% • donutchart(data, labels, ...)  -> plotting utility for donut/pie charts
%
% CONFIGURATION
% -------------
% You may need to adapt the indices below depending on how `group_sleep_var`
% organizes the metrics. Current defaults assume:
%   total_index   = 3;      % index of total sleep time (TST) or denominator
%   stage_indices = [4 5 6 7];   % indices for REM, N1, N2, N3 respectively
% If your mapping differs, edit the two lines under the CONFIG block.
%
% NOTES
% -----
% • No files are loaded from disk; the earlier hardcoded path and MAT file are removed.
% • The function assumes each metric is a vector across subjects; we compute the group mean.
% • Percentages are clipped at [0, 100] for display robustness if needed.

% -------------------- CONFIG --------------------
total_index   = 3;          % denominator metric index (e.g., total sleep time)
stage_indices = [4 5 6 7];  % [REM, N1, N2, N3]
stage_labels  = ["REM","N1","N2","N3"];
face_alpha    = 0.5;        % donut face transparency
font_color    = 'k';

% ---------------- Load sleep metrics ----------------
control_sleep_VAR = group_sleep_var(1);  % Controls
PD_sleep_VAR      = group_sleep_var(2);  % PD

% Validate structure
assert(iscell(control_sleep_VAR) && size(control_sleep_VAR,1) >= 2, ...
    'group_sleep_var must return a 2-row cell array: {values; label}'.
);
assert(numel(control_sleep_VAR) >= max([total_index stage_indices]), ...
    'Indices exceed available metrics in control_sleep_VAR.'
);
assert(numel(PD_sleep_VAR) >= max([total_index stage_indices]), ...
    'Indices exceed available metrics in PD_sleep_VAR.'
);

% ---------------- Compute % per stage ----------------
figs = gobjects(1,2);

for g = 1:2
    if g == 1
        G = control_sleep_VAR;
        group_name = 'Control';
    else
        G = PD_sleep_VAR;
        group_name = 'PD';
    end

    % Denominator: mean across subjects
    denom = mean(G{1, total_index}, 'omitnan');
    if ~isfinite(denom) || denom <= 0
        error('Total/denominator metric (index %d) is non-positive or missing for %s.', total_index, group_name);
    end

    % Numerators per stage: mean across subjects
    pct = zeros(1, numel(stage_indices));
    for k = 1:numel(stage_indices)
        numk = mean(G{1, stage_indices(k)}, 'omitnan');
        pct(k) = (numk / denom) * 100;
    end
    pct = max(0, min(100, pct)); % clip to [0, 100] for display

    % ---------------- Plot donut ----------------
    figs(g) = figure('Name', sprintf('%s sleep stage proportions', group_name), 'Color', 'w');
    try
        donutchart(pct, stage_labels, 'FaceAlpha', face_alpha, 'FontColor', font_color);
        title(sprintf('%s: REM/N1/N2/N3 (%% of total)', group_name));
    catch
        % Fallback to pie if donutchart is unavailable
        warning('donutchart not found; falling back to pie().');
        pie(pct, stage_labels);
        title(sprintf('%s: REM/N1/N2/N3 (%% of total)', group_name));
    end
end

end
