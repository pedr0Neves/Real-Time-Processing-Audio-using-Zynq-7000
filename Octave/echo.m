close all;
clear;
clc;


fs = 48000;			% sampling rate (48kHz)
s = 5;				% 5 segundos de duração
t = (0:s*fs-1) / fs;		% tempo total da simulação

pulse = zeros(1, s*fs);		% sinal de pulso
pulse(1) = 1;

% 
delay = 24000;		% 0.5s
feedback = 0.50;	% 50%
dry = 1.0;		% 100%

%comb_filter: H(z) = z^-D / (1 - g*z^-D)
b_comb = [zeros(1, delay), 1];
a_comb = [1, zeros(1, delay-1), -feedback];

delay_out = filter(b_comb, a_comb, pulse);
signal_out = (1 - dry) * pulse + dry * delay_out;

figure('Name', 'Echo (5 Segundos)', 'Position', [150, 150, 900, 400]);
stem(t, signal_out, 'b', 'Marker', 'none');
title('Efeito de atraso');
xlabel('Tempo (s)'); ylabel('Amplitude');
grid on;
xlim([0, s]);
