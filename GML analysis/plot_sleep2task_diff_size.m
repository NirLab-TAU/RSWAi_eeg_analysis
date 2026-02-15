%% plot_sleep2task_diff_size.m
% Author: Saar Lanir-Azaria
% Date: 03/05/2023
%
% TITLE
% -----
% Size‑weighted scatter plots: GML task improvement vs REM percentage by subgroup
%
% PURPOSE
% -------
% Create a 2x2 panel figure showing the relationship between GML task improvement
% and REM sleep percentage (% of total sleep) across four panels:
%   (1) Controls, (2) PD (overlay PD+RSWA), (3) PD−RSWA, (4) PD+RSWA.
% Point size is scaled by each subject's RSWAi (via RSWAi_2scattSize2), and each panel
% includes a least‑squares regression line with a confidence ribbon. Correlation is
% computed (default Spearman) and can be displayed optionally.
%
% PIPELINE
% --------
% 1) Fetch per‑subject GML task metrics using pre_post_val().
% 2) Fetch per‑subject sleep metrics using group_sleep_var().
% 3) Compute REM% = (REM time / Total sleep time) * 100.
% 4) Map indices for the four panels using groups_indx().
% 5) Draw regression line (regression_ci_saar) and optionally show r, p, 95% CI.
% 6) Render size‑weighted scatter points, overlaying PD+RSWA on PD panels.
%
% INPUTS (set below)
% ------------------
% task_parameter  : integer index of the GML task metric to plot on Y (default 1 = CR improvement)
% rem_index       : index of REM time in group_sleep_var output (default 4)
% total_index     : index of total sleep time in group_sleep_var output (default 3)
% show_coef       : 1 to annotate r, p, CI within panels; 0 to hide
% alpha           : CI level complement (0.05 => 95% CI)
% corr_type       : 'Spearman' (default) or 'Pearson'
%
% OUTPUTS
% -------
% • A figure with four subplots (2x2).
% • RBD_names / nonRBD_names cell arrays with subject IDs used for overlays/reporting.
%
% DEPENDENCIES (project helpers)
% ------------------------------
% • RSWAi_2scattSize2(level)      -> returns cell of scatter sizes per subgroup
% • task_para4plot()              -> returns plotting positions, colors, markers, font sizes
% • groups_indx()                 -> index sets for [Controls, PD pool, PD−RSWA, PD+RSWA]
% • pre_post_val(group, ...)      -> per‑subject GML task metrics
% • group_sleep_var(group)        -> per‑subject sleep metrics
% • Fisher_transf(r, x, alpha)    -> Fisher z confidence interval for correlation
% • regression_ci(alpha,x,y) -> regression line and CI envelopes for plotting
%
% NOTES
% -----
% • Inside pre_post_val(), blocks 2–8 are currently used (block 1 excluded).
%   To revert: open pre_post_val.m and set start_seq = 1.
% • X‑axis is REM% specifically (REM/Total * 100), independent of task_parameter.
% • This figure is descriptive; formal inference belongs in your stats scripts.

%% ----------------- User parameters -----------------
close all; clear;

task_parameter = 1;     % 1 = CR improvement (project‑specific mapping)
rem_index      = 4;     % REM time index in group_sleep_var
total_index    = 3;     % total sleep time index in group_sleep_var
show_coef      = 1;     % annotate r, p, CI in panels
alpha          = 0.05;  % CI level (95% CI)
corr_type      = 'Spearman'; % 'Spearman' (robust) or 'Pearson'

% Point sizes derived from RSWAi (returns a cell with sizes per subgroup)
scattSize = RSWAi_2scattSize(3);

% Appearance helpers (positions, colors, markers, font sizes)
[pos, Lines_Color, fill_colores, markers, all_indx, FS, fill_color] = task_para4plot();

% Axis limits (edit as needed)
Ylim = [-0.5 0.95; -0.7 0.8];          % per task metric index (rows)
Xlim = [0 0; 0 0; 0 0; 0 35; 0 0; 50 315]; % exemplar grid; not all rows used here

task_titles = { ...
    'CR improvement', ...
    'Improvement in response time (s)', ...
    'Improvement in correct response time (s)', ...
    'Improvement in efficiency score' ...
};

%% ----------------- Main figure -----------------
f = figure('Name','GML vs REM% (size = RSWAi)','Color','w');
f.Position = [100 100 1000 600];

