%% daviolinplot_RSWAi.m
% Author: Saar Lanir-Azaria
% Date: 03/05/2023
%
% TITLE
% -----
% Violin plots of REM Sleep Without Atonia index (RSWAi) by group
%
% PURPOSE
% -------
% Visualize RSWA indices (phasic, tonic, any) for Controls vs PD participants,
% highlighting subgroup membership (PD−RSWA / PD+RSWA is handled upstream in
% how indices are constructed). This figure is used alongside GML task analyses
% to contextualize sleep physiology.
%
% INPUTS / DATA
% -------------
% • A .mat file (default: 'groups_RSWAi.mat') containing `groups_RSWAi`, a 1x2 cell array:
%     groups_RSWAi{1,1} -> Control subjects (1xNcell), each cell is a 1x3 cell with fields:
%                          {phasic, tonic, any}, each being a numeric scalar or 1x1 array.
%     groups_RSWAi{1,2} -> PD subjects (matching structure)
% • Index sets from `groups_indx()` mapping overall indices to subgroup panels when needed.
%
% DEPENDENCIES (project helpers)
% ------------------------------
% • task_para4plot()  -> colors/markers/fonts (style helpers)
% • groups_indx()     -> indices per subgroup (Control, PD pool, PD−RSWA, PD+RSWA)
% • daviolinplot      -> 3rd-party plotting function (Povilas Karvelis)
%
% NOTES
% -----
% • All paths are generalized; set `data_path` and `mat_file` below.
% • This script does not run inferential stats; add tests if required.
% • RSWA metrics shown here support interpretation of GML task results elsewhere.

%% ----------------- User paths -----------------
data_path = '<YOUR_PATH>';
mat_file  = 'groups_RSWAi.mat';

%% ----------------- Load style helpers -----------------
[pos, Lines_Color, fill_colores, markers, ~, FS] = task_para4plot(); 
all_indx = groups_indx();  % Kept for consistency/reporting; not needed for this figure directly.

% Group labels
group_names = {'Control','PD'};
condition_names = {'phasic','tonic','any'};

%% ----------------- Colors -----------------
% Alternative color scheme (commented)
% c = [0.45 0.80 0.69; 0.98 0.40 0.35; 0.55 0.60 0.79; 0.90 0.70 0.30];

% Current scheme: first row = Control, rows 2–4 use PD hues
c = [ 0.04 0.04 0.74;  ... % Control
      0.64 0.08 0.18;  ... % PD
      0.64 0.08 0.18;  ...
      0.64 0.08 0.18];     

%% ----------------- Load RSWAi matrix -----------------
S = load(fullfile(data_path, mat_file));
if ~isfield(S, 'groups_RSWAi')
    error('The loaded file does not contain variable "groups_RSWAi".');
end
groups_RSWAi = S.groups_RSWAi;

%% ----------------- Assemble data matrices -----------------
RSWA = cell(1,2);    % RSWA{1,g}{1,var} -> vector over subjects
Nsub  = zeros(1,2);
for g = 1:2
    RSWAi = groups_RSWAi{1,g};          % 1xN cell, each {phasic, tonic, any}
    N = numel(RSWAi);
    for v = 1:3
        vec = nan(N,1);
        for s = 1:N
            x = RSWAi{1,s}{1,v};        % numeric scalar or 1x1
            vec(s) = x(1);
        end
        RSWA{1,g}{1,v} = vec;           % store column per condition
    end
    Nsub(g) = N;
end

% Group index vector for daviolinplot (1=Control, 2=PD)
group_inx = [ones(1, Nsub(1)), 2*ones(1, Nsub(2))];

% Concatenate data: rows = subjects, cols = conditions (phasic, tonic, any)
data2 = [ RSWA{1,1}{1,1}(:), RSWA{1,1}{1,2}(:), RSWA{1,1}{1,3}(:); ...
          RSWA{1,2}{1,1}(:), RSWA{1,2}{1,2}(:), RSWA{1,2}{1,3}(:) ];

%% ----------------- Plot -----------------
fig = figure('Name','RSWAi: Control vs PD', 'Color','w');
fig.Position = [100 100 1000 600];

try
    h = daviolinplot(data2, 'groups', group_inx, 'colors', c, 'outliers', 0, ...
        'boxcolors', 'k', 'box', 3, 'boxwidth', 1, 'boxspacing', 1, ...
        'scatter', 2, 'scattersize', 25, 'jitter', 1, 'xtlabels', condition_names); 
catch
    warning('daviolinplot not found. Ensure it is on the MATLAB path.');
end

ylabel('RSWA index (RSWAi)');
xl = xlim; xlim([xl(1)-0.1, xl(2)+0.2]);
ylim([-12.5 52]);
set(gca, 'FontSize', 12, 'Box', 'on', 'XColor', 'k', 'YColor', 'k');

title('RSWAi by group (Control vs PD)');

%% ----------------- (Optional) Save -----------------
% out_dir = fullfile(base_path, 'figures'); if ~exist(out_dir,'dir'), mkdir(out_dir); end
% saveas(fig, fullfile(out_dir, 'RSWAi_PD_vs_Control.png'));
