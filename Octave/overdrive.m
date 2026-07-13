close all;
clear;
clc;

fs = 48000;
t = (0:fs-1) / fs;

f = 440;
wave = sin(2 * pi * f * t);

threshold = 0.5;
gain = 15;
tone = 0.5;
volume = 0.75;

signal = wave;

% drive gain
signal_gain = signal * gain;
signal_clipped = max(min(signal_gain, threshold), -threshold);

% tone (passa-baixa IIR)
b_tone = [tone];
a_tone = [1, -(1 - tone)];
signal_tone = filter(b_tone, a_tone, signal_clipped);

% volume
signal_final = signal_tone * volume;

figure('Name', 'Overdrive Completo', 'Position', [100, 100, 800, 450]);
plot(t(1:500), signal(1:500), '--k', 'LineWidth', 1); hold on;
plot(t(1:500), signal_clipped(1:500), ':r', 'LineWidth', 1.5);
plot(t(1:500), signal_final(1:500), 'b', 'LineWidth', 2.5);

title(sprintf('Efeito de Overdrive'));
xlabel('Tempo (s)'); ylabel('Amplitude');
legend('1. Sinal Original', '2. Sinal Clipped (Aspero)', '3. Saída Final (Tone + Vol)');
grid on; 
xlim([0, 500/fs]); 
ylim([-2, 2]);
