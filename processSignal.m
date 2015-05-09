function [ws, resultString] = processSignal(ws, signalProcessingBlock)
% processSignal
% Do your data processing on this block of data here
%
% signalProcessingBlock is a C in X matrix containing the latest signal
% block (C rows are representative of the C Channels of the signal and X cols are representative of the X samples of each channel)
% 
% If you need to store data and information to use in later function calls
% for future signal blocks, store them in the ws struct. The ws struct
% won't be touched by onlinify and will be again passed to processSignal
% next time it is called (when a new block is available)
% 
% ws initially is populated with a settings field which contains the
% onlinify settings at the time of processSignal's first call 
% 
% Possible usage include but are not limited to: 
% 1. Storing several blocks for processing
% 2. Storing counters and settings variables
% 3. Passing additional settings to your processing block by declaring
% additional fields in onlinifyOptions


% Example usage of "ws"
if ~isfield(ws, 'processSignalCallCount'), ws.processSignalCallCount = 0; end
ws.processSignalCallCount = ws.processSignalCallCount + 1;

% Example usage of "ws.settings"
Fs = ws.settings.samplingRate;           % Sampling Rate of the Signal
numOfChans = ws.settings.numOfChannels;  % Number of Channels

% Preare a string result to append to the Result String (Optional)
allPosibleOutputs = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
resultString = allPosibleOutputs(randi(length(allPosibleOutputs)));
end