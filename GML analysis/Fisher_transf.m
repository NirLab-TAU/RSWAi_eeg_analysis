function [CI_z, CI_r] = Fisher_transf(r,x,alpha)
%Saar Lanir-Azaria 20/05/2024
% Calculate Fisher's z transformation
    z = atanh(r);
% Calculate standard error of z
    n = length(x);
    SE_z = 1/sqrt(n-3);
% Calculate critical value for desired confidence level (e.g., 95%)
    z_alpha = norminv(1-alpha/2);
% Calculate confidence interval for z
    CI_z = z + [-1, 1] * z_alpha * SE_z;
% Back-transform confidence interval for r
    CI_r = tanh(CI_z);
end