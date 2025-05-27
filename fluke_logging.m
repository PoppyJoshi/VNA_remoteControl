% % Resistance logging using FLUKE 8846A digital multimeter % %
% % ----------- Julia Fekete, 01/05/2019 ------------------ % %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
%% FLUKE Connection
clear all; clc;

% Find a tcpip object:
obj1 = instrfind('Type', 'tcpip', 'RemoteHost', '169.254.1.1', 'RemotePort', 3490, 'Tag', '');
% Create the tcpip object if it does not exist
% otherwise use the object that was found:
if isempty(obj1)
    obj1 = tcpip('169.254.1.1', 3490);
else
    fclose(obj1);
    obj1 = obj1(1);
end
% Connect to instrument object, obj1:
fopen(obj1);
% % Check connection: get instrument ID:
% fprintf(obj1, '*IDN?');

%% Configure measurement: Resistance, autoscale, 3 samples for each (internal) trigger
fprintf(obj1, 'CONF:RES DEF');
fprintf(obj1, 'DATA:FEED RDG_STORE ""');
fprintf(obj1, 'SAMPLE:COUNT 3');

%% Logging data into file and real-time plotting
% Create log file:
time = char(datestr(now,'hh-MM-ss')); % time of recording
formatOut='yy-mm-dd';
day=datestr(datetime('today'),formatOut); % today's date
fname = char(strcat('logdata_20',{day},'_',{time},'.txt')); % filename
file1 = fopen(fname,'a');
disp('Logging started. Close figure to exit logging. File out:')
disp(fname)

% Plot:
h = figure;
ax = axes( 'parent', h, 'nextplot', 'add' );
xlabel('Step Nr.')
grid on

tstep = 2; % time step(x 2 seconds) tstep = 2 gives ~5 sec
M=[];

for p = 1:1e5;

fprintf(obj1, 'INIT');
fprintf(obj1, 'FETC?');
rsamples = fscanf(obj1)

res=mean(str2num(rsamples))

    T = (p-1)*tstep;
    Tserial = datenum(now);
    
    drawnow()
    if ~ishandle ( h ); break; end
    plot(p,res,'r.')
    fprintf(file1,'%f %f %f %f \n',p,T,Tserial,res);
    M(p,:)=[p T Tserial res];
    pause(tstep)
    p = p + 1;
end

fclose(obj1);
delete(obj1);
clear obj1
return;

%% Read data file:
% 
% fname='logdata_2019-05-01_09-18-54.txt';
%     M=dlmread(fname); ts=M(:,3); R=M(:,4);
%     t_sec = ts*24*3600; t_sec=t_sec-t_sec(1);
%     figure(1); plot(t_sec,R,'r.-'); 
%     xlabel('Time (s)'); ylabel('Voltage'); title(fname)
%     set(gcf,'Position',[860  500  491  264])
%     
%     vary=(max(R)-min(R))./(max(R)+min(R)).*2;
%     legtext=['\sigma_{p-p} = ' num2str(vary*100,'%.1f') '%'];legend(legtext)