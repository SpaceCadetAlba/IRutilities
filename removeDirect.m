% This function removes the direct sound from IR.
% This is handy for bulk processing.
% The approach is to use the source and receiver heights, the distance
% between the source and the receiver, and the speed of sound to calculate
% the time difference between direct sound arrival and the shortest path
% reflection (here considered to be the first ground reflection).
% 
% The function finds the direct sound (as the maximim sample value in the
% IR) and estimates the point of the first reflection based on the air
% propegation time difference calculated.
%
% The beginning of the IR is then truncated to the estimated time of first
% reflection, and a linear fade-in of the specified length is added.
%
% Input arguments are:
% sHeight: The height of the source in IR measurement (meters)
% rHeight: The height of the receiver in IR measurement (meters)
% srDist: The distance between the source and receiver in IR measurement
% (meters)
% horDisp: The horizontal displacement of the source and receiver locations
% (meters)
% fadeSize: The size of the linear fade in (seconds)
%
% The truncated IR with direct sound removed, and figure detailing the
% process, are saved.
%
% This function expects .wav files for IR, can handle multichannel, any Fs, 
% and 16 bit or 24 bit res
%
% ~ PC

function removeDirect(sHeight, rHeight, srDist, horDisp, fadeSize)
% Load Audio---------------------------------------------------------------
file = uigetfile; % Choose file
[audio, Fs] = audioread(file); % Load file
info = audioinfo(file);
res = info.BitsPerSample; % Get the resolution
time = (1:length(audio))/Fs; % Create time vector

% Handle the filename for saving data later
filename = info.Filename; % This retains the path so we save to the same folder as the original file
filename = filename(1:end-4); % Remove the .wav

% Pre-processing-----------------------------------------------------------
% Audio
omniCh = audio(:, 1); % Get omnidirectional channel
omniChdB = mag2db(abs(omniCh)); % Convert to dB

% Estimate air propegation delays
tPerMms = 1000/346; % How many ms per meter at the speed of sound

directTime = srDist * tPerMms;  % Estimate the propegation delay for direct sound

halfDisp = horDisp/2; % Estimate the air propegation latency of the 1st reflection
path1 = sqrt((halfDisp^2) + (sHeight^2));
path2 = sqrt((halfDisp^2) + (rHeight^2));
pathFull = path1 + path2;
pathTime = pathFull * tPerMms;

% Estimate the time difference between direct sound arrival and first
% reflection arrival
tDiff = pathTime - directTime; % This is in ms

% Remove the direct sound--------------------------------------------------
% Find the direct sound
[maximum, maximumIndex] = max(omniChdB); % Get direct sound index
indexTime = maximumIndex/Fs; % Note this in time, this is in s

% Estimate the time 1st reflection relative to this direct sound
cutTime = indexTime + (tDiff/1000); % this is in s
cutSamp = round(cutTime * Fs);

% Trim audio to this sample
audioTrimmed = audio(cutSamp:end, :);

% Add the fade-in
windowSize = round(fadeSize * Fs);
fadeEnvelope = linspace(0, 1, windowSize); % generate the linear fade envelope
fadeEnvelope = fadeEnvelope';
fadeAudio = audioTrimmed(1:windowSize, :); % get the frame of audio to apply the fade envelope to
fadeAudio = fadeAudio.* fadeEnvelope; % apply the fade envelope
audioTrimmed(1:windowSize, :) = fadeAudio; % replace the relevant frame in the audio data

% Post Processing----------------------------------------------------------
% Get the omni channel of the processed audio for plotting
omniChTrimmed = audioTrimmed(:, 1);
omniChTrimmeddB = mag2db(abs(omniChTrimmed)); % Convert to dB
timeTrimmed = (1:length(audioTrimmed))/Fs; % Create time vector for plotting the processed audio

% Plots--------------------------------------------------------------------
% Plot the original audio
figure;
subplot(2, 1, 1);
plot(time, omniChdB);
xlim([0 0.05]);
if res == 24
    ylim([-144 0]);
elseif res == 16
    ylim([-96, 0]);
end
hold on
xline(indexTime, 'r--', 'LineWidth', 2); % Mark the direct sound
xline(cutTime, 'c--', 'LineWidth', 2); % Mark the 1st reflection time estimate
ylabel('dBFS');
xlabel('time(s)');
title('Original IR')

% Plot the processed audio
subplot(2, 1, 2);
plot(timeTrimmed, omniChTrimmeddB);
xlim([0 0.05]);
if res == 24
    ylim([-144 0]);
elseif res == 16
    ylim([-96, 0]);
end
ylabel('dBFS');
xlabel('time(s)');
title('Direct Removed IR')

% Save our work------------------------------------------------------------
% Generate Filenames
graphicFilename = sprintf("%s_directRemoveGraphic.jpg", filename);
audioFilename = sprintf("%s_directRemoved.wav", filename);

% Audio
audiowrite(audioFilename, audioTrimmed, Fs, 'BitsPerSample', res);

% Figure
z = gcf;
exportgraphics(z, graphicFilename, 'Resolution', 600); % 600dpi jpegs

end