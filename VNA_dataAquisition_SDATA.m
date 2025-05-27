%% ---------------- VNA data Aquisition PJ 22/05/22025----------------------
% This code is designed to connect to the keysight ENA 5061B via USB-A -->
% USB-B, read in the S11 parameters and calclate the impedance. We can also
% use this to set parameters/scales on the VNA remotely.

% First download the 'prerequisit' and 'main' keysight IO software to
% use the connection expert which will give the USB VISA address. 
% from https://www.keysight.com/us/en/lib/software-detail/computer-
% software/io-libraries-suite-downloads-2175637.html.

% SCIP commands can be found here
% https://helpfiles.keysight.com/csg/e5061b/programming/command_reference/index.htm


% If the connection expert dispays the device is connceted but MATLAB won't
% connect it is likely that is stores multiple connection attemps and gets
% confused.. Use:
% instrfind - to display the connections
% instrhwinfo - to displace the info of connected device
% instrreset - to clear the connections
% when you do 'instrfind' after 'instrreset' it should retrn an empty array
% i.e.  instrfind = []

% SDATA? - obtains the S-data
% FDATA? - obtains the current trace data. Less reliable, less info I don't
% recomend using this.

%%
clc;close all;clear all;

% VISA address from Keysight Connection Expert
visaAddress = 'USB0::0x2A8D::0x5E01::MY49912380::INSTR';

% Create the VISA object
VNA = visa('keysight', visaAddress);

% Enable debugging mode
VNA.Timeout = 10;  % Set timeout for commands (in seconds)
VNA.InputBufferSize = 5^12;  % Adjust buffer size if needed

% Open connection
try
    fopen(VNA);
    fprintf(VNA, '*IDN?\n');  % Query the instrument
    idn = fscanf(VNA);      % Read the response
    disp(['Connection sucessfull: ',idn]);       % Display the instrument ID
    fprintf(VNA,':SYST:BEEP:COMP:IMM\n')         % Make a beep for sucessfull connection
catch err
    disp('Error:');
    disp(err.message);          % Show the error message if there is one
end

% Reset the instrument to ensure no previous settings cause conflicts
fprintf(VNA, '*RST\n');  % Reset the device
fprintf(VNA, '*CLS\n');  % Clear any errors from previous sessions
return

%% Setting and checking params
% Set frequency range from 1 GHz to 5 GHz and the number of points to 201
fprintf(VNA, ':SENS:FREQ:START 5E0');    % Start frequency = 1 GHz
fprintf(VNA, ':SENS:FREQ:STOP 5E6');     % Stop frequency = 5 GHz
fprintf(VNA, ':SENS:SWE:POIN 201');      % Set the number of points to 201

% Confirm the settings (optional)
fprintf(VNA, ':SENS:FREQ:START?');
startFreq = fscanf(VNA, '%f');
fprintf(VNA, ':SENS:FREQ:STOP?');
stopFreq = fscanf(VNA, '%f');
fprintf(VNA, ':SENS:SWE:POIN?');
numPoints = fscanf(VNA, '%d');
disp(['Start Frequency: ', num2str(startFreq), ' Hz']);
disp(['Stop Frequency: ', num2str(stopFreq), ' Hz']);
disp(['Number of Points: ', num2str(numPoints)]);
%% Setting S11 paramter and initiating sweep
fprintf(VNA, 'CALC1:PAR:DEF S11\n'); % Sets paramater s S11
fprintf(VNA, 'INIT:IMM; *WAI\n');  % Initiate a sweep  

 %% Reding in the S11 data
fprintf(VNA, ':CALC1:DATA:SDATA?'); % This collects the S11 data
pause(3);
rawData = fscanf(VNA);
%% Processing and plotting the data
close all
% Process the data: Convert to numeric values
data = str2double(strsplit(strtrim(rawData), ','));

% Separate real and imaginary parts
realPart = data(1:2:end);  % Real part (odd indices)
imagPart = data(2:2:end);  % Imaginary part (even indices)

