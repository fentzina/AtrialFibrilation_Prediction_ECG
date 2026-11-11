close all; clear all; clc;
% PROCESS BOTH LEADS OF 1 SIGNAL

% METADATA
recordName = 'p02c'; % 'p37c'; %'t54'; % ESTW

[signals, Fs, units] = wfdbdesc(recordName);  % Read header information
numLeads = length(signals); % Number of leads

% SIGNAL
[ecg, Fs, t] = rdsamp(recordName);
startTime = 60;    % seconds
winLen = 10;        % seconds
startSamp = startTime * Fs;
endSamp   = startSamp + winLen * Fs;
tWin   = t(startSamp:endSamp);
preR = round(0.2*Fs);   % 200 ms before R for P-wave start
postR = round(0.05*Fs); % 50 ms before R for P-wave end
tol = round(0.05*Fs);   % 50 ms tolerance for alignment - part 3

ecgWin = zeros(size(ecg));

for i=1:numLeads
    %%plot RAW ECG
    ecgWin = ecg(startSamp:endSamp, i); % i want to check a part of the whole ECG.

    hold off;
    figure;
    plot(tWin, ecgWin,'k','LineWidth',1.2)
    ylim([-1 1]);
    grid on;
    title(['Raw ECG of ' recordName ' - Lead ' num2str(i)]);
    xlabel('Time (s)');
    ylabel('Amplitude (mV)');

    %% Denoising
    % Remove baseline wander
    % usage: [filtered_signal, baseline]=ECG_Baseline_Removal(signal,samplerate,window_length,overlap)
    [ecg_filtered_baseline, ~] = ECG_Baseline_Removal(ecg, Fs, 1, 0.5);

    figure;
    ecgWin = ecg_filtered_baseline(startSamp:endSamp, i);
    plot(tWin, ecgWin, 'k', 'LineWidth', 1.2); 
    ylim([-1 1]);
    grid on;
    title(['Baseline Removal of ' recordName ' - Lead ' num2str(i)]);
    xlabel('Time (s)');
    ylabel('Amplitude (mV)');

    % filter noise frequencies
    % frequencies are already optimized for ECG signals (literature values):
    % Lowpass: 120 Hz, Highpass: 0.3 Hz, Bandstop (49-51 Hz)
    [ecg_filtered_frq] = ECG_High_Low_Filter(ecg, Fs, 1, 40);
    ecg_filtered_frq = Notch_Filter(ecg_filtered_frq, Fs, 50, 1);
    
    % visualizing waveforms
    ecgWin = ecg_filtered_frq(startSamp:endSamp, i);

    figure; %ax3 = subplot(4,1,3);
    plot(tWin, ecgWin, 'k', 'LineWidth', 1.2); 
    ylim([-1 1]);
    grid on;
    title(['Highpass, Lowpass, Bandstop cleared ' recordName ' - Lead ' num2str(i)]);
    xlabel('Time (s)');
    ylabel('Amplitude (mV)');
    % linkaxes([ax1, ax2, ax3],'xy')
    
    % isoline correction
    % usage: [filteredsignal,offset,frequency_matrix,bins_matrix]=Isoline_Correction(signal,varargin)
    [ecg_filtered_isoline, offset, ~, ~] = Isoline_Correction(ecg_filtered_frq);
    
    ecgWin = ecg_filtered_isoline(startSamp:endSamp, i);
    % ax4 = subplot(4,1,4);
    figure;
    plot(tWin, ecgWin, 'k', 'LineWidth', 1.2); 
    ylim([-1 1]);
    grid on;
    title(['Isoline Correction of ' recordName ' - Lead ' num2str(i)]);
    xlabel('Time (s)');
    ylabel('Amplitude (mV)');
    % linkaxes([ax1, ax2, ax3, ax4],'xy')

    %% Band pass filter, for QRS Detection
    [b, a] = butter(2,[5 15]/(Fs/2),'bandpass'); % Use bandpass 5-15 Hz to enhance QRS
    ecg_bandpass = filtfilt(b, a, ecg_filtered_isoline);
    
    ecgWin = ecg_bandpass(startSamp:endSamp, i);
    figure;
    plot(tWin, ecgWin, 'k', 'LineWidth', 1.2);
    xlabel('Time (s)');
    ylabel('ECG Amplitude');
    title(['Band pass filter from Lead ' num2str(i)]);
    ylim([-1 1]);
    grid on;

    %% Normalization / Scaling
    % ecg_clean: is your denoised ECG; Fully denoised ECG (baseline, high-freq
    % noise, notch) ==> Use for feature extraction: P-wave amplitude, T-wave 
    % amplitude, RR intervals, and ML input. Normalizing here preserves all waves.
    ecg_scaled = (ecg_bandpass(:,i) - min(ecg_bandpass)) ./ (max(ecg_bandpass) - min(ecg_bandpass));
    ecg_scaled = ecg_scaled * 2 - 1;  % now in [-1, 1]

    % %% Feature calculation
    % % produce FPT Table
    % % usage: [FPT_MultiChannel,FPT_Cell]=Process_ECG_Multi(signal,samplerate,varargin)
    % [FPT_MultiChannel, FPT_Cell] = Annotate_ECG_Multi(ecg_filtered_isoline, Fs);
    % 
    % % extract FPTs for Channel i (Lead I and II):
    % FPT_Lead_i = FPT_Cell{i,1};
    % 
    % Pwave_samples = reshape(FPT_Lead_i(:,1:3), [1,size(FPT_Lead_i(:,1:3),1)*size(FPT_Lead_i(:,1:3),2)]);
    % QRS_samples = reshape([FPT_Lead_i(:,4),FPT_Lead_i(:,6), FPT_Lead_i(:,8)] , [1,size(FPT_Lead_i(:,1:3),1)*size(FPT_Lead_i(:,1:3),2)]);
    % Twave_samples = reshape(FPT_Lead_i(:,10:12), [1,size(FPT_Lead_i(:,10:12),1)*size(FPT_Lead_i(:,10:12),2)]);
    % 
    % % visualize fiducial points
    % figure; 
    % ecgWin = ecg_filtered_isoline(startSamp:endSamp, i); %plot(ecg_filtered_isoline(:,2));
    % plot(ecgWin, 'k', 'LineWidth', 1.2);
    % hold on;
    % ylim([-1 1]);
    % grid on;
    % xlabel('Time (s)');
    % ylabel('Amplitude (mV)');
    % validIdx = Pwave_samples >= 1 & Pwave_samples <= size(ecgWin,1);
    % Pwave_samples = Pwave_samples(validIdx);
    % scatter(Pwave_samples, ecgWin(Pwave_samples,1), 'g', 'filled');
    % 
    % validIdx = QRS_samples >= 1 & QRS_samples <= size(ecgWin,1);
    % QRS_samples = QRS_samples(validIdx);
    % scatter(QRS_samples, ecgWin(QRS_samples,1), 'r', 'filled');
    % 
    % validIdx = Twave_samples >= 1 & Twave_samples <= size(ecgWin,1);
    % Twave_samples = Twave_samples(validIdx);
    % scatter(Twave_samples, ecg_filtered_isoline(Twave_samples,1), 'b', 'filled');
    % title(['Filtered ECG of ' recordName ' - Lead ' num2str(i)]);
    % xlabel('samples'); ylabel('voltage');
    % legend({'ECG', 'P', 'QRS', 'T'});

    %% R-peak detection using peak finding ---- fenia
    minPeakHeight = 0.3 * max(ecg_scaled(:,i)); % 0.3 * max(ecg_QRS);
    minPeakDist   = round(0.25 * Fs);  % 300 ms refractory period
    
    [Rpeaks, Rlocs] = findpeaks(ecg_scaled(:,i), ...
        'MinPeakHeight', minPeakHeight, ...
        'MinPeakDistance', minPeakDist);
    
    ecgR_Win = ecg_scaled(startSamp:endSamp, i);
    inWindow = Rlocs >= startSamp & Rlocs <= endSamp;
    R_locWin = Rlocs(inWindow) - startSamp + 1;  % adjust to ecgR_Win indexing
    
    % Plot
    figure;
    plot(tWin, ecgR_Win,'k'); hold on
    plot(tWin(R_locWin), ecgR_Win(R_locWin),'ro','MarkerFaceColor','r') % R peaks in window
    ylim([-1 1]);
    grid on;
    title(['R-peak Detection of Lead ' num2str(i)]);
    xlabel('Time (s)');
    ylabel('Amplitude (mV)');
    
    %% Delineation ECG
    Q_locs = zeros(size(Rlocs));
    S_locs = zeros(size(Rlocs));
    P_locs = zeros(size(Rlocs));
    T_locs = zeros(size(Rlocs));
    for x = 1:length(Rlocs)
        r = Rlocs(x);
    
        % Q wave (minimum before R)
        q_range = max(r - round(0.04*Fs), 1) : r;
        [~, q_idx] = min(ecg_scaled(q_range));
        Q_locs(x) = q_range(q_idx);
    
        % S wave (minimum after R)
        s_range = r : min(r + round(0.06*Fs), length(ecg_scaled));
        [~, s_idx] = min(ecg_scaled(s_range));
        S_locs(i) = s_range(s_idx);
    
        % P wave (maximum before R)
        p_range = max(r - round(0.2*Fs), 1) : max(r - round(0.08*Fs), 1);
        [~, p_idx] = max(ecg_scaled(p_range));
        P_locs(x) = p_range(p_idx);
        
        % T wave (maximum after R)
        t_range = min(r + round(0.1*Fs), length(ecg_scaled)) : ...
                  min(r + round(0.4*Fs), length(ecg_scaled));
        [~, t_idx] = max(ecg_scaled(t_range));
        T_locs(x) = t_range(t_idx);
    
    end
    
    ecgQ_Win = ecg_scaled(startSamp:endSamp,i);
    inWindow = Q_locs >= startSamp & Q_locs <= endSamp;
    Q_locWin = Q_locs(inWindow) - startSamp + 1;  % adjust to ecgPWin indexing
    
    ecgS_Win = ecg_scaled(startSamp:endSamp,i);
    inWindow = S_locs >= startSamp & S_locs <= endSamp;
    S_locWin = S_locs(inWindow) - startSamp + 1;  % adjust to ecgPWin indexing
    
    ecgPWin = ecg_scaled(startSamp:endSamp,i);
    inWindow = P_locs >= startSamp & P_locs <= endSamp;
    P_locWin = P_locs(inWindow) - startSamp + 1;  % adjust to ecgPWin indexing
    
    ecgT_Win = ecg_scaled(startSamp:endSamp,i);
    inWindow = T_locs >= startSamp & T_locs <= endSamp;
    T_locWin = T_locs(inWindow) - startSamp + 1;  % adjust to ecgPWin indexing
    
    figure;
    plot(tWin, ecgPWin,'k'); hold on
    plot(tWin(R_locWin), ecgR_Win(R_locWin),'ro','MarkerFaceColor','r') % R peaks in window
    plot(tWin(P_locWin), ecgPWin(P_locWin),'mo','MarkerFaceColor','m') % P peaks in window
    plot(tWin(Q_locWin), ecgQ_Win(Q_locWin), 'go','MarkerFaceColor','g')
    plot(tWin(S_locWin), ecgS_Win(S_locWin), 'go','MarkerFaceColor','g')
    plot(tWin(T_locWin), ecgT_Win(T_locWin), 'co','MarkerFaceColor','c')
    ylim([-1 1]);
    grid on;
    legend('ECG','R','P','Q', "", 'T')
    title(['ECG Deliniation of Lead ' num2str(i)]);
    xlabel('Time (s)');
    ylabel('Amplitude (mV)');
    % hold off;   


    %% DETECTOR 1: FINDPEAKS DIKO MOY VS WFDB
    R_fp = Rlocs;
    %% DETECTOR 2: PAN TOMPKINS
    % Derivative Operation %%
    ecg_out3=differentiator(ecg_bandpass);
    % squaring operation %%
    ecg_out4=squaring(ecg_out3);    
    % Integration operation %%
    ecg5=integration(ecg_out4);
    % Thresholding operation - Pan tompkins
    [Q_val,Q_loc,R_val,R_PT,S_val,S_loc,P_loc,P_val,TH,w] = thresholding_fen(ecg_bandpass, ecg5, Fs);

    % %% proxeiro apo huh.m
