% This function provides decay envelope adjustment based upon original and
% desired T30 values.
%
% The inputs are:
%   - rtOrig -> the original T30 of the IR (defined in seconds)
%   - rtDesired -> the desired T30 for the adjusted IR (defined in seconds)
%   - startTime -> the time from which attenuation of the IR is applied
%   (defined in seconds)
%
% For multichannel formats the attenuation envelope will be applied equally
% to all channels.
%
% Only wavs are handled
%
% A wav is saved with modified filename for the output IR
% A graphic detailing the mixing time and showing the original and modified
% IR is also output.
%
% This method of decay envelope adjustment is an implementation of the
% algorithm detailed in:Cabrera, Densil & Lee, Doheon & Yadav, Manuj & Martens,...
% William. (2011). Decay envelope manipulation of room impulse responses: ...
% Techniques for auralization and sonification. Australian Acoustical Society ...
% Conference 2011, Acoustics 2011: Breaking New Ground.
%
% ~PC

function decayAdjust(rtOrig, rtDesired, startTime)

% Load Audio---------------------------------------------------------------
file = uigetfile; % Choose file
[audio, Fs] = audioread(file); % Load file

info = audioinfo(file);
res = info.BitsPerSample; % Get the resolution

lengthSamples = size(audio, 1); % get n channels
nChannels = size(audio, 2); % get n samples

% Get delta values for envelope -------------------------------------------
delta1 = 6.91/rtOrig; % In s
delta2 = 6.91/rtDesired; % In s

% Process Audio------------------------------------------------------------
% Make an empty matrix to store the adjusted audio in
audioMod = zeros(lengthSamples, nChannels);

% Get the start sample for decay envelope mod
startSample = round(startTime * Fs); % In ms

% Fill in the unmodified frame of audio
audioMod(1:startSample, :) = audio(1:startSample, :);

% Apply the envelope-------------------------------------------------------
% for each channel
for k = 1:nChannels
    % for each sample
    for i = startSample:lengthSamples
        t = (i-1)/Fs;
        ampEnv = exp(-t*(delta2-delta1));
        audioMod(i, k) = audio(i, k) * ampEnv;
    end
end

% Save the adjusted IR as wav----------------------------------------------
% Generate a filename
basefilename = info.Filename;
basefilename = basefilename(1:end-4);
audioFilename = sprintf("%s_adjusted_%dto%d_mt%d.wav", basefilename, round(1000*rtOrig), round(1000*rtDesired), round(1000*startTime));
audiowrite(audioFilename, audioMod, Fs, 'BitsPerSample', res);

% Plot the original and adjusted audio-------------------------------------
origOmnidB = mag2db(abs(audio(:, 1)));
modOmnidB = mag2db(abs(audioMod(:, 1)));

time = (1:length(audio))/Fs; % Create time vector

figure;
subplot(2, 1, 1);
plot(time, origOmnidB);
if res == 24
    ylim([-144 0]);
elseif res == 16
    ylim([-96, 0]);
end
xlim([0 round(lengthSamples/Fs)]);
ylabel('dBFS');
xlabel('time(s)');
title('Original audio')
xline(startTime, '--r');

subplot(2, 1, 2);
plot(time, modOmnidB);
if res == 24
    ylim([-144 0]);
elseif res == 16
    ylim([-96, 0]);
end
xlim([0 round(lengthSamples/Fs)]);
ylabel('dBFS');
xlabel('time(s)');
title('Decay adjusted audio')
xline(startTime, '--r');

% Save the figure
figName = sprintf("%s_decayAdjustmentGraphic_%dto%d_mt%d.jpg", basefilename, round(1000*rtOrig), round(1000*rtDesired), round(1000*startTime));
z = gcf;
exportgraphics(z, figName, 'Resolution', 600);

end

