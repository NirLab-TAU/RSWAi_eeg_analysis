function scattSize = RSWAi_2scattSize(indx_type, opts)
% RSWAi_2scattSize
% Author: Saar Lanir-Azaria
% Date: 03/05/2023
%
% PURPOSE
% -------
% Convert subject-wise RSWA indices into scatter-point sizes for 4 plotting panels:
%   (1) Controls, (2) PD (pooled), (3) PD−RSWA, (4) PD+RSWA.
% Sizes are linearly scaled within an output range and returned per panel to
% overlay on GML vs sleep plots.
%
% INPUTS
% ------
% indx_type : integer selecting which RSWAi measure to use per subject
%             (e.g., 1 = phasic, 2 = tonic, 3 = any) — depends on your RSWAi files.
% opts      : (optional) struct with fields:
%   • data_path  : folder containing '<suffix>_RSWAi.mat' files (default '<YOUR_PATH>/sleep_staging/RSWA')
%   • factor     : scalar multiplier for sizes (default 6)
%   • out_min    : minimum size before multiplying by factor (default 1)
%   • out_max    : if empty, auto = 0.85*max(all RSWAi); else use provided value
%   • verbose    : true/false to print summary (default false)
%
% OUTPUT
% ------
% scattSize : 1x4 cell where scattSize{1,panel} is a 1xN vector of sizes
%             matching the subject order used by groups_indx() for that panel.
%
% DEPENDENCIES
% ------------
% • groups_indx()             -> returns subject indices per panel
% • subjects_list_names(group)-> returns a suffix used to load '<suffix>_RSWAi.mat'
% • Files: '<suffix>_RSWAi.mat' must contain variable RSWAi with structure
%          RSWAi{1,subject}{1,indx_type}(1,1) -> numeric value
%
% NOTES
% -----
% • No hardcoded CDs; uses fullfile to load required MAT files.
% • If RSWA range is nearly constant, a small spread is enforced to keep markers visible.
% • For consistent appearance across figures, consider fixing out_max rather than auto.

    % -------- Defaults --------
    if nargin < 2, opts = struct(); end
    if ~isfield(opts, 'data_path') || isempty(opts.data_path)
        opts.data_path = fullfile('<YOUR_PATH>', 'sleep_staging', 'RSWA');
    end
    if ~isfield(opts, 'factor') || isempty(opts.factor),   opts.factor = 6;  end
    if ~isfield(opts, 'out_min') || isempty(opts.out_min), opts.out_min = 1; end
    if ~isfield(opts, 'out_max'),                          opts.out_max = []; end
    if ~isfield(opts, 'verbose') || isempty(opts.verbose), opts.verbose = false; end

    % -------- Panel indices --------
    all_indx = groups_indx();  % {1,1}=Controls, {1,2}=PD pooled, {1,3}=PD−RSWA, {1,4}=PD+RSWA

    % Collect RSWAi values per panel
    RSWAi_var = cell(1,4);
    group_spans = zeros(4,2);  % start/stop indices in concatenated vector
    concat_vals = [];

    start_idx = 1;
    for panel = 1:4
        % Map panel to group file suffix (1=controls, else PD)
        if panel == 1
            group_id = 1; % Control
        else
            group_id = 2; % PD
        end

        sub_indx = all_indx{1, panel};
        [~, suffix] = subjects_list_names(group_id);
        matfile = fullfile(opts.data_path, [suffix '_RSWAi.mat']);
        if ~exist(matfile, 'file')
            error('RSWAi_2scattSize2:FileNotFound', 'Cannot find file: %s', matfile);
        end
        S = load(matfile);
        if ~isfield(S, 'RSWAi')
            error('RSWAi_2scattSize2:BadFile', 'File %s does not contain variable RSWAi.', matfile);
        end
        RSWAi = S.RSWAi;

        vals = nan(1, numel(sub_indx));
        for s = 1:numel(sub_indx)
            v = RSWAi{1, sub_indx(s)}{1, indx_type};
            vals(s) = v(1); % expect scalar
        end
        RSWAi_var{1, panel} = vals;

        stop_idx = start_idx + numel(vals) - 1;
        group_spans(panel, :) = [start_idx, stop_idx];
        concat_vals = [concat_vals, vals]; %#ok<AGROW>
        start_idx = stop_idx + 1;
    end

    % -------- Linear scaling to sizes --------
    all_var = concat_vals(:)';
    finite_mask = isfinite(all_var);
    finite_vals = all_var(finite_mask);
    if isempty(finite_vals)
        error('RSWAi_2scattSize2:NoFiniteValues', 'No finite RSWAi values found.');
    end

    data_min = min(finite_vals);
    data_max = max(finite_vals);
    if isempty(opts.out_max) || ~isfinite(opts.out_max)
        out_hi = 0.85 * data_max;  % mimic original heuristic
    else
        out_hi = opts.out_max;
    end
    out_lo = opts.out_min;

    % Edge cases: enforce a reasonable spread
    if ~isfinite(out_hi) || out_hi <= out_lo
        out_hi = out_lo + 1; % ensure strictly increasing
    end
    if data_max <= data_min
        % nearly constant input; use a flat mid size
        scaled = ones(size(all_var)) * ((out_lo + out_hi) / 2);
    else
        % Use MATLAB rescale if available; otherwise manual
        try
            scaled = rescale(all_var, out_lo, out_hi);
        catch
            scaled = (all_var - data_min) ./ (data_max - data_min);
            scaled = scaled * (out_hi - out_lo) + out_lo;
        end
    end

    sizes = scaled * opts.factor;

    % -------- Split back into panels --------
    scattSize = cell(1,4);
    for panel = 1:4
        span = group_spans(panel, :);
        scattSize{1, panel} = sizes(span(1):span(2));
    end

    if opts.verbose
        fprintf('RSWAi_2scattSize: factor=%.2f, out_range=[%.2f, %.2f], data_range=[%.3f, %.3f]\n', ...
            opts.factor, out_lo, out_hi, data_min, data_max);
    end
end