% R_PT= R_pt;
R_final = align_R_peaks(Rlocs, R_PT, Fs);

fprintf('Number of R-peaks:\nPT=%d, WFDB=%d, aligned=%d\n', length(Rlocs), length(R_PT), length(R_final));

% Optional: plot
figure; hold on;
plot(ecg5, 'k');
plot(Rlocs, ecg5(Rlocs), 'r*','MarkerFaceColor','r');
plot(R_PT, ecg5(R_PT), 'bs','MarkerFaceColor','b');
plot(R_final, ecg5(R_final), 'go','MarkerFaceColor','g');
legend('ECG','FENIA','PT','Aligned');
xlabel('Samples'); ylabel('Amplitude (mV)');
title('1ST TRY: R-peak alignment across detectors');
grid on;
% % Bandpass (0.5-40 Hz) -- Pan-Tompkins ----> I DONT LIKE
% [b,a] = butter(2, [0.5 40]/(Fs/2), 'bandpass');
% ecgPT = filtfilt(b,a,ecg_bandpass);
% 
% % Derivative, squaring, moving average (Pan-Tompkins)
% diff_ecg = diff(ecgPT);
% squared = diff_ecg.^2;
% window = round(0.15*Fs);  % 150 ms
% ma = movmean(squared, window);
% 
% % Detect peaks
% minPeakDist = round(0.3*Fs);
% minPeakHeight = 0.3*max(ma);
% [RpeaksPT, RlocsPT] = findpeaks(ma, 'MinPeakDistance', minPeakDist, 'MinPeakHeight', minPeakHeight);
% 
% R_PT= R_loc;
% R_final = align_R_peaks(Rlocs, RlocsPT, Fs);
% 
% fprintf('Number of R-peaks:\nMine=%d, PT=%d, aligned=%d\n', length(Rlocs), length(RlocsPT), length(R_final));
% 
% % Optional: plot
% figure; hold on;
% plot(ecg_bandpass, 'k');
% plot(Rlocs, ecg_bandpass(Rlocs), 'r*','MarkerFaceColor','r');
% plot(RlocsPT, ecg_bandpass(RlocsPT), 'bs','MarkerFaceColor','b');
% plot(R_final, ecg_bandpass(R_final), 'go','MarkerFaceColor','g');
% legend('ECG','FENIA','RlocsPT','Aligned');
% xlabel('Samples'); ylabel('Amplitude (mV)');
% title('R-peak alignment across detectors');
% grid on;
    %% CALCULATE HRV 
    RR = diff(R_final)/Fs;              % RR intervals in seconds
    if isempty(RR)
        meanRR = NaN; SDNN = NaN; RMSSD = NaN; HR_mean = NaN; NBeats = 0;
    else
        meanRR = mean(RR);
        SDNN = std(RR);
        RMSSD = sqrt(mean(diff(RR).^2));
        HR_mean = mean(60 ./ RR);
        NBeats = length(R_final);
    end
    
    %% --- SAVE RESULTS ---
    % Results.Record(r) = recordName;
    % Results.MeanRR(r) = meanRR;
    % Results.SDNN(r) = SDNN;
    % Results.RMSSD(r) = RMSSD;
    % Results.MeanHR(r) = HR_mean;
    % Results.NBeats(r) = NBeats;
    
    %% OPTIONAL: plot a few records 
    if r <= 1 %length(records)
        figure;
        plot(tWin, ecg5,'k'); hold on;
        plot(tWin(R_fp), ecg5(R_fp),'ro','MarkerSize',6);
        plot(tWin(R_wfdb), ecg5(R_wfdb),'bx','MarkerSize',6);
        plot(tWin(R_final), ecg5(R_final),'go','MarkerSize',7,'LineWidth',1.5);
        legend('ECG','findpeaks','WFDB .qrs','Aligned');
        xlabel('Time (s)'); ylabel('Amplitude (mV)');
        title(['R-peaks for ', recordName]);
        grid on;
    end

    %% (5) P-WAVE FEATURES (time + frequency) 
    nBeats = length(R_final);
    Pwaves = cell(nBeats,1);
    TimeFeatures = table('Size',[nBeats,5],...
        'VariableTypes',{'double','double','double','double','double'},...
        'VariableNames',{'Duration_s','Amplitude_mV','Area_mVs','SlopeMax','SlopeMin'});
    FreqFeatures = table('Size',[nBeats,3],...
        'VariableTypes',{'double','double','double'},...
        'VariableNames',{'DominantFreq_Hz','Power_0_5Hz','Power_5_10Hz'});

    for i = 1:nBeats
        idxStart = max(R_final(i)-preR,1);
        idxEnd   = max(R_final(i)-postR,1);
        Pwaves{i} = ecg5(idxStart:idxEnd);

        Pwave = Pwaves{i};
        % Time-domain
        TimeFeatures.Duration_s(i) = length(Pwave)/Fs;
        TimeFeatures.Amplitude_mV(i) = max(Pwave)-min(Pwave);
        TimeFeatures.Area_mVs(i) = trapz(Pwave)/Fs;
        TimeFeatures.SlopeMax(i) = max(diff(Pwave))*Fs;
        TimeFeatures.SlopeMin(i) = min(diff(Pwave))*Fs;

        % Frequency-domain
        N = length(Pwave);
        Y = fft(Pwave);
        P2 = abs(Y/N);
        P1 = P2(1:floor(N/2)+1);
        f = Fs*(0:floor(N/2))/N;

        [~, idxMax] = max(P1);
        FreqFeatures.DominantFreq_Hz(i) = f(idxMax);
        FreqFeatures.Power_0_5Hz(i) = sum(P1(f<=5).^2);
        FreqFeatures.Power_5_10Hz(i) = sum(P1(f>5 & f<=10).^2);
    end

    % Averaged P-wave
    maxLen = max(cellfun(@length,Pwaves));
    Pmatrix = zeros(nBeats,maxLen);
    for i=1:nBeats
        Pmatrix(i,:) = interp1(1:length(Pwaves{i}),Pwaves{i},linspace(1,length(Pwaves{i}),maxLen));
    end
    Pwave_mean = mean(Pmatrix,1);

    % Time-domain features for average
    P_avg_Duration = length(Pwave_mean)/Fs;
    P_avg_Amplitude = max(Pwave_mean)-min(Pwave_mean);
    P_avg_Area = trapz(Pwave_mean)/Fs;
    P_avg_SlopeMax = max(diff(Pwave_mean))*Fs;
    P_avg_SlopeMin = min(diff(Pwave_mean))*Fs;

    % Frequency-domain features for average
    N = length(Pwave_mean);
    Y = fft(Pwave_mean);
    P2 = abs(Y/N);
    P1 = P2(1:floor(N/2)+1);
    f = Fs*(0:floor(N/2))/N;
    [~, idxMax] = max(P1);
    P_avg_DominantFreq = f(idxMax);
    P_avg_Power_0_5Hz = sum(P1(f<=5).^2);
    P_avg_Power_5_10Hz = sum(P1(f>5 & f<=10).^2);

    %% --- DISPLAY EXAMPLES FOR THIS RECORD ---
    fprintf('\n=== P-wave features for record: %s ===\n', recordName);
    disp('--- Beat-to-beat time-domain features (first 5 beats) ---')
    disp(TimeFeatures(1:min(5,nBeats),:))
    disp('--- Beat-to-beat frequency-domain features (first 5 beats) ---')
    disp(FreqFeatures(1:min(5,nBeats),:))
    disp('--- Averaged P-wave features ---')
    fprintf('Duration: %.3f s, Amplitude: %.3f mV, Area: %.3f mVs\n', ...
        P_avg_Duration, P_avg_Amplitude, P_avg_Area)
    fprintf('SlopeMax: %.3f, SlopeMin: %.3f\n', P_avg_SlopeMax, P_avg_SlopeMin)
    fprintf('DominantFreq: %.2f Hz, Power0-5Hz: %.4f, Power5-10Hz: %.4f\n', ...
        P_avg_DominantFreq, P_avg_Power_0_5Hz, P_avg_Power_5_10Hz)
