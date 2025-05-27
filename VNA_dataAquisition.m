% ---------------- VNA data Aquisition PJ 22/05/22025
% First download the 'prerequisit' and 'main' keysight IO software
% from https://www.keysight.com/us/en/lib/software-detail/computer-
% software/io-libraries-suite-downloads-2175637.html.

% SCIP commands can be found here
% https://helpfiles.keysight.com/csg/e5061b/programming/command_reference/index.htm
%instrfind
%%
clc;close all;clear all;

% Replace this with the VISA address from Keysight Connection Expert
visaAddress = 'USB0::0x2A8D::0x5E01::MY49912380::INSTR';


% Create the VISA object with your correct address
VNA = visa('keysight', visaAddress);


% Enable debugging mode
VNA.Timeout = 10;  % Set timeout for commands (in seconds)
VNA.InputBufferSize = 5^12;  % Adjust buffer size if needed

% Open connection
try
    fopen(VNA);
    fprintf(VNA, '*IDN?\n');  % Query the instrument
    idn = fscanf(VNA);      % Read the response
    disp(['Connection sucessfull: ',idn]);                  % Display the instrument ID
    fprintf(VNA,':SYST:BEEP:COMP:IMM\n')
catch err
    disp('Error:');
    disp(err.message);          % Show the error message
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
  % Trigger a sweep and fetch the data
    fprintf(VNA, 'INIT:IMM; *WAI\n');  % Initiate a sweep  

  return
 %% Reding in the S11 data
fprintf(VNA, ':CALC1:DATA:FDATA?'); % This collects the current trace
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

magS11_dB = 20*log10(abs(S11_FreqDomain))*-1;  % Magnitude in dB
plot(frequencies * 1e-9, (magS11_dB),'LineWidth',2);  % Plot in dB
xlabel('Frequency (GHz)');
ylabel('|S11| (dB)');
title('Magnitude of S11');
grid on;
% Set X and Y axis to logarithmic scale
% set(gca, 'XScale', 'log');  % Log scale for X-axis (Frequency)
% set(gca, 'YScale', 'log');  % Log scale for Y-axis (Magnitude)
% Invert the magnitude (fix the upside-down issue) by flipping the Y-axis direction
ylim([-50, 50]);  % Set the range from -50 dB to +50 dB
% set(gca, 'YDir', 'reverse');  % Flip Y-axis direction to correct the plot

% % Plot the Phase of S11 (in radians)
% subplot(2,1,2);
% plot(frequencies * 1e-9, angle(S11_FreqDomain));  % Phase in radians
% xlabel('Frequency (GHz)');
% ylabel('Phase (radians)');
% title('Phase of S11');
% grid on;
return
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

