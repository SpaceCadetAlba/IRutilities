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
audioFilename = sprintf("%s_adjusted_%dto%d.wav", basefilename, round(1000*rtOrig), round(1000*rtDesired));
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

% Save the figure
figName = sprintf("%s_decayAdjustmentGraphic_%dto%d.jpg", basefilename, round(1000*rtOrig), round(1000*rtDesired));
z = gcf;
exportgraphics(z, figName, 'Resolution', 600);

end

