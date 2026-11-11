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
    [Q_val,Q_loc,R_val,R_pt,S_val,S_loc,P_loc,P_val,TH,w] = thresholding_fen(ecg_bandpass, ecg5, Fs);

    %% DETECTOR 3: WFDB .QRS
    R_wfdb = rdann(recordName,'qrs');       
    R_wfdb = R_wfdb(R_wfdb <= length(ecgWin));  % limit to window
    
    %% ALIGN DETECTIONS --- PT VS WFD &&& MINE VS WFDB
    R_aligned = [];

    for i = 1:length(R_fp)
        candidates = [];
    
        % WFDB match
        diffs_w = abs(R_wfdb - R_fp(i));
        [minW, idxW] = min(diffs_w);
        if minW <= tol
            candidates(end+1) = R_wfdb(idxW);
        end
    
        % Pan–Tompkins match
        diffs_p = abs(R_pt - R_fp(i));
        [minP, idxP] = min(diffs_p);
        if minP <= tol
            candidates(end+1) = R_pt(idxP);
        end
    
        % Always include findpeaks
        candidates(end+1) = R_fp(i);
    
        % Final aligned beat = median of detectors
        if length(candidates) >= 2
            R_aligned(end+1) = round(median(candidates));
        end
    end
    
    R_aligned = unique(R_aligned);
    
    %% Plot
    % Window for my findpeaks
    R_fp_win = R_fp(R_fp >= startSamp & R_fp <= endSamp) - startSamp + 1;
    
    % Window WFDB
    R_wfdb_win = R_wfdb(R_wfdb >= startSamp & R_wfdb <= endSamp) - startSamp + 1;
    
    % Window Pan–Tompkins
    R_pt_win = R_pt(R_pt >= startSamp & R_pt <= endSamp) - startSamp + 1;
    
    % Window aligned
    R_aligned_win = R_aligned(R_aligned >= startSamp & R_aligned <= endSamp) ...
                - startSamp + 1;
    figure;
    plot(ecgPWin,'k'); 
    hold on
    plot(tWin(R_fp_win), ecg_scaled(R_fp_win),'ro')
    plot(tWin(R_wfdb_win), ecg_scaled(R_wfdb_win),'bx')
    plot(tWin(R_pt_win), ecg_scaled(R_pt_win),'m^')
    plot(tWin(R_aligned_win), ecg_scaled(R_aligned_win),'go','LineWidth',1.5)
    ylim([-1 1]);
    legend('ECG','findpeaks','WFDB .qrs','Aligned');
    xlabel('Time (s)'); ylabel('Amplitude (mV)');
    title(['Aligned R peaks for ', recordName]);
    grid on;

    % CALCULATE HRV 
    % RR = diff(R_aligned)/Fs;              % RR intervals in seconds
    % if isempty(RR)
    %     meanRR = NaN; SDNN = NaN; RMSSD = NaN; HR_mean = NaN; NBeats = 0;
    % else
    %     meanRR = mean(RR);
    %     SDNN = std(RR);
    %     RMSSD = sqrt(mean(diff(RR).^2));
    %     HR_mean = mean(60 ./ RR);
    %     NBeats = length(R_aligned);
    % end 
end


% %% proxeiro apo huh.m
% R_PT= R_loc;
% R_final = align_R_peaks(Rlocs, R_PT, Fs);
% 
% fprintf('Number of R-peaks:\nPT=%d, WFDB=%d, aligned=%d\n', length(Rlocs), length(R_PT), length(R_final));
% 
% % Optional: plot
% figure; hold on;
% plot(ecg_clean, 'k');
% plot(Rlocs, ecg_clean(Rlocs), 'r*','MarkerFaceColor','r');
% plot(R_PT, ecg_clean(R_PT), 'bs','MarkerFaceColor','b');
% plot(R_final, ecg_clean(R_final), 'go','MarkerFaceColor','g');
% legend('ECG','FENIA','PT','Aligned');
% xlabel('Samples'); ylabel('Amplitude (mV)');
% title('1ST TRY: R-peak alignment across detectors');
% grid on;
% Bandpass (0.5-40 Hz) -- Pan-Tompkins ----> I DONT LIKE
% % [b,a] = butter(2, [0.5 40]/(Fs/2), 'bandpass');
% % ecgPT = filtfilt(b,a,ecg_bp);
% % 
% % % Derivative, squaring, moving average (Pan-Tompkins)
% % diff_ecg = diff(ecgPT);
% % squared = diff_ecg.^2;
% % window = round(0.15*Fs);  % 150 ms
% % ma = movmean(squared, window);
% % 
% % % Detect peaks
% % minPeakDist = round(0.3*Fs);
% % minPeakHeight = 0.3*max(ma);
% % [RpeaksPT, RlocsPT] = findpeaks(ma, 'MinPeakDistance', minPeakDist, 'MinPeakHeight', minPeakHeight);
% % 
% % % Plot
% % % figure;
% % % plot(tWin, ecgWin); hold on;
% % % plot(tWin(RlocsPT), ecgWin(RlocsPT), 'ro','MarkerFaceColor','r');
% % % title('Pan-Tompkins R-peaks');
% % % xlabel('Time (s)'); ylabel('mV'); grid on;
% % 
% % R_PT= R_loc;
% % R_final = align_R_peaks(Rlocs, RlocsPT, Fs);
% % 
% % fprintf('Number of R-peaks:\nPT=%d, WFDB=%d, aligned=%d\n', length(Rlocs), length(RlocsPT), length(R_final));
% % 
% % % Optional: plot
% % figure; hold on;
% % plot(ecg_clean, 'k');
% % plot(Rlocs, ecg_clean(Rlocs), 'r*','MarkerFaceColor','r');
% % plot(RlocsPT, ecg_clean(RlocsPT), 'bs','MarkerFaceColor','b');
% % plot(R_final, ecg_clean(R_final), 'go','MarkerFaceColor','g');
% % legend('ECG','FENIA','RlocsPT','Aligned');
% % xlabel('Samples'); ylabel('Amplitude (mV)');
% % title('R-peak alignment across detectors');
% grid on;