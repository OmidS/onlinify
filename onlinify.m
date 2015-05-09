% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Onlinify Version 2013.11.06
% Onlinify is an application based on BCI2000 and Fieldtrip
% It is made to make creating online BCI applications a piece of cake!
% This file expects two functions from the user (BCI creator):
% function resultString = processSignal(signal)
% function userSettings = onlinifyOptions()
% For more info please read Onlinify Help.txt

% by Omid Ghasemsani - omidsani@gmail.com
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% tidying up the workspace
clear all
close all
fclose all;
clc


userSettings = struct();
if (exist('onlinifyOptions.m', 'file') == 2)
    userSettings = onlinifyOptions();
end

settings = struct();
settings.fileReplay = 0;
settings.processingBlockSec = 60;
settings.dataFolderPath = 'C:\BCI2000\data\'; % Absolute or relative (to MATLAB's current directory) path to the folder containing BCI2000 dat file
settings.dataFile = 'samplefiles\eeg1_1.dat'; % the BCI2000 dat file you want to read from (from the dataFolderPath)
settings.showResultsBox = 1;
settings.showEachOutput = 0;
settings.showEachOutputPauseTime = 1;
settings.samplingRate = 128;
settings.numOfChannels = 14;
settings.verbose = 1;
    
for fieldName = fieldnames(userSettings)'
    if (isfield(settings, fieldName{1})), settings.(fieldName{1}) = userSettings.(fieldName{1}); end
end




% Temp Inits
samplingRate = settings.samplingRate;
numOfChannels = settings.numOfChannels;

processingBlock = samplingRate * settings.processingBlockSec;


oneSec = 0.1; % time factor (for file replay)
fromFieldTrip = 1;
if (settings.fileReplay), fromFieldTrip = 0; end


if (fromFieldTrip == 1)
    bufferAddress = 'buffer://localhost:1972';
    oneSec = 1;
end

if (settings.showResultsBox == 1)
    screens = get(0,'MonitorPositions');
    resBoxWidth = screens(end,3)-screens(end,1)+1+2;
    resBoxHeight = 125;
    typeBoxOuterPosition = [screens(end,1)-1 screens(1,4)-screens(end,2)+1-resBoxHeight+20 resBoxWidth resBoxHeight];
    % typeBoxOuterPosition = [1366 663 1282 125];
    % typeBoxOuterPosition = [1600 800 1278 125];
    typeBoxFontSize = resBoxHeight/2;
    typeBoxTitleMargin = resBoxWidth;
    typeBoxHandle = figure('Name','Result','NumberTitle','off','OuterPosition',typeBoxOuterPosition,'Resize','off','Toolbar','none','MenuBar','none','DockControls','off');
    title('Result: ','FontName','Times New Roman','fontSize',typeBoxFontSize,'fontWeight','bold','HorizontalAlignment','center','VerticalAlignment','middle','BackgroundColor','k','color','w','margin',typeBoxTitleMargin);
    drawnow
end
if (settings.showEachOutput == 1)
    screenWidth = screens(end,3)-screens(end,1)+1;
    screenHeight = screens(end,4);
    charDetBoxWidth = 300;
    charDetBoxHeight = 300;
%     charDetBoxOuterPosition = [1600+500 250 300 300];
    charDetBoxOuterPosition = [screens(end,1)-1+screenWidth/2-charDetBoxWidth/2 screens(1,4)-screens(end,2)+1-screenHeight/2-charDetBoxHeight/2 charDetBoxWidth charDetBoxHeight];
    charDetBoxFontSize = charDetBoxHeight/2;
    charDetBoxTitleMargin = charDetBoxWidth;
    charDetBoxHandle = figure('Name','','NumberTitle','off','OuterPosition',charDetBoxOuterPosition,'Resize','off','Toolbar','none','MenuBar','none','DockControls','off','Visible','off');
    title('C','FontName','Times New Roman','fontSize',charDetBoxFontSize,'fontWeight','bold','HorizontalAlignment','center','VerticalAlignment','middle','BackgroundColor','k','color','w','margin',charDetBoxTitleMargin);
    drawnow
    charDetBoxPauseTime = settings.showEachOutputPauseTime;
    pause on
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Preparing some other stuff
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% loading data file
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (fromFieldTrip == 1)
else
    dataFile = sprintf('%s%s', settings.dataFolderPath, settings.dataFile);
    fprintf(1,'Loading data file from: %s\n', dataFile );
    fid = fopen(dataFile);
    if (fid ~= -1) % filter file exists
        fclose(fid);
        [ allSignal, allStates, allParameters , totalSamples, fileSamples ] = load_bcidat( dataFile );
        fprintf(1, 'data file successfully loaded.\n');
        
        if (isfield(allParameters, 'SamplingRate') && isfield(allParameters.SamplingRate, 'NumericValue') && allParameters.SamplingRate.NumericValue)
            settings.samplingRate = allParameters.SamplingRate.NumericValue;
            fprintf(1, 'samplingRate was set to %.2fHz according to the data file...\n', settings.samplingRate);
        end
        if (settings.numOfChannels ~= size(allSignal, 2))
            settings.numOfChannels = size(allSignal, 2);
            fprintf(1, 'numOfChannels was set to %d according to the data file...\n', settings.numOfChannels);
        end
    else
        error('data file could not be opened!\n');
    end
end    

% Some Temp Inits
samplingRate = settings.samplingRate;
numOfChannels = settings.numOfChannels;

