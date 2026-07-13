close all;
clear;
clc;

fs = 48000;
s = 2;
t = (0:s*fs-1) / fs;

pulse = zeros(1, s*fs);
pulse(1) = 1;

predelay = 1000;
decay = 0.85;
dry = 0.5;

% pre delay
signal_pre = filter([zeros(1, predelay), 1], [1, zeros(1, predelay-1), 0], pulse);

% comb_filter
D1 = 1423;
D2 = 1601;
D3 = 1733;
D4 = 1907;

c1 = filter([zeros(1, D1), 1], [1, zeros(1, D1-1), -decay], signal_pre);
c2 = filter([zeros(1, D2), 1], [1, zeros(1, D2-1), -decay], signal_pre);
c3 = filter([zeros(1, D3), 1], [1, zeros(1, D3-1), -decay], signal_pre);
c4 = filter([zeros(1, D4), 1], [1, zeros(1, D4-1), -decay], signal_pre);
mix = (c1 + c2 + c3 + c4) / 4;

% all pass filter
g_ap = 0.7;
AP1_D = 227;
AP2_D = 331;

b_ap1 = [-g_ap, zeros(1, AP1_D-1), 1];
a_ap1 = [1, zeros(1, AP1_D-1), -g_ap];
ap1_out = filter(b_ap1, a_ap1, mix);

b_ap2 = [-g_ap, zeros(1, AP2_D-1), 1];
a_ap2 = [1, zeros(1, AP2_D-1), -g_ap];
ap2_out = filter(b_ap2, a_ap2, ap1_out);

signal_final = (1 - dry) * pulse + dry * ap2_out;

figure('Name', 'Reverb', 'Position', [200, 200, 900, 400]);
plot(t, signal_final, 'm');
title('Reverb (Schroeder) effect');
xlabel('Tempo (s)'); ylabel('Amplitude');
grid on;
xlim([0, s]);
