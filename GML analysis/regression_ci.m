function [top_int, bot_int, X, Y] = regression_ci(alpha, x, y)
% regression_ci
% Author: Saar Lanir-Azaria
% Date: 03/05/2023
%
% PURPOSE
% -------
% Compute a simple least-squares regression line y = b0 + b1*x and return the
% predicted line and its confidence interval envelopes for plotting.
% This wrapper avoids toolbox-specific code and delegates CI computation to the
% project helper `regression_line_ci`.
%
% INPUTS
% ------
% alpha : (optional) confidence level complement for the CI; default 0.05 (i.e., 95% CI)
% x     : vector of predictor values
% y     : vector of response values (same length as x)
%
% OUTPUTS
% -------
% top_int : 1xN vector, upper confidence envelope evaluated at X
% bot_int : 1xN vector, lower confidence envelope evaluated at X
% X       : 1xN vector of x-coordinates used to draw the line/CI (spanning data range)
% Y       : 1xN vector of fitted regression line values at X
%
% FUNCTIONS CALLED
% ----------------
% • regression_line_ci(alpha, BETA, x, y, Npts)  (project helper)
%   where BETA = [b0 b1] = [intercept slope]
%
% NOTES
% -----
% • Uses ordinary least squares via POLYFIT (no Statistics Toolbox required).
% • NaN/Inf pairs are removed prior to fitting.
% • The CI calculation is handled inside regression_line_ci.
%
% EXAMPLE
% -------
%   [top, bot, X, Y] = regression_ci_saar(0.05, x, y);
%   plot(X, Y, 'k-'); hold on;
%   fill([X, fliplr(X)], [top, fliplr(bot)], [0.5 0.5 0.5], 'FaceAlpha', 0.1, 'EdgeColor', 'none');

    % --- Defaults & validation ---
    if nargin < 1 || isempty(alpha), alpha = 0.05; end
    if nargin < 3
        error('Usage: regression_ci_saar(alpha, x, y)');
    end
    x = x(:); y = y(:);
    ok = isfinite(x) & isfinite(y);
    x = x(ok); y = y(ok);
    if numel(x) < 2
        error('Need at least two finite (x,y) pairs to fit a line.');
    end

    % --- Ordinary least squares fit (slope & intercept) ---
    p = polyfit(x, y, 1);        % p(1)=slope, p(2)=intercept
    BETA = [p(2), p(1)];         % [intercept slope]

    % --- Confidence envelopes & line sampling ---
    Npts = 100;                  % resolution for plotting
    [top_int, bot_int, X, Y] = regression_line_ci(alpha, BETA, x, y, Npts);
end
