close all; clear all; clc;
% https://www.youtube.com/watch?v=Eh2142LSLIc

% LOAD ECG data from local file
filename = "n10c.dat";
fid = fopen(filename, 'r');
ecg = fread(fid, Inf, 'int16');
fclose(fid);

% Extract sampling freq and time vector
fs = 128;
t = (0:length(ecg)-1)/fs;

figure
subplot(3,1,1)
plot(t, ecg(1:length(t)));
xlabel("Time (s)");
ylabel("Amplitude");
title("RAW ECG signal");

% Low pass filte design
filterOrder = 10;
cutOffFreq = 18;
[b, a] = butter(filterOrder, cutOffFreq/(fs/2), 'low');
[h, w] = freqz(b, a);
subplot(3,1,2)
plot(w/pi*fs/2, abs(h), '-');
title("Low-Pass Magnitude response");
grid on

% Apply the filter to the ECG signal
filteredEcg = filter(b, a, ecg);
subplot(3,1,3)
plot(t, filteredEcg(1:length(t)));
xlabel("Time (s)");
ylabel("Amplitude");
title("Low-Pass Filtered ECG signal");

% HIGH pass filte design
filterOrder = 10;
cutOffFreq = 4;
[b, a] = butter(filterOrder, cutOffFreq/(fs/2), 'high');
[h, w] = freqz(b, a);
figure;
subplot(2,1,1)
plot(w/pi*fs/2, abs(h), '-');
title("high-Pass Magnitude response");
grid on

% Apply the filter to the ECG signal
highfilteredEcg = filter(b, a, ecg);
subplot(2,1,2)
plot(t, highfilteredEcg(1:length(t)));
xlabel("Time (s)");
ylabel("Amplitude");
title("high-Pass Filtered ECG signal");

% Localize R-waveforms

[pks, locs] = findpeaks(highfilteredEcg);
threshold = 2*(rms(highfilteredEcg));
Rwave = pks>threshold;

R_waveform = zeros(size(highfilteredEcg));
R_waveform(locs(Rwave)) = max(highfilteredEcg);
figure;
subplot(2,1,2)
plot(highfilteredEcg)
hold on
stem(R_waveform, 'r', '*');
title("Location  of r-waves")