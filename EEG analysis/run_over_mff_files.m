%% run_over_mff_files
% Author: Saar Lanir-Azaria
% Date: 03/05/2023
%
% This script performs initial preprocessing of EEG sleep data recorded with an EGI high-density system in MFF format.
% The preprocessing steps include filtering, downsampling, and segmentation.
% Sleep stage annotations are imported from a separate CSV file and embedded into the processed data.
% Preprocessed data is saved in MATLAB (.mat) format compatible with FieldTrip (cfg format).
%
% Required toolbox:
% - FieldTrip (credit to FieldTrip developers: https://www.fieldtriptoolbox.org)
%
% IMPORTANT: Replace placeholder paths with your local directories.

%% Load subject file information
clc

% Load subject details
load('<YOUR_PATH>\subjects_files.mat'); % Replace <YOUR_PATH> with the path to your subject files information.

%% Define processing variables
for f = 1:60 % Adjust the indices for your specific subject range
    tic % Start timing the loop iteration

    % Define your directories (replace <YOUR_PATH> with your actual paths)
    data_path_mff = '<YOUR_PATH>\mff_data'; % Directory containing the original MFF files
    data_path_csv = '<YOUR_PATH>\scoring_data'; % Directory containing scoring CSV files

    % Identify specific files
    dataset_file = fullfile(data_path_mff, subjectsfiles.mff_file{f}); % Path to the MFF file for the current subject
    scoring_csv  = subjectsfiles.scoring_csv{f}; % CSV file containing sleep staging annotations
    subject      = subjectsfiles.subject{f}; % Subject identifier
    group        = subjectsfiles.group(f); % Group identifier (e.g., Control vs PD)

    %% Determine save location based on group
    if group == 1
        save_folder = '<YOUR_PATH>\data\all_night_by_stage\control'; % Folder for control group data
    else
        save_folder = '<YOUR_PATH>\data\all_night_by_stage\PD'; % Folder for Parkinson's disease group data
    end

    %% Import sleep stage scoring
    cd(data_path_csv);
    scoring = xlsread(scoring_csv); % Load sleep scoring data from CSV

    %% EEG preprocessing (segmentation, filtering, resampling)
    [data, epoched_scoring] = preper_sleep_data(dataset_file, scoring);
    % Calls a custom-built function (which internally uses FieldTrip functions)
    % to preprocess EEG data. This includes:
    % - Segmentation into epochs
    % - Filtering (basic EEG filtering)
    % - Resampling (downsampling for computational efficiency)

    %% Save preprocessed data
    cd(save_folder);
    save_filename = [subject '_epoched_sleep_DATA.mat'];
    save(save_filename, 'data', 'epoched_scoring', '-v7.3'); % Saves data in cfg-compatible format

    disp(['File saved successfully: ' save_filename]);
    toc % Display processing time
end
