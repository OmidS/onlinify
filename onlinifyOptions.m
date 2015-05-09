function userSettings = onlinifyOptions()
% If you want any option to be set to its default value, simply do not
% include it in userSettings (comment that line)

userSettings = struct();
userSettings.fileReplay = 1;                % Do you want to read from a BCI2000 Data file instead of Fieldtrip
userSettings.processingBlockSec = 60;       % Length of the signal blocks given to processSignal (in seconds)
userSettings.dataFolderPath = 'C:\BCI2000\data\'; % Absolute or relative (to MATLAB's current directory) path to the folder containing BCI2000 dat file
userSettings.dataFile = 'samplefiles\eeg1_1.dat'; % the BCI2000 dat file you want to read from (from the dataFolderPath)
% userSettings.showResultsBox = 1;          % Enable/Disable the all results' strip
% userSettings.showEachOutput = 0;          % Enable/Disable the latest result box
% userSettings.samplingRate = 128;          % Sampling rate of the device (only needed in Fieldtrip mode)
% userSettings.numOfChannels = 14;          % Number of channels recorded by the device (only needed in Fieldtrip mode)
% userSettings.verbose = 1;                 % Onlinify only reports inportant things in the command window if this is set to 0 (Default: 1)

end