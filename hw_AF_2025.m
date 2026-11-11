% Labels are hidden (you are supposed to predict them)
% Each record set contains 4 ECG files: (x = p or n)
% All 4 recordings:
% 1. Come from one continuous ECG recording 
% 2. Belong to one person
%
% Record	    Meaning
% p15 (odd)	    ECG far away from PAF
% p16 (even)	ECG right before PAF starts
% p15c	        Confirms no PAF after p15
% p16c	        Shows the actual PAF episode


% SOS! apo to documentation kseroume: h diarkeia toys einai 5min.
% Total number of samples = 38400 ( gia to n10p.dat)
% ARA: At 128 Hz → 38400 / 128 = 300 seconds = 5 minutes
% (which matches a continuation record)
% 
% Prefix	Meaning
% p*	PAF patients
% p odd	Far from PAF
% p even	Immediately before PAF
% n*	No AF
% t*	Test set