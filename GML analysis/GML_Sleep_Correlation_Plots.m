%% GML_Sleep_Correlation_Plots.m
% Author: Saar Lanir-Azaria
% Date: 03/05/2023
%
% Correlating GML task improvement with sleep parameters (by subgroup)
%
% PURPOSE
% -------
% Create 2x2 panel plots showing the relationship between a selected GML task
% improvement metric and a selected sleep parameter, across four subject panels:
%   (1) Controls, (2) PD (overlaying PD+RSWA), (3) PD−RSWA, (4) PD+RSWA.
% Each panel shows scatter points, a least-squares regression line, and its
% confidence interval.
%
% WHAT THIS SCRIPT DOES
% ---------------------
% • Pulls subject-wise pre/post GML task metrics via pre_post_val().
% • Pulls subject-wise sleep metrics via group_sleep_var().
% • Selects a task metric (task_parameter) and a sleep metric (sleep_parameter).
% • Uses groups_indx() to address the four panels (index sets per subgroup).
% • Computes Pearson r, Fisher CI, and regression CI (for plotting only).
% • Highlights PD+RSWA subjects overlayed on PD panels.
%
% INPUTS (set below)
% ------------------
% task_parameter   : integer selecting the GML task improvement metric index
% sleep_parameter  : integer selecting the sleep metric index
% show_coef        : 1 to print r, p, 95% CI text in panels; 0 to hide
% alpha            : CI level for Fisher & regression intervals (e.g., 0.05)
% Xlim, Ylim       : axis limits per metric (optional, can keep defaults)
%
% OUTPUTS
% -------
% • A figure with four subplots (2x2) saved/displayed.
% • Variables RBD_names and nonRBD_names capturing the subject IDs used.
%
% DEPENDENCIES (project helpers)
% ------------------------------
% • task_para4plot()       -> returns subplot positions, colors, markers, font size
% • groups_indx()          -> returns index sets per subgroup for addressing panels
% • pre_post_val(group, ...) -> returns pre/post GML task metrics per subject
% • group_sleep_var(group) -> returns sleep metrics per subject
% • Fisher_transf(r, x, a) -> Fisher z CI for correlation
% • regression_ci(a,x,y) -> regression line and CI envelopes for plotting
%
% CITATIONS / CREDIT
% ------------------
% • FieldTrip toolbox if used by the called helpers.
% • (Leave a placeholder here to cite the manuscript when accepted.)

%% ----------------- User parameters -----------------
close all; clear;

% NOTE: Inside pre_post_val(), blocks 2–8 are currently used (block 1 excluded).
% To revert, open pre_post_val.m, line ~14, and set start_seq = 1.

task_parameter  = 1;   % 1=CR improvement; see 'task_titles' below for mapping
sleep_parameter = 6;   % 4=REM time, 6=N2 time, 8=NREM time (example mapping from your project)
show_coef       = 0;   % 1 to print r, p, CI in the panels
alpha           = 0.05; % CI for Fisher & regression
fill_color      = [0.5 0.5 0.5];

% Appearance helpers (positions, colors, markers, font sizes)
[pos, Lines_Color, fill_colores, markers, ~, FS] = task_para4plot();

% Group index sets for the 4 panels
all_indx = groups_indx();

% Axis label presets (edit if needed)
Ylim = [-0.5 0.95; -0.7 0.8]; % per task metric index (first two rows as example)
Xlim = [0 0; 0 0; 0 0; 0 135; 0 0; 50 315]; % per sleep metric index (example)

task_titles = { ...
    'CR improvement', ...
    'Improvement in response time (s)', ...
    'Improvement in correct response time (s)', ...
    'Improvement in efficiency score' ...
};

%% ----------------- Main figure -----------------
f = figure('Name','GML vs Sleep (by subgroup)','Color','w');
f.Position = [100 100 1000 600];