processingBlock = samplingRate * settings.processingBlockSec;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The buffer simulation process [Filedtrip ready]
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (fromFieldTrip == 1)
    % Waiting for fieldtrip to turn on
    fprintf('Waiting for ready signal from FieldTrip...\n');
    fieldTripReady = 0;
    while (~fieldTripReady)
        try
            fieldTripReady = 1;
            % read the header for the first time to determine number of channels and sampling rate
            hdr = ft_read_header(bufferAddress, 'cache', true);
        catch err
            fieldTripReady = 0;    
        end
        tic;
        while (toc < 1)
            % Wait!
        end
        fprintf('.');
    end
    
    count      = 0;
    prevSample = 0;
    samplingRate = hdr.Fs;
    blocksize  = samplingRate;
    numOfChannels   = hdr.nChans;
    chanindx   = 1:numOfChannels; 
    seqStart   = 1;
    lastProcessedSample = 0;
else
    count      = 0;
    prevSample = 0;
    % blocksize  = hdr.Fs;
    blocksize  = samplingRate;
    %1:hdr.nChans;
    chanindx   = 1:numOfChannels; 
    seqStart   = 1;    
    lastProcessedSample = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Start Online Processing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic;
while true
    noDataPeriod = toc;        
    if (fromFieldTrip == 1) % Getting signal from field trip buffer
        % determine number of samples available in buffer
        hdr = ft_read_header(bufferAddress, 'cache', true);

        % see whether new samples are available
        newsamples = (hdr.nSamples*hdr.nTrials-prevSample);
        
        if (noDataPeriod > 30), error('No data for more than 30s. Exiting...'); end
        
    else % Getting signal from a file
        if (noDataPeriod > (blocksize/samplingRate*oneSec*60) && (prevSample+blocksize>=size(allSignal,1)) )
            fprintf('\nNo data for too much time. (File ended)...\n');
            break; % Get out of the while
        end

        if ( (noDataPeriod > oneSec) && (prevSample+blocksize<size(allSignal,1)) )
            newsamples = blocksize; 
        else
            newsamples = 0;
        end

    end
    
    if (newsamples >= blocksize)
        % Determine the samples to process
        begsample  = prevSample+1;
        endsample  = prevSample+blocksize;

        % Remember up to where the data was read
        prevSample  = endsample;
        count       = count + 1;
    %     fprintf('processing segment %d from sample %d to %d\n', count, begsample, endsample);

        % Read data segment from buffer
        if (fromFieldTrip == 1) % Getting signal from field trip buffer    
            dat = ft_read_data(bufferAddress, 'header', hdr, 'begsample', begsample, 'endsample', endsample, 'chanindx', chanindx);
            signal(begsample:endsample, chanindx) = dat';
        else % Getting signal from a file
            trialLength = 1000/1000*samplingRate;
            if (endsample+trialLength <= size(allSignal,1))
                dat = allSignal(begsample:endsample+trialLength, chanindx)';
                signal(begsample:endsample+trialLength, chanindx) = dat';    
            else
                dat = allSignal(begsample:endsample, chanindx)';
                signal(begsample:endsample, chanindx) = dat';
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % subsequently the data can be processed
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % create a matching time-axis
        time = (begsample:endsample)/samplingRate;%/hdr.Fs;

        % My Experiments
        if (settings.verbose)
            if (mod(time(end),10) == 1), fprintf('\nTime: '); end
            fprintf('% 5.0f  ', time(end));
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Call the processSignal function if a complete sequence has been recorded
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        availableNewSamples = endsample - (lastProcessedSample+1) + 1;
        if (availableNewSamples >= processingBlock)
            if (settings.verbose)
                fprintf('\nA complete sequence detected! [%d - %d]\n', lastProcessedSample+1, lastProcessedSample + processingBlock);
            end

            signalProcessingBlock = signal((lastProcessedSample+1):(lastProcessedSample + processingBlock), :)';
            lastProcessedSample = lastProcessedSample + processingBlock;
            
            if (~exist('ws', 'var')), ws = struct('settings', settings); end % Initialize inner workspace if not exists
            [ws, resultString] = processSignal(ws, signalProcessingBlock);

            if (~exist('resultStringAccumulate', 'var')), resultStringAccumulate = ''; end
            resultStringAccumulate = [resultStringAccumulate resultString];
            
            if (settings.verbose)
                fprintf(1,'\nThis Block Result: %s\n', resultString);
                fprintf(1,'All Results: %s\n', resultStringAccumulate);
            end

            if (settings.showResultsBox == 1)
                set(0,'CurrentFigure',typeBoxHandle);
                textToShow = resultStringAccumulate;
                title(textToShow,'FontName','Times New Roman','fontSize',typeBoxFontSize,'fontWeight','bold','HorizontalAlignment','center','VerticalAlignment','middle','BackgroundColor','k','color','w','margin',typeBoxTitleMargin);
                drawnow
            end
            if (settings.showEachOutput == 1)
                set(0,'CurrentFigure',charDetBoxHandle);
                title(resultString,'FontName','Times New Roman','fontSize',charDetBoxFontSize,'fontWeight','bold','HorizontalAlignment','center','VerticalAlignment','middle','BackgroundColor','k','color','w','margin',charDetBoxTitleMargin);
                drawnow
                set(charDetBoxHandle, 'Visible', 'on');
%                 oldPauseState = pause('on'); % Backup the current MATLAB pause state (on or off)
                pause(charDetBoxPauseTime);
%                 pause(oldPauseState); % Restore the original MATLAB pause state
                set(charDetBoxHandle, 'Visible', 'off');
            end

            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Clean Up the Saved data of the last Sequence
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % only keep the latest second of data
    % % % %         signal = dat'; NOR READY
            if (settings.verbose)
                fprintf('Time: ');
            end
        end

        tic; % for no data period counting    
    end % if new samples available
end % while true