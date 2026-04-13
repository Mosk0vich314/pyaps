%% clear
clear
clc
close all

%% parameters
Dir = 'E:\Samples\flaa_AngEvap_22\9AGNR\300K\NoiseMeasurements\';
Filename = '2019-12-13_run75_1V_10s_Gt';

%% load
load(sprintf('%s/%s.mat', Dir, Filename))

%% Noisetestskript
%Use Fourier transforms to find the frequency components of a signal buried in noise.
% Specify the parameters of a signal with a sampling frequency of 1 kHz and a signal duration of 1.5 seconds.

Fs = Gt.scanrate / Gt.points_av;     %         % Sampling frequency                    
T = Gt.time_per_point; %1/Fs;   % Sampling period       
L = Gt.runtime_counts;%1500;    % Length of signal
t = Gt.time; %(0:L-1)*T;        % Time vector

%% Window correction factors
cUniAmp = 1.0;      % Uniform
cUniEnergy = 1.0;   % Uniform
cHannAmp = 2.0;     % Hanning
cHannEnergy = 1.63; % Hanning
cFlatAmp = 4.18;    % Flattop
cFlatEnergy = 2.26;   % Flattop

%Flattop
%Blackman
%Hamming
%Kaiser-Bessel

%% Form a signal containing a 50 Hz sinusoid of amplitude 0.7 and a 120 Hz sinusoid of amplitude 1.
S = Gt.current{1}; %0.7*sin(2*pi*50*t) + sin(2*pi*120*t);

%% Corrupt the signal with zero-mean white noise with a variance of 4.

X = S; %+ 2*randn(size(t));

npieces = 100;
pitch = floor(length(X)/npieces);
C = zeros(pitch,1); 
for i=1:npieces
    B = X((i-1)*pitch+1:(i*pitch));
    C = C + fft(hann(length(B)).*B);
end    
C = C/npieces; 
%% Plot the noisy signal in the time domain. It is difficult to identify the frequency components by looking at the signal X(t).
%plot(t(1:end),X(1:end))
%title('Signal')
%xlabel('t (seconds)')
%ylabel('X(t)')

%% Compute the Fourier transform of the signal.
%Y = fft(hann(length(X)).*X);  %fft(X);

%% Compute the two-sided spectrum P2. Then compute the single-sided spectrum P1 based on P2 and the even-valued signal length L.
P2 = abs(C/pitch);
P1 = P2(1:pitch/2+1);
P1(2:end-1) = 2*P1(2:end-1)*cHannEnergy;

%% Define the frequency domain f and plot the single-sided amplitude spectrum P1. The amplitudes are not exactly at 0.7 and 1, as expected, because of the added noise. On average, longer signals produce better frequency approximations.
f = Fs*(0:(pitch/2))/pitch;
h = figure;
plot(f,P1) 
title('Single-Sided Amplitude Spectrum of X(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')
set(gca, 'yscale', 'log')
set(gca, 'xscale', 'log')

saveas(h, sprintf('%s/%s_FFT.png', Dir, Filename))
