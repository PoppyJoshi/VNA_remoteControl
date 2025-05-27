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

%% ---------------- Connecting to the VNA ---------------------------------
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
%% ---------------- Setting up the file to save data to -------------------
% Get current date and time at start of logging
startTime = datetime('now');

% Format date and time as 'yyyy-MM-dd_HH-mm-ss'
timestampStr = datestr(startTime, 'yyyy-mm-dd_HH-MM-SS');

% Create filename with date and time
outputFile = ['impedance_data_' timestampStr '.txt'];
fid = fopen(outputFile, 'a');  % Append mode
%% ---------------- Setting and checking params for S11 measurement -------

% Define your input variables 
startFreq = 5e0;      % Start frequency in Hz (5 Hz here, update as needed)
stopFreq = 5e6;       % Stop frequency in Hz (5 MHz here, update as needed)
numPoints = 201;      % Number of sweep points
SparamNum = '11';     % Setting S-param number (i.e '11' is S11)
Z0 = 50               % Charateristic impedance

% Use sprintf to create the command strings dynamically
fprintf(VNA, sprintf(':SENS:FREQ:START %g', startFreq));  %g -  automatically chooses between
                                                          %f (fixed-point notation) and %e scientific
                                                          % notation
fprintf(VNA, sprintf(':SENS:FREQ:STOP %g', stopFreq));
fprintf(VNA, sprintf(':SENS:SWE:POIN %d', numPoints));    %d is integer


cmd = sprintf('CALC1:PAR:DEF S%s\n', SparamNum);          % Build the command
fprintf(VNA, cmd);                                        % Send to VNA

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



% Get current date and time at start of logging
startTime = datetime('now');
% Format date and time as 'yyyy-MM-dd_HH-mm-ss'
timestampStr = datestr(startTime, 'yyyy-mm-dd_HH-MM-SS');
% Create filename with date and time
outputFile = ['impedance_data_' timestampStr '.txt'];
%% ---------------- Setting up logging loop -------------------------------
% --- Initialize ---
Z0 = 50;  % Characteristic impedance
startTime = datetime('now');
timestampStr = datestr(startTime, 'yyyy-mm-dd_HH-MM-SS');
outputFile = ['impedance_data_' timestampStr '.txt'];

% Open file
fid = fopen(outputFile, 'w');
fprintf(fid, ['Timestamp\tFrequencyHz\tRealZ\tImagZ\tMagZ\tAvgResistance_5to100Hz\n']);

% --- Setup figure 1: Impedance plots ---
figImpedance = figure('Name','Impedance Plots');
set(figImpedance,'Position',[100, 100, 800, 600]);

hReal = subplot(3,1,1);
hLineReal = plot(hReal, nan, nan, 'r', 'LineWidth', 2);
xlabel(hReal, 'Frequency (MHz)');
ylabel(hReal, 'Real(Z) (\Omega)');
title(hReal, 'Resistance');
grid(hReal, 'on');
set(hReal, 'FontSize', 12, 'FontName', 'Palatino Linotype');

hImag = subplot(3,1,2);
hLineImag = plot(hImag, nan, nan, 'b', 'LineWidth', 2);
xlabel(hImag, 'Frequency (MHz)');
ylabel(hImag, 'Imag(Z) (\Omega)');
title(hImag, 'Reactance');
grid(hImag, 'on');
set(hImag, 'FontSize', 12, 'FontName', 'Palatino Linotype');

hMag = subplot(3,1,3);
hLineMag = plot(hMag, nan, nan, 'k', 'LineWidth', 2);
xlabel(hMag, 'Frequency (MHz)');
ylabel(hMag, '|Z| (\Omega)');
title(hMag, 'Magnitude of Impedance');
grid(hMag, 'on');
set(hMag, 'FontSize', 12, 'FontName', 'Palatino Linotype');

% --- Setup figure 2: Average resistance over time ---
figRes = figure('Name','Average Resistance Over Time');
set(figRes, 'Position', [950, 100, 600, 400]);