for sub_group = 1:4
    % Map panel to group arg for data loading
    if sub_group == 1
        group = 1; % Controls
    else
        group = 2; % PD pool
    end

    % ---- Load GML task pre/post metrics for this group ----
    % NOTE: pre_post_val(group, 8, 5) signature is project-defined. Keep as-is.
    [pre_post, nfiles] = pre_post_val(group, 8, 5);

    % Extract mean task metrics per subject (row 1), their names (row 2)
    mean_task_var = cell(2,4);
    for k = 1:4
        for n = 1:nfiles
            mean_task_var{1,k}(1,n) = pre_post{1,k}{1,n}(1,6); % task metric selection (project-specific)
            mean_task_var{2,k}      = pre_post{2,k};           % label(s)
            legend_names{n}         = pre_post{1,1}{2,n};      
        end
    end

    % ---- Load sleep metrics for this group ----
    group_sleep_VAR = group_sleep_var(group);

    % Select the panel’s subject indices and variables
    task_var  = mean_task_var{1, task_parameter}(1, all_indx{1, sub_group});
    sleep_var = group_sleep_VAR{1, sleep_parameter}(1, all_indx{1, sub_group});

    % Sort by sleep_var (for nicer plotting order)
    [x, indM] = sort(sleep_var);
    y = task_var(indM);

    % ---- Statistics for display (Pearson r; Fisher CI; regression CI) ----
    [r, p] = corr(x', y', 'Type', 'Pearson');
    [CI_z, CI_r]       = Fisher_transf(r, x, alpha); 
    [top_int, bot_int, X, Y] = regression_ci(alpha, x, y);

    % ---- Panel plotting ----
    subplot('Position', pos(sub_group,:)); hold on;

    % Regression line
    plot(X, Y, 'k-', 'LineWidth', 1); hold on;

    % Confidence ribbon
    fill([X, fliplr(X)], [top_int, fliplr(bot_int)], fill_color, ...
        'FaceAlpha', 0.1, 'EdgeColor', 'none');

    % Optional text with coefficients
    if show_coef
        text(0.05, 0.97, sprintf('r = %.3f', r), 'Units', 'normalized', 'FontSize', 12);
        text(0.05, 0.89, sprintf('p = %.3g', p), 'Units', 'normalized', 'FontSize', 12);
        text(0.05, 0.81, sprintf('95%% CI: [%.3f, %.3f]', CI_r(1), CI_r(2)), 'Units', 'normalized', 'FontSize', 12);
    end

    % Scatter points for the panel’s subgroup
    scatter(sleep_var, task_var, 60, ...
        'MarkerFaceColor', fill_colores(group,:), ...
        'MarkerEdgeColor', Lines_Color(group,:), ...
        'Marker', markers{1, group});

    % Overlay PD+RSWA points on PD panels (2 and 4)
    if sub_group == 2 || sub_group == 4
        task_var_RSWA  = mean_task_var{1, task_parameter}(1, all_indx{1, 4});
        sleep_var_RSWA = group_sleep_VAR{1, sleep_parameter}(1, all_indx{1, 4});
        scatter(sleep_var_RSWA, task_var_RSWA, 80, ...
            'MarkerFaceColor', fill_colores(group,:), ...
            'MarkerEdgeColor', Lines_Color(3,:), ...
            'Marker', markers{1, group}, ...
            'LineWidth', 2);
        set(gca,'YTickLabel', [], 'XColor','k', 'FontSize', FS);
    else
        ylabel('Task Improvement (GML task)', 'Color','k', 'FontSize', FS);
        set(gca, 'XColor','k','YColor','k','FontSize',FS);
    end

    % Axes & labels
    if sleep_parameter <= size(Xlim,1) && any(Xlim(sleep_parameter,:))
        xlim(Xlim(sleep_parameter,:));
    end
    if task_parameter <= size(Ylim,1) && any(Ylim(task_parameter,:))
        ylim(Ylim(task_parameter,:));
    end
    xlabel(group_sleep_VAR{2, sleep_parameter}, 'Color','k', 'FontSize', 12);
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
% saveas(f, fullfile('<YOUR_PATH>','figures','GML_sleep_correlation.png'));