% Combine into a complex number
S11_FreqDomain = complex(realPart, imagPart);

% Get frequency axis (assuming frequency data is available)
fprintf(VNA, ':SENS:FREQ:DATA?\n');  % Query frequency data
frequencies = str2double(strsplit(strtrim(fscanf(VNA)), ','));

% Plot S11 Magnitude and Phase in Frequency Domain
figure;

% Plot the Magnitude of S11 (in dB)

magS11_dB = 20*log10(abs(S11_FreqDomain));  % Magnitude in dB
subplot(2,1,1)
plot(frequencies * 1e-6, (magS11_dB),'LineWidth',2);  % Plot in dB
xlabel('Frequency (MHz)');
ylabel('|S11| (dB)');
title('Magnitude of S11');
grid on;
ylim([-50, 50]);  % Set the range from -50 dB to +50 dB


% % Plot the Phase of S11 (in radians)
subplot(2,1,2);
plot(frequencies * 1e-6, angle(S11_FreqDomain),'LineWidth',2);  % Phase in radians
xlabel('Frequency (MHz)');
ylabel('Phase (radians)');
title('Phase of S11');
grid on;
%% Calculating Impedance
% Define characteristic impedance Z0 (typically 50 Ohms)
Z0 = 50;

% Calculate S11 as a complex number (already done above)
% S11_FreqDomain = complex(realPart, imagPart);  % This is the complex S11

% Calculate the impedance using the formula Z = Z0 * (1 + S11) / (1 - S11)
impedance = Z0 * (1 + S11_FreqDomain) ./ (1 - S11_FreqDomain);

% Extract the real and imaginary parts of the impedance
impedance_real = real(impedance);
impedance_imag = imag(impedance);

% Plot S11 Magnitude, Phase, and Impedance in Frequency Domain
f1 = figure(1);

% Plot the Magnitude of S11 (in dB)
magS11_dB = 20*log10(abs(S11_FreqDomain));  % Magnitude in dB
subplot(3,1,1)
plot(frequencies * 1e-6, magS11_dB, 'LineWidth', 2);  % Plot in dB
% xlabel('Frequency (MHz)');
ylabel('|S11| (dB)');
title('Magnitude of S11');
grid on;
set(gca,"FontSize",12,"fontname","Palatino Linotype");


% Plot the Phase of S11 (in radians)
subplot(3,1,2);
plot(frequencies * 1e-6, angle(S11_FreqDomain), 'LineWidth', 2);  % Phase in radians
% xlabel('Frequency (MHz)');
ylabel('Phase (radians)');
title('Phase of S11');
grid on;
set(gca,"FontSize",12,"fontname","Palatino Linotype");

% Plot the Impedance (Real and Imaginary Parts)
subplot(3,1,3);
plot(frequencies * 1e-6, impedance_real, 'r', 'DisplayName', 'Real','linewidth',2);  % Real part
hold on;
plot(frequencies * 1e-6, impedance_imag, 'b', 'DisplayName', 'Imaginary','linewidth',2);  % Imaginary part
xlabel('Frequency (MHz)');
ylabel('Impedance (\Omega)');
title('Impedance (Real and Imaginary Parts)');
legend;
grid on;
set(gca,"FontSize",12,"fontname","Palatino Linotype");
set(gcf,'position',[498    54   691   388]);
exportgraphics(f1,'Impedance_Lowpass.png','Resolution',150)
% Optional: Logarithmic scale for frequency axis
% set(gca, 'XScale', 'log');  % Log scale for X-axis (Frequency)

%% averaging 
% % Enable averaging and set the average count
% fprintf(visaObj, 'SENS:AVER:STAT ON');
% fprintf(visaObj, 'SENS:AVER:COUN 10');
    %% Clean up connections at the end
    % % Clean up
   
fclose(VNA);
delete(VNA);
clear VNA;
instrreset 
 clear all
% Reset all instrument objects Use this to check if instrfind returns only 1 connection

