# AtrialFibrilation_Prediction_ECG
Atrial fibrillation (AF) is the most common sustained cardiac arrhythmia, occurring in 1–2% of 
the general population. AF is characterized by an irregular and chaotic electrical activation of the atria resulting 
in the modification of the ventricular activity and increased risk of clot formation. “Paroxysmal” AF (PAF) is a 
type of AF which may last up to 48 hours and is usually self-terminated. Given the absence of remarkable 
structural remodeling in patients with PAF, the detection of possible changes in the surface electrocardiogram 
(ECG) is challenging. The atrial depolarization is represented on the surface ECG as the P-wave. P-wave closely 
correlates with the conduction in specific parts of the atria and thus any deflection of the P-wave characteristics 
implies regional changes in atrial activation time and conduction route. [1] 
[1] Hindricks, Gerhard, et al. "2020 ESC Guidelines for the diagnosis and management of atrial fibrillation 
developed in collaboration with the European Association for Cardio-Thoracic Surgery (EACTS) The Task Force 
for the diagnosis and management of atrial fibrillation of the European Society of Cardiology (ESC) Developed 
with the special contribution of the European Heart Rhythm Association (EHRA) of the ESC." European heart 
journal 42.5 (2021): 373-498. 
Data used: Signals from the PAF Prediction Challenge Database from physionet will be used 
(https://physionet.org/content/afpdb/1.0.0/). This database contains two channel ECG recording of 30 minutes 
duration, from both healthy subjects and from PAF patients, which are further categorised as those where the 
PAF episodes start immediately after the end of the recording and those where the recording s distant from any 
episode of PAF (there is no PAF during the 45-minute period before the beginning or after the end of the 30
minute record). Each group includes 50 distinct subjects. 
[2] Moody GB, Goldberger AL, McClennen S, Swiryn SP. Predicting the Onset of Paroxysmal Atrial Fibrillation: 
The Computers in Cardiology Challenge 2001. Computers in Cardiology 28:113-116 (2001). 

Pipeline description: The main steps of the pipeline include (1) preprocessing the data to remove noise 
(try different processing techniques to remove noise without distorting the signal), (2) identifying the 
fiducial points on the ECG signals using different techniques, such as ECGdeli1, neurokit22, Pan
Tompkins3 or WFDB detectors 4 5, (3) comparing the detected R-peak locations across detectors and leads 
using a defined tolerance window, aligning and correcting beat locations between leads to obtain a 
consistent set of beat annotations, (4) performing HRV analysis to assess how different detection methods 
influence HRV features, (5) extracting features from different domains (time, frequency and 
time/frequency based on a quick bibliographic search to identify relevant features) from the P-wave in a 
beat-to-beat basis and from an averaged P-wave, (5) performing statistical analysis on both beat-to-beat 
and averaged wave features to identify differences between patient groups. 
