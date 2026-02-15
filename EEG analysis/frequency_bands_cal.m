%% Sub-function: Computes power spectrum using FieldTrip
function [data_freq] = frequency_bands_cal(data, method, freq)

    epoch_length = length(data.trial{1}) / data.fsample;
    time_win = 2;  % length of each window in seconds
    frequency_res = freq(1):1/time_win:freq(2);

    cfg = [];
    cfg.output = 'pow';
    cfg.foi = frequency_res;
    cfg.feedback = 'none';
    cfg.channel = 'all';

    switch method
        case 1  % Boxcar
            cfg.method = 'mtmfft';
            cfg.taper = 'boxcar';
            data_freq = ft_freqanalysis(cfg, data);

        case 2  % Hanning
            cfg.method = 'mtmfft';
            cfg.taper = 'hanning';
            data_freq = ft_freqanalysis(cfg, data);

        case 3  % DPSS
            cfg.method = 'mtmfft';
            cfg.taper = 'dpss';
            cfg.tapsmofrq = 2;
            cfg.foilim = freq;
            cfg.padtype = 'zero';
            data_freq = ft_freqanalysis(cfg, data);

        case 4  % Morlet wavelets
            cfg.method = 'wavelet';
            cfg.toi = 1:time_win:epoch_length-1;
            cfg.pad = 'nextpow2';
            data_freq = ft_freqanalysis(cfg, data);

        case 5  % Multitaper convolution, average time
            cfg.method = 'mtmconvol';
            cfg.taper = 'hanning';
            cfg.toi = 1:time_win:epoch_length-1;
            cfg.t_ftimwin = 3 ./ frequency_res;
            data_TFR = ft_freqanalysis(cfg, data);

            sel = [];
            sel.trials = 'all';
            sel.avgoverchan = 'no';
            sel.avgoverfreq = 'no';
            sel.avgovertime = 'yes';
            sel.avgoverrpt = 'no';
            sel.nanmean = 'yes';
            data_freq = ft_selectdata(sel, data_TFR);

        case 6  % Multitaper convolution, average trial
            cfg.method = 'mtmconvol';
            cfg.taper = 'hanning';
            cfg.toi = 1:time_win:epoch_length-1;
            cfg.t_ftimwin = ones(length(cfg.toi), 1) .* time_win;
            data_TFR = ft_freqanalysis(cfg, data);

            sel = [];
            sel.trials = 'all';
            sel.avgoverchan = 'no';
            sel.avgoverfreq = 'no';
            sel.avgovertime = 'no';
            sel.avgoverrpt = 'yes';
            sel.nanmean = 'yes';
            data_freq = ft_selectdata(sel, data_TFR);

        otherwise
            error('Unknown method. Choose 1–6.');
    end
end
