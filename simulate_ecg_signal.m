close all; clear all; clc;
% https://www.youtube.com/watch?v=mJgXlXH3laM
%% LOAD ECG data from local file
filename = "t54.dat";
fid = fopen(filename, 'r');
ecg_signal = fread(fid, Inf, 'int16');
fclose(fid);

% Extract sampling freq and time vector
fs = 128;
t = (0:length(ecg_signal)-1)/fs;

figure;
%t_5sec = t(t<=5); % adjust time vector to only span the first 5secs
plot(t, ecg_signal(1:length(t)));
xlabel("Time (s)");
ylabel("Amplitude");
title("RAW ECG signal");

% detect R peaks fro segmentation
 [~, test] = findpeaks(ecg_signal);
 num_beats1 = length(test); 
 fprintf("Number of beats in raw signal: %d\n", num_beats1); % Number of beats in signal: 36172
%% Apply Bandpass filter to remove noise
f_low = 5; % Hz
f_high = 15;
[b, a] = butter(2, [f_low, f_high]/(fs/2), 'bandpass');
filtered_signal = filtfilt(b, a, ecg_signal);

% Plot the filtered ECG signal
figure;
plot(t, filtered_signal(1:length(t)));
xlabel("Time (s)");
ylabel("Amplitude");
title("Filtered ECG signal (first 5 sec)");

% detect R peaks fro segmentation
[~, r_locks] = findpeaks(filtered_signal);

% Mark the R peaks on the filtered ECG signal
% hold on;
% plot(t_5sec(r_locks), filtered_signal(r_locks(1:length(t_5sec(r_locks)))), 'ro');
% hold off;

num_beats = length(r_locks);
fprintf("Number of beats in filtered signal: %d\n", num_beats);
% Number of beats in signal: 3629

%% Normalize amplitude to [-1, 1]
normalized_signal = (filtered_signal - min(filtered_signal)) / (max(filtered_signal) - min(filtered_signal)) * 2 -1;

figure;
t_5sec = t(t<5);
plot(t, normalized_signal(1:length(t)));
xlabel("Time (s)");
ylabel("Amplitude");
title("Normalized ECG signal (first 5 sec)");