end

%% SHOW RESULTS 
% disp(Results);
% 
% % Separate groups n* VS p*
% ResultsTable = table(Results);
% group = contains(Results.Record,'p'); % logical: 1 for p*, 0 for n*
% 
% HR_n = Results.MeanHR(~group);
% HR_p = Results.MeanHR(group);
% 
% SDNN_n = Results.SDNN(~group);
% SDNN_p = Results.SDNN(group);
% 
% RMSSD_n = Results.RMSSD(~group);
% RMSSD_p = Results.RMSSD(group);
% 
% %% (6)  1. Boxplots of HRV metrics 
% figure; 
% subplot(1,3,1)
% boxplot([HR_n; HR_p],[zeros(size(HR_n)); ones(size(HR_p))], 'Labels',{'n*','p*'})
% ylabel('Mean HR (bpm)')
% title('Mean Heart Rate')
% 
% subplot(1,3,2)
% boxplot([SDNN_n; SDNN_p],[zeros(size(SDNN_n)); ones(size(SDNN_p))], 'Labels',{'n*','p*'})
% ylabel('SDNN (s)')
% title('SDNN')
% 
% subplot(1,3,3)
% boxplot([RMSSD_n; RMSSD_p],[zeros(size(RMSSD_n)); ones(size(RMSSD_p))], 'Labels',{'n*','p*'})
% ylabel('RMSSD (s)')
% title('RMSSD')
% 
% sgtitle('HRV metrics comparison: n* vs p*')
% 
% %% (6) 2. Histogram of RR intervals per group 
% RR_n = [0.68+0.01*randn(1,88), 0.50+0.01*randn(1,120)]; % n05 + n06c
% RR_p = [0.43+0.02*randn(1,138), 0.77+0.02*randn(1,78)]; % p36c + p37c
% 
% figure;
% histogram(RR_n,0.4:0.02:0.8,'FaceColor','b','FaceAlpha',0.5); hold on;
% histogram(RR_p,0.4:0.02:0.8,'FaceColor','r','FaceAlpha',0.5);
% xlabel('RR interval (s)')
% ylabel('Count')
% title('Histogram of RR intervals: n* vs p*')
% legend('n*','p*')
% grid on;