hPlotRes = plot(nan, nan,'.-', 'LineWidth', 2);
xlabel('Time', 'FontSize', 12, 'FontName', 'Palatino Linotype');
ylabel('Average Resistance (Ohms)', 'FontSize', 12, 'FontName', 'Palatino Linotype');
title('Live DC Resistance (5–100 Hz)', 'FontSize', 14, 'FontName', 'Palatino Linotype');
grid on;
set(gca, 'FontSize', 12, 'FontName', 'Palatino Linotype');


timeLog = datetime.empty;  % empty datetime array
avgResLog = [];            % numeric array for resistance values
xAxisStartTime = [];  % empty for now


% --- Logging Loop ---
while ishandle(figImpedance) && ishandle(figRes)
    fprintf(VNA, 'INIT:IMM; *WAI\n'); 
    pause(3);  % Wait for sweep

    % Read S11 and frequency data
    fprintf(VNA, ':CALC1:DATA:SDATA?');
    rawData = fscanf(VNA);
    fprintf(VNA, ':SENS:FREQ:DATA?');
    freqData = fscanf(VNA);

    % Process
    data = str2double(strsplit(strtrim(rawData), ','));
    freq = str2double(strsplit(strtrim(freqData), ','));
    realPart = data(1:2:end);
    imagPart = data(2:2:end);
    S11 = complex(realPart, imagPart);
    impedance = Z0 * (1 + S11) ./ (1 - S11);
    resistance = real(impedance);
    magZ = abs(impedance);

    % Average resistance (5–100 Hz)
    idxRange = freq >= 5 & freq <= 100;
    avgResistance = mean(resistance(idxRange));

    % Log
    currentTime = datetime('now');
    currentTimeStr = datestr(currentTime, 'yyyy-mm-dd HH:MM:SS');
    if isempty(xAxisStartTime)
    xAxisStartTime = currentTime;  % store the very first timestamp only once
    end

    for k = 1:length(freq)
        fprintf(fid, '%s\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\n', ...
            currentTimeStr, freq(k), resistance(k), imag(impedance(k)), magZ(k), avgResistance);
    end
    

    % --- Update figure 1: impedance plots ---
if ishandle(figImpedance)
    figure(figImpedance);
    
    % Clear any previous supertitle
    sgtitle('');
    % Main title: current timestamp + avg resistance
    suptitleStr = sprintf('Impedance Plots — %s | Avg DC Resistance (5–100 Hz): %g Ω', ...
                          currentTimeStr, avgResistance); subtitleStr = ['Logging started @ ' datestr(startTime, 'yyyy-mm-dd HH:MM:SS')];

    % Use sgtitle for the main title
    sg = sgtitle({suptitleStr, subtitleStr});
    sg.FontSize = 14;
    sg.FontWeight = 'bold';
    sg.FontName = 'Palatino Linotype';
    freqMHz = freq * 1e-6;
    set(hLineReal, 'XData', freqMHz, 'YData', resistance);
    set(hLineImag, 'XData', freqMHz, 'YData', imag(impedance));
    set(hLineMag,  'XData', freqMHz, 'YData', magZ);
    drawnow;
end

% --- Update figure 2: average resistance over time ---
if ishandle(figRes)
    % Append current time and average resistance
    currentTime = datetime('now');
    timeLog(end+1) = currentTime;
    avgResLog(end+1) = avgResistance;

    % Set xAxisStartTime if this is the first data point
    if isempty(xAxisStartTime)
        xAxisStartTime = currentTime;
    end

    % Prepare plot
    figure(figRes);
    axRes = gca;

    % Convert datetime array to datenum for plotting and limits
    xDataNum = datenum(timeLog);

    % Update plot data
    set(hPlotRes, 'XData', xDataNum, 'YData', avgResLog);

%     margin = 1/1440;  % 1 minute margin in days
% 
%     % Set limits: start fixed to first entry, end is latest + margin
%     if length(xDataNum) > 1
%         leftLimit = datenum(xAxisStartTime) - margin;
%         rightLimit = xDataNum(end) + margin;
%         xlim(axRes, [leftLimit, rightLimit]);
%     else
%         % Only one data point: center limits around it
%         xlim(axRes, [xDataNum(1) - margin, xDataNum(1) + margin]);
%     end

    % Format x-axis ticks as datetime strings
