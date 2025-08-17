%% plot_top_comp.m
% Author: Saar Lanir-Azaria
% Date: 03/05/2023
%
% This function plots the topographies of ICA components for visual inspection,
% and opens a FieldTrip databrowser for manual exploration.
%
% INPUTS:
%   comp      - the output structure from ft_componentanalysis
%   num_comp  - number of components to visualize
%
% OUTPUT:
%   databrowser - handle to the opened FieldTrip databrowser
%
% Required:
% - FieldTrip toolbox
% - A layout file matching the EEG setup (loaded below)
%
% IMPORTANT: Set path to your layout files folder before running.

function [databrowser] = plot_top_comp(comp, num_comp)

close all;
x_lim = [-0.3 0.1];
zlim = 'maxmin';

%% User must specify the path to their layout files
layout_path = '<YOUR_PATH>/EEG_analysis/templates'; % <-- Adjust this path

load(fullfile(layout_path, 'lay.mat'));
layout = lay; % use layout depending on your montage

%% Plot ICA components topographically
if num_comp <= 41
    figure(1)
    cfg = [];
    cfg.xlim = x_lim;
    cfg.component = 1:(num_comp/2);
    cfg.zlim = zlim;
    cfg.layout = layout;
    cfg.comment = 'no';
    ft_topoplotIC(cfg, comp);

    figure(2)
    cfg.component = ((num_comp/2)+1):num_comp;
    ft_topoplotIC(cfg, comp);

else
    figure(1)
    cfg = [];
    cfg.xlim = x_lim;
    cfg.component = 1:20;
    cfg.layout = layout;
    cfg.zlim = zlim;
    cfg.comment = 'no';
    ft_topoplotIC(cfg, comp);

    figure(2)
    cfg.component = 21:40;
    ft_topoplotIC(cfg, comp);

    figure(3)
    cfg.component = 41:num_comp;
    ft_topoplotIC(cfg, comp);
end

%% Open FieldTrip databrowser for component inspection
cfg = [];
cfg.channel = 1:10;
cfg.layout = layout;
cfg.viewmode = 'component';
cfg.allowoverlap = 'yes';
cfg.preproc.demean = 'yes';
cfg.preproc.detrend = 'yes';

databrowser = ft_databrowser(cfg, comp);

end
