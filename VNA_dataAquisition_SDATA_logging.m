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
%% Setting up the file to save data to
todayStr = datestr(now, 'yyyy-mm-dd');  % Format: 2025-05-27
outputFile = ['impedance_data_' todayStr '.txt'];
fid = fopen(outputFile, 'a');  % Append mode
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
%% ---- Setting up logging loop -------
% Initialize VNA and File Setup
fprintf(VNA, 'CALC1:PAR:DEF S11\n');   % Set S11 parameter
todayStr = datestr(now, 'yyyy-mm-dd');
outputFile = ['impedance_data_' todayStr '.txt'];


% Write header once
fid = fopen(outputFile, 'a');
fprintf(fid, 'Timestamp\t\tFrequency(Hz)\tReal(Z)\tImag(Z)\t|Z|\n');
fclose(fid);

startTime = datestr(now, 'yyyy-mm-dd HH:MM:SS'); % logging start time
% Create figure once
f1 = figure(1);

% --- Start Continuous Logging Loop ---
while ishandle(f1)  % Runs until the figure is closed
    % Initiate sweep and read S11
    fprintf(VNA, 'INIT:IMM; *WAI\n');
    fprintf(VNA, ':CALC1:DATA:SDATA?');
    pause(3);
    rawData = fscanf(VNA);
    data = str2double(strsplit(strtrim(rawData), ','));
    realPart = data(1:2:end);
    imagPart = data(2:2:end);
    S11_FreqDomain = complex(realPart, imagPart);

    % Frequency read
    fprintf(VNA, ':SENS:FREQ:DATA?\n');
    frequencies = str2double(strsplit(strtrim(fscanf(VNA)), ','));

    % Calculate impedance
    Z0 = 50;
    impedance = Z0 * (1 + S11_FreqDomain) ./ (1 - S11_FreqDomain);
    impedance_real = real(impedance);
    impedance_imag = imag(impedance);
    impedance_mag = abs(impedance);

    % Save data to file
    timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    fid = fopen(outputFile, 'a');
    for i = 1:length(frequencies)
        fprintf(fid, '%s\t%.6e\t%.6f\t%.6f\t%.6f\n', ...
            timestamp, frequencies(i), impedance_real(i), impedance_imag(i), impedance_mag(i));
    end
    fprintf(fid, '\n');
    fclose(fid);

    % Update plots
clf(f1);  % Clear figure
set(f1, 'Position', [189, 101.6667, 681.3333, 521.3333]);

% Get latest timestamp for this measurement
timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');

subplot(3,1,1)
magS11_dB = 20*log10(abs(S11_FreqDomain));
plot(frequencies * 1e-6, magS11_dB, 'LineWidth', 2);
ylabel('|S11| (dB)');
title({'Magnitude of S11', ['Timestamp: ', timestamp]});
grid on;
set(gca, "FontSize", 12, "FontName", "Palatino Linotype");

subplot(3,1,2)
plot(frequencies * 1e-6, angle(S11_FreqDomain), 'LineWidth', 2);
ylabel('Phase (radians)');
title('Phase of S11');
grid on;
set(gca, "FontSize", 12, "FontName", "Palatino Linotype");

subplot(3,1,3)
plot(frequencies * 1e-6, impedance_real, 'r', 'DisplayName', 'Real', 'LineWidth', 2);
hold on;
plot(frequencies * 1e-6, impedance_imag, 'b', 'DisplayName', 'Imag', 'LineWidth', 2);
xlabel('Frequency (MHz)');
ylabel('Impedance (\Omega)');
title('Impedance (Real and Imaginary)');
legend;
grid on;
set(gca, "FontSize", 12, "FontName", "Palatino Linotype");

annotation(f1, 'textbox', [0.65 0.93 0.3 0.05], ...
    'String', ['Logging started @ ' startTime], ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'right', ...
    'FontSize', 10, ...
    'FontName', 'Palatino Linotype');


drawnow;

    % Wait 30 seconds before next sweep
    pause(10);
end
return
%% --- Clean Up After Window Closed ---
fclose(VNA);
delete(VNA);
clear VNA;
instrreset;
clear all;
%% -- Example reading the data -- 
filename = 'impedance_data_2025-05-27.txt';

% Read data, skipping the header line
data = readtable(filename, 'Delimiter', '\t', 'HeaderLines', 1);
% Assign your own variable names based on your file structure
data.Properties.VariableNames = {'Timestamp', 'FrequencyHz', 'RealZ', 'ImagZ', 'Zmag', 'ExtraColumn'};

% Convert timestamp strings to datetime
timestamps = datetime(data.Timestamp, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');

frequencies = data{:, 'FrequencyHz'};  % or data.FrequencyHz if named
Z_real = data{:, 'RealZ'};
Z_imag = data{:, 'ImagZ'};
Z_mag = data{:, 'Zmag'};  % If column names aren't preserved, this is usually |Z|
% Assuming data and variables are already loaded as you described:
% frequencies, Z_real, Z_imag, Z_mag

% Parameters
pointsPerSweep = 201; % should be the same as fprintf(VNA, ':SENS:SWE:POIN 201');

% Number of full sweeps in your data
numSweeps = floor(length(frequencies) / pointsPerSweep);
display(['Number of sweeps = ',num2str(numSweeps)])

% Extract data for first sweep
freqSweep = frequencies(1:pointsPerSweep) * 1e-6; % MHz
Z_real_sweep = Z_real(1:pointsPerSweep);
Z_imag_sweep = Z_imag(1:pointsPerSweep);
Z_mag_sweep = Z_mag(1:pointsPerSweep);

% Create figure with 3 subplots
figure;

% Real part subplot
subplot(3,1,1);
plot(freqSweep, Z_real_sweep, 'r', 'LineWidth', 2);
xlabel('Frequency (MHz)');
ylabel('Real(Z) (\Omega)');
title('Real Part of Impedance - First Sweep');
grid on;

% Imaginary part subplot
subplot(3,1,2);
plot(freqSweep, Z_imag_sweep, 'b', 'LineWidth', 2);
xlabel('Frequency (MHz)');
ylabel('Imag(Z) (\Omega)');
title('Imaginary Part of Impedance - First Sweep');
grid on;

% Magnitude subplot
subplot(3,1,3);
plot(freqSweep, Z_mag_sweep, 'k', 'LineWidth', 2);
xlabel('Frequency (MHz)');
ylabel('|Z| (\Omega)');
title('Magnitude of Impedance - First Sweep');
grid on;

% Improve figure appearance
set(gcf,'Position',[200 100 700 800]);
