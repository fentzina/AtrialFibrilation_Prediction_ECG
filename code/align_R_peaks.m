function R_corrected = align_R_peaks(R1, R2, Fs)
% ALIGN_R_PEAKS Aligns R-peaks from two detectors using a tolerance window
% Inputs:
%   R1, R2 : R-peak indices from two detectors
%   Fs     : sampling frequency
% Output:
%   R_corrected : aligned and merged R-peaks

tolerance_sec = 0.05; % 50 ms
tolSamples = round(tolerance_sec * Fs);

R_corrected = [];

i = 1; j = 1;

while i <= length(R1) && j <= length(R2)
    diff_ij = R2(j) - R1(i);
    
    if abs(diff_ij) <= tolSamples
        % Match found → take the average location
        R_corrected(end+1) = round((R1(i)+R2(j))/2);
        i = i + 1;
        j = j + 1;
    elseif diff_ij < -tolSamples
        % R2 peak occurs before R1 → add it
        R_corrected(end+1) = R2(j);
        j = j + 1;
    else
        % R1 peak occurs before R2 → add it
        R_corrected(end+1) = R1(i);
        i = i + 1;
    end
end

% Add remaining peaks
if i <= length(R1)
    R_corrected = [R_corrected R1(i:end)];
end
if j <= length(R2)
    R_corrected = [R_corrected R2(j:end)];
end

% Sort final R-peaks
R_corrected = sort(R_corrected);

end
