% This function is handy for bulk truncation of IR from start of audio file
% to direct sound

% This is done by
%   - search for max loudness
%   - trim audio to T before peak loudness
%   - where T is preRing, defined in seconds
%   - adding a linear fade in of length T/2 from the start of the audio
%   file

% Multichannel formats can be handled - however trim times are based on a
% single channel defined by cH (example: for mono or ambisonic we may use
% cH = 1, however for stereo or binaural formats we may wish to use cH = 1
% or 2 for IR measured with source in the left or right hemisphere
% respectively).

% This is scripted working with wavs. See Line 89 where the '.wav' extension
% is trimmed from the base filename in the creation of filenames for trimmed
% audio and for graphics. If you are using other types of audio files, you
% might want to edit this line to chop of the correct amount of characters
% to remove the relevant extension from your base filename. This script
% also save audio as wavs, as defined in Line 91. If you are working with
% other file types you may want to change this too.

% This script will handle 16 and 24 bit audio resolutions.

% ~ PC

function directTruncate(preRing, cH)

% Load Audio---------------------------------------------------------------
file = uigetfile; % Choose file
[audio, Fs] = audioread(file); % Load file
info = audioinfo(file);
res = info.BitsPerSample; % Get the resolution
time = (1:length(audio))/Fs; % Create time vector

omniCh = audio(:, cH); % Get channel

omniChdB = mag2db(abs(omniCh)); % Convert to dB

[maximum, maximumIndex] = max(omniChdB); % Get direct sound index
indexTime = maximumIndex/Fs; % Note this in time

% Trim start of audio file to direct sound with pre-ring
windowSize = round(preRing*Fs); % Get size of pre-ring window
audioTrimmed = audio((maximumIndex-windowSize):end, :); % Trim audio

% Add fade in
fadeWindow = round(windowSize/2); % Fade in is half the size of the pre-ring
fadeEnvelope = linspace(0, 1, fadeWindow); % Create linear amp env
fadeEnvelope = fadeEnvelope'; % Make column to match audio
fadeAudio = audioTrimmed(1:fadeWindow, :); % Grab the audio to process
fadeAudio = fadeAudio.*fadeEnvelope; % Apply the envelope
audioTrimmed(1:fadeWindow, :) = fadeAudio; % Replace the unprocessed frame w the processed frame

audioTrimmeddB = mag2db(abs(audioTrimmed(:, cH))); % Grab channel and convert to dB for plotting
trimTime = (1:length(audioTrimmed))/Fs; % Get time vector for plotting

% Plot original and processed audio----------------------------------------
subplot(2, 1, 1)
plot(time, omniChdB); % Original audio
xlim([0 0.1]); % only show the 1st 100ms to see the edit made
if res == 24 % the ylims (dynamic range) depends on the resolution
    ylim([-144 0]);
elseif res == 16
    ylim([-96, 0]);
end
ylabel('dBFS');
xlabel('time(s)');
title('Original IR')
hold on
xline(indexTime, 'r--', 'LineWidth', 2); % Mark where we have truncated to
hold off

subplot(2, 1, 2)
plot(trimTime, audioTrimmeddB); % Plot the processed audio
xlim([0 0.1]);
if res == 24
    ylim([-144 0]);
elseif res == 16
    ylim([-96, 0]);
end
ylabel('dBFS');
xlabel('time(s)');
title('Truncated IR')

% Save the data------------------------------------------------------------
% Get the filename
filename = info.Filename; % This retains the path so we save to the same folder as the original file
filename = filename(1:end-4); % Remove the .wav
graphicFilename = sprintf("%s_truncationGraphic.jpg", filename);
audioFilename = sprintf("%s_directTruncated.wav", filename);

% Figure
z = gcf;
exportgraphics(z, graphicFilename, 'Resolution', 600); % 600dpi jpegs

% Audio
audiowrite(audioFilename, audioTrimmed, Fs, 'BitsPerSample', res);

end