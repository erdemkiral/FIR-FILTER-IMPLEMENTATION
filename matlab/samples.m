clc ;
fs = 20000;
T  = 1/fs;
t = 0:1/fs:0.02;

signal_noisy = 2*sin(2*pi*2500*t) + 4*cos(2*pi*7000*t);

noisy_single = single(signal_noisy);
noisy_hex    = num2hex(noisy_single);

figure(1);
ydft= fftshift(fft(signal_noisy));
df = fs/length(signal_noisy);
f  = -fs/2+df:df:fs/2;

subplot(2,1,1); plot(t,signal_noisy);title('Sampled Noisy Signal');xlabel('Time(sec)');ylabel('Amplitude (V)');
subplot(2,1,2); plot(f,abs(ydft));title('Noisy Signal Spectrum');xlabel('Hz');ylabel('Amplitude');

filter_out_noisy = hexsingle2num(filterout.Variables);

figure(2);
ydft= fftshift(fft(filter_out_noisy));
df = fs/length(filter_out_noisy);
f  = -fs/2+df:df:fs/2;
subplot(2,1,1);plot(f,abs(ydft));title(' Filtered Noisy Signal Spectrum ');xlabel('Hz');ylabel('Amplitude');
subplot(2,1,2);plot(filter_out_noisy);title(' Filtered Noisy Signal  ');xlabel('Time(sec)');ylabel('Amplitude (V)');


