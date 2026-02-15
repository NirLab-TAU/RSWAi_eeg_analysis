%% prep_REM_data.m
% Author: Saar Lanir-Azaria
% Date: 03/05/2023
%
% This script applies advanced preprocessing to EEG sleep data using FieldTrip toolbox functions.
% It performs detailed artifact removal, including visual inspection, artifact rejection,
% ICA-based artifact component removal, and channel interpolation.
%
% Required toolbox:
% - FieldTrip (credit to FieldTrip developers: https://www.fieldtriptoolbox.org)
%
% IMPORTANT: Replace placeholders with your local directories and specify the bad channels/components per subject.

%% Define subject-specific variables
subject     = 'AB11'; % Replace with your subject ID
save_folder = '<YOUR_PATH>\data\post_ICA_data'; % Replace with your save path
files_folder = '<YOUR_PATH>\data\all_night_by_stage\epoched'; % Replace with your data path

%% Add necessary paths (Adjust to your local paths)

%% Load data (Assuming the preprocessed data is loaded into variable "data")
cd(files_folder)
load(subject);
trl = data.cfg.trl;

%% Select REM stage epochs only
REM_CODE = 100;
cfg = [];
cfg.trials = find(trl(:,3) == REM_CODE);
data_REM = ft_selectdata(cfg, data);

%% User-specified artifact removal parameters (Adjust manually per subject)
cfg = [];
cfg.channel = 1:10; 
cfg.viewmode = 'vertical';
%cfg.artfctdef.badChann.artifact     = [];
ft_databrowser(cfg, data_REM);

%% User-specified artifact removal parameters (Adjust manually per subject)
bad_chn = {}; % Example: {'E219'; 'E236'; 'E246'};

% Removing user-specified bad eyes channels
if ~isempty(bad_chn)
    cfg = [];
    cfg.channel = setdiff(data.label(:), bad_chn);
    data_REM = ft_selectdata(cfg, data_REM);
end

keep_track.removed_bad_chn = bad_chn;

%% Remove artifacts visually  (for REM sleep stage)
cfg = [];
cfg.keeptrial = 'nan'; %string, determines how to deal with trials that are not selected.'no'= completely remove deselected trials from the data (default)
cfg.keepchannel = 'nan';
clean_REM = ft_rejectvisual(cfg, data_REM); % REM

%% Document removed trials
all_trials = (clean_REM.sampleinfo(:,1));
artifact = (clean_REM.cfg.artfctdef.summary.artifact(:,1));
artifact_trials = [];
for a = 1:length(artifact)
    artifact_trials(a) = find(all_trials == artifact(a));
end
trials2use = setdiff((1:length(all_trials)), artifact_trials);
keep_track.removed_trials = artifact_trials;
[chan2use, artifact_chan] = detect_nan_chan(clean_REM,trials2use);
keep_track.removed_channels = artifact_chan;

%%
cfg =[];
cfg.trials = trials2use;
data_4componentanalysis1 = ft_preprocessing(cfg,clean_REM);
[data_4componentanalysis2]=Fix_bad_Chann(data_4componentanalysis1);
cfg =[];
cfg.reref         = 'yes';
cfg.refchannel    =  chan2use;% 
data_4componentanalysis3 = ft_preprocessing(cfg,data_4componentanalysis2);

%% ICA artifact removal (adjust per subject)
numcomponent = 100;% Adjust based on data complexity
cfg = [];
cfg.method = 'runica';
cfg.numcomponent = numcomponent; 
ica_data = ft_componentanalysis(cfg, clean_REM);

%% Visualize ICA components to decide manually which to remove
plot_top_comp(ica_data, 80);

%% User-specified ICA components to remove (Adjust per subject)
remove_comp = []; % Example: [19 21 22 28];
cfg = [];
cfg.component = remove_comp;
data_post_ICA = ft_rejectcomponent(cfg, ica_data, clean_REM);
keep_track.remov_ICAcomp = remov_comp; 
keep_track.numICAcomp = numcomponent; 

%% Save preprocessed data
cd(save_folder);
save([subject '_clean_REM.mat'], 'data_post_ICA', '-v7.3');
disp('File saved successfully.');
