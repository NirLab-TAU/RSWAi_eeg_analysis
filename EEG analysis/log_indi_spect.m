
function [freq_log] = log_indi_spect(freq_data)
Nsub = length(freq_data);
for sub = 1:Nsub
    cfg           = [];
    cfg.parameter = 'powspctrm';
    cfg.operation = 'log10';
    freq_log{1,sub} = ft_math(cfg, freq_data{1,sub});
end
end