for sub_group = 1:4
    % Panel -> group arg for data loading
    if sub_group == 1
        group = 1;   % Controls
    else
        group = 2;   % PD pool
    end

    % ---- Load GML task metrics for this group ----
    [pre_post, nfiles] = pre_post_val(group, 8, 5);

    % Extract mean task metrics per subject (row 1), their names (row 2)
    mean_task_var = cell(2,4);
    for k = 1:4
        vals = nan(1, nfiles);
        for n = 1:nfiles
            vals(1,n) = pre_post{1,k}{1,n}(1,6);  % project‑specific field
            mean_task_var{2,k} = pre_post{2,k};   % labels
            legend_names{n}    = pre_post{1,1}{2,n}; %#ok<AGROW>
        end
        mean_task_var{1,k} = vals;
    end

    % ---- Load sleep metrics for this group ----
    group_sleep_VAR = group_sleep_var(group);

    % Indices for this panel
    idx = all_indx{1, sub_group};

    % Y: chosen GML task measure
    task_var = mean_task_var{1, task_parameter}(1, idx);

    % X: REM percentage of total sleep
    rem_vals   = group_sleep_VAR{1, rem_index}(1, idx);
    total_vals = group_sleep_VAR{1, total_index}(1, idx);
    sleep_var  = (rem_vals ./ total_vals) * 100;

    % Order by X for nicer plotting
    [x, indM] = sort(sleep_var);
    y = task_var(indM);

    % ---- Correlation (display only) ----
    [r, p] = corr(x', y', 'Type', corr_type);

    % Fisher CI + regression CI
    [~, CI_r] = Fisher_transf(r, x, alpha); 
    [top_int, bot_int, X, Y] = regression_ci(alpha, x, y);

    % ---- Panel subplot ----
    subplot('Position', pos(sub_group,:)); hold on;

    % Regression line and CI ribbon
    plot(X, Y, 'k-', 'LineWidth', 1);
    fill([X, fliplr(X)], [top_int, fliplr(bot_int)], fill_color, ...
        'FaceAlpha', 0.1, 'EdgeColor', 'none');

    % Optional text with coefficients
    if show_coef
        text(0.05, 0.97, sprintf('r = %.3f', r), 'Units', 'normalized', 'FontSize', 12);
        text(0.05, 0.89, sprintf('p = %.3g', p), 'Units', 'normalized', 'FontSize', 12);
        text(0.05, 0.81, sprintf('95%% CI: [%.3f, %.3f]', CI_r(1), CI_r(2)), 'Units', 'normalized', 'FontSize', 12);
    end

    % Scatter points (size = RSWAi‑based)
    scatter(sleep_var, task_var, scattSize{1, sub_group}, ...
        'MarkerFaceColor', fill_colores(group,:), ...
        'MarkerEdgeColor', Lines_Color(group,:), ...
        'Marker', markers{1, group});

    % Overlay PD+RSWA subjects on PD panels (2 and 4)
    if sub_group == 2 || sub_group == 4
        idx_RSWA      = all_indx{1, 4};
        task_var_RSWA = mean_task_var{1, task_parameter}(1, idx_RSWA);
        rem_RSWA      = group_sleep_VAR{1, rem_index}(1, idx_RSWA);
        total_RSWA    = group_sleep_VAR{1, total_index}(1, idx_RSWA);
        sleep_var_RSWA = (rem_RSWA ./ total_RSWA) * 100;

        scatter(sleep_var_RSWA, task_var_RSWA, scattSize{1, 4}, ...
            'MarkerFaceColor', fill_colores(group,:), ...
            'MarkerEdgeColor', Lines_Color(3,:), ...
            'Marker', markers{1, group}, ...
            'LineWidth', 2);
        set(gca, 'YTickLabel', [], 'XColor','k', 'FontSize', FS, 'Box','on');
    else
        ylabel('Task Improvement (GML task)', 'Color','k', 'FontSize', FS);
        set(gca, 'XColor','k', 'YColor','k', 'FontSize', FS, 'Box','on');
    end

    % Axes
    if size(Xlim,1) >= 4 && any(Xlim(4,:))
        xlim(Xlim(4,:));
    end
    if task_parameter <= size(Ylim,1) && any(Ylim(task_parameter,:))
        ylim(Ylim(task_parameter,:));
    end
    xlabel('REM %', 'Color','k', 'FontSize', 12);
end

%% ----------------- Names (for reporting) -----------------
RSWA_names    = cell(1, numel(all_indx{1,4}));
nonRSWA_names = cell(1, numel(all_indx{1,3}));
for ii = 1:numel(all_indx{1,4})
    ind = all_indx{1,4}(1, ii);
    RSWA_names{ii} = pre_post{1,1}{2, ind};
end
for ii = 1:numel(all_indx{1,3})
    ind = all_indx{1,3}(1, ii);
    nonRSWA_names{ii} = pre_post{1,1}{2, ind};
end

%% ----------------- (Optional) Save figure -----------------
% out_dir = fullfile('<YOUR_PATH>','figures'); if ~exist(out_dir,'dir'), mkdir(out_dir); end
% saveas(f, fullfile(out_dir, 'GML_vs_REMpct_sizeWeighted.png'));