%     datetick(axRes, 'x', 'yyyy-mm-dd HH:MM:SS', 'keeplimits', 'keepticks');

    % Rotate labels for readability
    axRes.XTickLabelRotation = 45;

    drawnow;
   
end

    pause(5);  % 5 sec delay between sweeps
end

% --- Clean up ---
fclose(fid);
disp('✅ Logging stopped and file closed.');

return
%% ---------------- Close and clean Up connection -------------------------
fclose(VNA);
delete(VNA);
clear VNA;
instrreset;
clear all;
display(['Connection succsefully closed! :)'])
%% ---------------- Example reading the data ------------------------------ 
%% ---------------- Example reading the data ------------------------------ 
% ------------  INPUT  ---------------------------------------------------
filename       = 'impedance_data_Example.txt';
pointsPerSweep = 201;                     % must match VNA sweep‐point setting
Z0             = 50;                      % (unused here, but kept for context)

% ------------  LOAD TABLE  ---------------------------------------------
T = readtable(filename, 'Delimiter', '\t', 'HeaderLines', 1);
T.Properties.VariableNames = {'Timestamp','FrequencyHz','RealZ','ImagZ','Zmag','DCRes'};

freq     = T.FrequencyHz;
Z_real   = T.RealZ;
Z_imag   = T.ImagZ;
Z_mag    = T.Zmag;
avgRes   = T.DCRes;  % Precomputed average resistance
ts       = datetime(T.Timestamp,'InputFormat','yyyy-MM-dd HH:mm:ss');

numSweeps = floor(height(T)/pointsPerSweep);
sweepTime = ts(1:pointsPerSweep:end);     % First timestamp per sweep
avgRes    = avgRes(1:pointsPerSweep:end); % One avg value per sweep

% ------------  FIGURE 10 : ALL SWEEPS OF IMPEDANCE  ---------------------
f10 = figure('Name','All Impedance Sweeps','Position',[100 100 800 650]);

% --- Real(Z)
subplot(3,1,1); hold on;
for k = 1:numSweeps
    idx = (k-1)*pointsPerSweep + (1:pointsPerSweep);
    plot(freq(idx)*1e-6, Z_real(idx),'Color',[0.85 0 0 0.4]); % semi-transparent red
end
xlabel('Frequency (MHz)'); ylabel('Real(Z) (\Omega)');
title('Real Part – all sweeps'); grid on;
set(gca, 'FontSize', 12, 'FontName', 'Palatino Linotype');

% --- Imag(Z)
subplot(3,1,2); hold on;
for k = 1:numSweeps
    idx = (k-1)*pointsPerSweep + (1:pointsPerSweep);
    plot(freq(idx)*1e-6, Z_imag(idx),'Color',[0 0.2 0.8 0.4]); % semi-transparent blue
end
xlabel('Frequency (MHz)'); ylabel('Imag(Z) (\Omega)');
title('Imaginary Part – all sweeps'); grid on;
set(gca, 'FontSize', 12, 'FontName', 'Palatino Linotype');

% --- |Z|
subplot(3,1,3); hold on;
for k = 1:numSweeps
    idx = (k-1)*pointsPerSweep + (1:pointsPerSweep);
    plot(freq(idx)*1e-6, Z_mag(idx),'Color',[0 0 0 0.4]);      % semi-transparent black
end
xlabel('Frequency (MHz)'); ylabel('|Z| (\Omega)');
title('Magnitude – all sweeps'); grid on;
set(gca, 'FontSize', 12, 'FontName', 'Palatino Linotype');
set(gcf,'Position',[11.6667   65.6667  792.0000  568.6667]);

% ------------  FIGURE 11 : AVG RESISTANCE vs. TIME  ---------------------
f11 = figure('Name','Average DC Resistance vs Time','Position',[950 100 650 350]);
plot(sweepTime, avgRes,'.-','LineWidth',2);
xlabel('Time'); ylabel('DC resistance  (5–100 Hz)  [\Omega]');
title('Average Resistance per Sweep'); grid on;
xtickformat('yyyy-MM-dd HH:mm:ss'); xtickangle(45);
set(gca, 'FontSize', 12, 'FontName', 'Palatino Linotype');
set(gcf,'Position',[660.3333  283.6667  650.0000  350.0000]);

