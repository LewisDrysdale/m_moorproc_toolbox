% function temperature_overlay(moor,'procpath','proclvl','layout','plot_interval')
%
% Function for plotting temperatures from a mooring overlayed on the same axes
%
% required inputs:-
%   moor: complete mooring name as string. e.g. 'wb1_1_200420'
%
% optional inputs:-
%   layout: orientation of figure portrait/lanscape (default = portrait)
%           input of 'landscape' or 'portrait'
%           e.g. pressure_overlay('wb1_1_200420','layout','landscape')
%   plot_interval: matrix of start and end dates for plot
%           e.g. pressure_overlay('wb1_1_200420','plot_interval',[2004 02 01 00; 2005 06 01 00])
%           dates are:- yyyy mm dd hh. Default is calculated automatically
%   procpath: can specify exact procpath if not using standard data paths. 
%           e.g. pressure_overlay('wb1_1_200420','inpath','/Volumes/noc/mpoc/hydro/rpdmoc/rapid/data/moor/proc/')
%   proclvl: can specify level of processing of the data to plot. 
%           e.g. 'proclvl','2': will plot the .use file ; 'proclvl','3' will plot the .microcat and .edt files
%
% functions called:-
%   rodbload, julian, auto_filt
%   from .../exec/moor/tools and .../exec/moor/rodb paths
% 
% Routine written by Darren Rayner January 2007.
% adapted from pressure_overaly.m
% 15/4/11 - added compatability for Seaguards
% 05/10/16 - Loic Houpert: added option to process lvl 3 data (.microcat and .edt files for nortek) and save plot
%
function temperature_overlay(moor,varargin)
if nargin <1
    help temperature_overlay
    return
end

% check for optional arguments
a=strmatch('layout',varargin,'exact');
if a>0
    layout=char(varargin(a+1));
else
    layout='portrait';
end

a=strmatch('procpath',varargin,'exact');
if a>0
    procpath=char(varargin(a+1));
else
    data_report_tools_dir=which('data_report_tools');
    b=strfind(data_report_tools_dir,'/');
    data_report_tools_dir=data_report_tools_dir(1:b(end));
    procpath=[data_report_tools_dir '../../../moor/proc/']; %DR changed to be relative paths now that data_report_tools are on the network 19/2/12
end


a=strmatch('proclvl',varargin,'exact');
if a>0
    proclvlstr0=char(varargin(a+1));
    proclvl   = str2num(proclvlstr0);
else
    proclvl=2;
    proclvlstr0 = num2str(proclvl);
end

a=strmatch('plot_interval',varargin,'exact');
if a>0
    plot_interval=eval(varargin{a+1});
else
    plot_interval=0;
end

a=strmatch('unfiltered',varargin,'exact');
if a>0
    filtered=0;
    proclvlstr = [proclvlstr0 '_unfilt'];    
else
    filtered=1;
    proclvlstr = [proclvlstr0 '_lpfilt'];        
end

if isunix
    infofile=[procpath,moor,'/',moor,'info.dat'];
elseif ispc
    infofile=[procpath,moor,'\',moor,'info.dat'];
end

% Load vectors of mooring information
% id instrument id, sn serial number, z nominal depth of each instrument
% s_t, e_t, s_d, e_d start and end times and dates
% lat lon mooring position, wd corrected water depth (m)
% mr mooring name
[id,sn,z,s_t,s_d,e_t,e_d,lat,lon,wd,mr]  =  rodbload(infofile,...
    'instrument:serialnumber:z:Start_Time:Start_Date:End_Time:End_Date:Latitude:Longitude:WaterDepth:Mooring');


% JULIAN Convert Gregorian date to Julian day.
% JD = JULIAN(YY,MM,DD,HH) or JD = JULIAN([YY,MM,DD,HH]) returns the Julian
% day number of the calendar date specified by year, month, day, and decimal
% hour.
% JD = JULIAN(YY,MM,DD) or JD = JULIAN([YY,MM,DD]) if decimal hour is absent,
% it is assumed to be zero.
% Although the formal definition holds that Julian days start and end at
% noon, here Julian days start and end at midnight. In this convention,
% Julian day 2440000 began at 00:00 hours, May 23, 1968.
jd_start = julian([s_d' hms2h([s_t;0]')]);
jd_end   = julian([e_d' hms2h([e_t;0]')]);

disp(['z : instrument id : serial number'])
for i = 1:length(id)
    disp([z(i),id(i),sn(i)])
end

% ------------------------------------------------
% Determine plot_interval if not input to function
if plot_interval==0
    plot_interval = zeros(2,4);
    plot_interval(1,1) = s_d(1); plot_interval(1,2) = s_d(2)-1; plot_interval(1,3) = 1; plot_interval(1,4) = 0;
    plot_interval(2,1) = e_d(1); plot_interval(2,2) = e_d(2)+1; plot_interval(2,3) = 1; plot_interval(2,4) = 0;
    if plot_interval(1,2)==0
        plot_interval(1,2)=12; plot_interval(1,1)=plot_interval(1,1)-1;
    end
    if plot_interval(2,2)==13
        plot_interval(2,2)=1; plot_interval(2,1)=plot_interval(2,1)+1;
    end
end


% create xtick spacings based on start of months     
check=0;
i=2;
xticks(1,:)=plot_interval(1,:);
while check~=1
    xticks(i,:)=xticks(i-1,:);
    if xticks(i,2)<12
        xticks(i,2)=xticks(i-1,2)+1;
    else
        xticks(i,2)=1;
        xticks(i,1)=xticks(i-1,1)+1;
    end
    if xticks(i,:)>=plot_interval(2,:)
        check = 1;
    end
    i=i+1;
end

if i<4
   jdxticks =julian(plot_interval(1,:)):(julian(plot_interval(2,:))-julian(plot_interval(1,:)))/5:julian(plot_interval(2,:));
   gxticks = gregorian(jdxticks);
   xticks = gxticks(:,1:4);
   xticklabels = datestr(gxticks,'dd mmm');
else
	jdxticks=julian(xticks);
	% create xticklabels from xticks
	months=['Jan'; 'Feb'; 'Mar'; 'Apr'; 'May'; 'Jun'; 'Jul'; 'Aug'; 'Sep'; 'Oct'; 'Nov'; 'Dec'];
	xticklabels=months(xticks(:,2),1:3);
end

% cannot have multi-line xticklabels so have to use manual label command
% this is not really a problem as only want to display years on bottom plot
year_indexes =[];
for i=1:length(xticklabels)
    if find(strfind(xticklabels(i,1:3),'Jan'))
        year_indexes=[year_indexes; i];
    end
end
% use year_indexes later for plotting on bottom graph

jd1 = julian(plot_interval(1,:));
jd2 = julian(plot_interval(2,:)); 


% find the index number of Microcats
iiMC = find(id == 337 | id == 335);
vecMC = sn(iiMC);
% find the index number of RBRs
iiRBR = find(id == 330);
vecRBR = sn(iiRBR);
% find the index number of Idronauts
iiIDR = find(id == 339);
vecIDR = sn(iiIDR);
% find the index number of S4s
iiS4 = find(id == 302);
vecS4 = sn(iiS4);
% and find index number of RCM11s
iiRCM11 = find(id == 310);
vecRCM11 = sn(iiRCM11);
% and find index number of Sontek Argonauts
iiARG = find(id == 366);
vecARG = sn(iiARG);
% and find index number of Nortek Aquadopps
iiNOR = find((id == 368|id==370));
vecNOR = sn(iiNOR);
% and find index number of Seaguards
iiSG = find(id == 301);
vecSG = sn(iiSG);

depths(:,1) = id([iiMC;iiRBR;iiIDR;iiS4;iiRCM11;iiARG;iiNOR;iiSG]);
depths(:,2) = z([iiMC;iiRBR;iiIDR;iiS4;iiRCM11;iiARG;iiNOR;iiSG]);
depths=sortrows(depths,2);
iiiMC=find(depths(:,1)==337 | depths(:,1)==335);
iiiRBR=find(depths(:,1)==330);
iiiIDR=find(depths(:,1)==339);
iiiS4=find(depths(:,1)==302);  
iiiRCM11=find(depths(:,1)==310);  
iiiARG=find(depths(:,1)==366 | depths(:,1)==366337); 
iiiNOR=find(depths(:,1)==368|depths(:,1)==370);
iiiSG=find(depths(:,1)==301);
iii=[iiiS4;iiiRCM11;iiiARG;iiiNOR;iiiMC;iiiRBR;iiiIDR;iiiSG];

%set figure size on screen for better viewing
bdwidth = 5;
topbdwidth = 30;
set(0,'Units','pixels') 
scnsize = get(0,'ScreenSize');

%set print area of figure
pos1  = [1/8*scnsize(3),8*bdwidth,1/2*scnsize(3),(scnsize(4) - 30*bdwidth)];
temperature_plot=figure('Position',pos1);
set(temperature_plot,'PaperUnits','centimeters');
set(temperature_plot, 'PaperType', 'A4');
set(temperature_plot, 'PaperOrientation',layout);
papersize = get(temperature_plot,'PaperSize');
width=17; height=26; left = (papersize(1)- width)/2; bottom = (papersize(2)- height)/2;
figuresize = [left, bottom, width, height];
set(temperature_plot, 'PaperPosition', figuresize);

plot_string={};

% -----------------------------------
% START OF READING IN INSTRUMENT DATA
% -----------------------------------
%--------------------------------------
% Now read in Microcat data if required
%--------------------------------------
if iiMC>0
    j=1;
    
    % loop to read one file at a time

    for i=1:length(vecMC);
       serialno = vecMC(i);
       disp('*************************************************************')
       disp(['Reading MICROCAT - ',num2str(serialno)])
       disp('*************************************************************')	
       
       if proclvl==2
	       if isunix
        	   infile = [procpath,moor,'/microcat/',moor,'_',sprintf('%0.4d',vecMC(i)),'.use'];
       		elseif ispc
        	   infile = [procpath,moor,'\microcat\',moor,'_',sprintf('%0.4d',vecMC(i)),'.use'];
           end
        elseif proclvl==3
	       if isunix
        	   infile = [procpath,moor,'/microcat/',moor,'_',sprintf('%0.3d',i),'.microcat'];
       		elseif ispc
        	   infile = [procpath,moor,'\microcat\',moor,'_',sprintf('%0.3d',i),'.microcat'];
           end	
       end

       % check if file exists
       fileopen=fopen(infile,'r');
       
       if fileopen>0
           % read data into vectors and then into structure array

           [yy,mm,dd,hh,t,c,p] = ...
               rodbload(infile,'yy:mm:dd:hh:t:c:p');
           jd=julian(yy,mm,dd,hh);

           bad_data=find(t==-9999); t(bad_data)=NaN;

           eval_string(iiiMC(j))={['MC_' num2str(serialno)]};

           eval([char(eval_string(iiiMC(j))) '.jd=jd;']);
           eval([char(eval_string(iiiMC(j))) '.t=t;']);

           sampling_rate = 1/median(diff(jd));
           if filtered==1
                % Apply a butterworth filter to the data using auto_filt and use for
                % plots
           
                ii = eval(['find(~isnan(' char(eval_string(iiiMC(j))) '.t));']); 
                eval([char(eval_string(iiiMC(j))) '.t(ii)=auto_filt(' char(eval_string(iiiMC(j)))...
                 '.t(ii), sampling_rate, 1/2,''low'',4);']);
           end
       end
       j=j+1;
    end
end
%--------------------------------------
% Now read in Idronaut data if required
%--------------------------------------
if iiIDR>0
    j=1;
    
    % loop to read one file at a time

    for i=1:length(vecIDR);
       serialno = vecIDR(i);
       disp('*************************************************************')
       disp(['Reading IDRONAUT - ',num2str(serialno)])
       disp('*************************************************************')

       if isunix
           infile = [procpath,moor,'/idr/',moor,'_',sprintf('%0.4d',vecIDR(i)),'.use'];
       elseif ispc
           infile = [procpath,moor,'\idr\',moor,'_',sprintf('%0.4d',vecIDR(i)),'.use'];
       end

       % read data into vectors and then into structure array
      
       % check if file exists
       fileopen=fopen(infile,'r');
       
       
       if fileopen>0
           
           [yy,mm,dd,hh,t,c,p,] = ...
               rodbload(infile,'yy:mm:dd:hh:t:c:p');
           jd=julian(yy,mm,dd,hh);

           bad_data=find(t==-9999); t(bad_data)=NaN;

           eval_string(iiiIDR(j))={['IDR_' num2str(serialno)]};

           eval([char(eval_string(iiiIDR(j))) '.jd=jd;']);
           eval([char(eval_string(iiiIDR(j))) '.t=t;']);
           
           sampling_rate = 1/median(diff(jd));
           
           if filtered==1
               % Apply a butterworth filter to the data using auto_filt and use for
               % plots

               ii = eval(['find(~isnan(' char(eval_string(iiiIDR(j))) '.t));']); 
               eval([char(eval_string(iiiIDR(j))) '.t(ii)=auto_filt(' char(eval_string(iiiIDR(j)))...
                     '.t(ii), sampling_rate, 1/2,''low'',4);']);
           end
       end
       j=j+1;
    end
end
%--------------------------------------
% Now read in RBR data if required
%--------------------------------------
if iiRBR>0
    j=1;
    
    % loop to read one file at a time

    for i=1:length(vecRBR);
       serialno = vecRBR(i);
       disp('*************************************************************')
       disp(['Reading RBR - ',num2str(serialno)])
       disp('*************************************************************')

       if isunix
           infile = [procpath,moor,'/rbr/',moor,'_',sprintf('%0.4d',vecRBR(i)),'.use'];
       elseif ispc
           infile = [procpath,moor,'\rbr\',moor,'_',sprintf('%0.4d',vecRBR(i)),'.use'];
       end

       % read data into vectors and then into structure array
       
       % check if file exists
       fileopen=fopen(infile,'r');
       
       if fileopen>0
           
           [yy,mm,dd,hh,p,t,c] = ...
               rodbload(infile,'yy:mm:dd:hh:p:t:c');
           jd=julian(yy,mm,dd,hh);

           bad_data=find(t==-9999); t(bad_data)=NaN;

           eval_string(iiiRBR(j))={['RBR_' num2str(serialno)]};

           eval([char(eval_string(iiiRBR(j))) '.jd=jd;']);
           eval([char(eval_string(iiiRBR(j))) '.t=t;']);

           
           sampling_rate = 1/median(diff(jd));
           if filtered==1
               % Apply a butterworth filter to the data using auto_filt and use for
               % plots


               ii = eval(['find(~isnan(' char(eval_string(iiiRBR(j))) '.t));']); 
               eval([char(eval_string(iiiRBR(j))) '.t(ii)=auto_filt(' char(eval_string(iiiRBR(j)))...
                     '.t(ii), sampling_rate, 1/2,''low'',4);']);
           end
       end
       j=j+1;
    end
end

% --------------------
% Read in S4 data if required.
% --------------------
if iiS4>0 
    
    % loop to read one file at a time
    j=1;
    for i=1:length(vecS4);
       serialno = vecS4(i);
       disp('*************************************************************')
       disp(['Reading S4 - ',num2str(serialno)])
       disp('*************************************************************')
       
       if isunix
           infile = [procpath,moor,'/s4/',moor,'_',sprintf('%4.4d',vecS4(i)),'.use'];
       elseif ispc
           infile = [procpath,moor,'\s4\',moor,'_',sprintf('%4.4d',vecS4(i)),'.use'];
       end

       % check if file exists
       fileopen=fopen(infile,'r');
       
       if fileopen>0
           % read data into vectors and then into structure array

           [yy,mm,dd,hh,u,v,t,c,p,hdg] = rodbload(infile,'yy:mm:dd:hh:u:v:t:c:p:hdg');
           jd=julian(yy,mm,dd,hh);

           bad_data=find(t==-9999); t(bad_data)=NaN;

           eval_string(iiiS4(j))={['S4_' num2str(serialno)]};

           eval([char(eval_string(iiiS4(j))) '.jd=jd;']);
           eval([char(eval_string(iiiS4(j))) '.t=t;']);
           
           sampling_rate = 1/median(diff(jd));
           
           if filtered==1
               % Apply a butterworth filter to the data using auto_filt and use for
               % plots


               ii = eval(['find(~isnan(' char(eval_string(iiiS4(j))) '.t));']); 
               eval([char(eval_string(iiiS4(j))) '.t(ii)=auto_filt(' char(eval_string(iiiS4(j)))...
                     '.t(ii), sampling_rate, 1/2,''low'',4);']);
           end
       end
       j=j+1;
       
    end
end

%-----------------------------------
% Now read in RCM11 data if required
%-----------------------------------
if iiRCM11>0
    j=1;
    
    % loop to read one file at a time

    for i=1:length(vecRCM11);
       serialno = vecRCM11(i);
       disp('*************************************************************')
       disp(['Reading RCM11 - ',num2str(serialno)])
       disp('*************************************************************')

       if isunix
           infile = [procpath,moor,'/rcm/',moor,'_',sprintf('%3.3d',vecRCM11(i)),'.use'];
       elseif ispc
           infile = [procpath,moor,'\rcm\',moor,'_',sprintf('%3.3d',vecRCM11(i)),'.use'];
       end

       % check if file exists
       fileopen=fopen(infile,'r');
       
       if fileopen>0
           % read data into vectors and then into structure array

           [yy,mm,dd,hh,ref,u,v,t,c,p,tlt,mss] = rodbload(infile,'yy:mm:dd:hh:ref:u:v:t:c:p:tlt:mss');
           jd=julian(yy,mm,dd,hh);

           bad_data=find(t==-9999); t(bad_data)=NaN;

           eval_string(iiiRCM11(j))={['RCM11_' num2str(serialno)]};

           eval([char(eval_string(iiiRCM11(j))) '.jd=jd;']);
           eval([char(eval_string(iiiRCM11(j))) '.t=t;']);

           sampling_rate = 1/median(diff(jd));
           if filtered==1
               % Apply a butterworth filter to the data using auto_filt and use for
               % plots

               ii = eval(['find(~isnan(' char(eval_string(iiiRCM11(j))) '.t));']); 
               eval([char(eval_string(iiiRCM11(j))) '.t(ii)=auto_filt(' char(eval_string(iiiRCM11(j)))...
                     '.t(ii), sampling_rate, 1/2,''low'',4);']);
           end
       end
       j=j+1;
    end
end

%--------------------------------------
% Now read in Argonaut data if required
%--------------------------------------
if iiARG>0
    j=1;
    
    % loop to read one file at a time

    for i=1:length(vecARG);
       serialno = vecARG(i);
       disp('*************************************************************')
       disp(['Reading ARGONAUT - ',num2str(serialno)])
       disp('*************************************************************')

       if isunix
           infile = [procpath,moor,'/arg/',moor,'_',num2str(vecARG(i)),'.use'];
           if exist(infile)==0  % older Arg files had 4 digit serial number starting with zero in filename
               infile = [procpath,moor,'/arg/',moor,'_0',num2str(vecARG(i)),'.use'];
           end
       elseif ispc
           infile = [procpath,moor,'\arg\',moor,'_',num2str(vecARG(i)),'.use'];
           if exist(infile)==0  % older Arg files had 4 digit serial number starting with zero in filename
               infile = [procpath,moor,'\arg\',moor,'_0',num2str(vecARG(i)),'.use'];
           end
       end

       % check if file exists
       fileopen=fopen(infile,'r');
      
       if fileopen>0
           % read data into vectors and then into structure array

           [yy,mm,dd,hh,t,tcat,p,pcat,c,u,v,w,hdg,pit,rol,usd,vsd,wsd,uss,vss,wss,hdgsd,pitsd,rolsd,ipow] = ...
               rodbload(infile,'yy:mm:dd:hh:t:tcat:p:pcat:c:u:v:w:hdg:pit:rol:usd:vsd:wsd:uss:vss:wss:hdgsd:pitsd:rolsd:ipow');
           jd=julian(yy,mm,dd,hh);

           bad_data=find(t==-9999); t(bad_data)=NaN;

           eval_string(iiiARG(j))={['ARG_' num2str(serialno)]};

           eval([char(eval_string(iiiARG(j))) '.jd=jd;']);
           eval([char(eval_string(iiiARG(j))) '.t=t;']);

           sampling_rate = 1/median(diff(jd));
           if filtered==1
               % Apply a butterworth filter to the data using auto_filt and use for
               % plots


               ii = eval(['find(~isnan(' char(eval_string(iiiARG(j))) '.t));']); 
               eval([char(eval_string(iiiARG(j))) '.t(ii)=auto_filt(' char(eval_string(iiiARG(j)))...
                     '.t(ii), sampling_rate, 1/2,''low'',4);']);
           end
       end
       j=j+1;
    end
end
%--------------------------------------
% Now read in Aquadopp data if required
%--------------------------------------
if iiNOR>0
    j=1;
    
    % loop to read one file at a time

    for i=1:length(vecNOR);
       serialno = vecNOR(i);
       disp('*************************************************************')
       disp(['Reading AQUADOPP - ',num2str(serialno)])
       disp('*************************************************************')

       if isunix
           infile = [procpath,moor,'/nor/',moor,'_',sprintf('%3.3d',vecNOR(i)),'.use'];
       elseif ispc
           infile = [procpath,moor,'\nor\',moor,'_',sprintf('%3.3d',vecNOR(i)),'.use'];
       end
       
       % check if file exists
       fileopen=fopen(infile,'r');
      
       if fileopen>0
           % read data into vectors and then into structure array

           [yy,mm,dd,hh,t,p,u,v,w,hdg,pit,rol,uss,vss,wss,ipow,cs,cd] = ...
               rodbload(infile,'yy:mm:dd:hh:t:p:u:v:w:hdg:pit:rol:uss:vss:wss:ipow:cs:cd');
           jd=julian(yy,mm,dd,hh);

           bad_data=find(t==-9999); t(bad_data)=NaN;

           eval_string(iiiNOR(j))={['NOR_' num2str(serialno)]};

           eval([char(eval_string(iiiNOR(j))) '.jd=jd;']);
           eval([char(eval_string(iiiNOR(j))) '.t=t;']);
           
           sampling_rate = 1/median(diff(jd));
           if filtered==1
               % Apply a butterworth filter to the data using auto_filt and use for
               % plots


               ii = eval(['find(~isnan(' char(eval_string(iiiNOR(j))) '.t));']); 
               eval([char(eval_string(iiiNOR(j))) '.t(ii)=auto_filt(' char(eval_string(iiiNOR(j)))...
                     '.t(ii), sampling_rate, 1/2,''low'',4);']);
           end
       end
       j=j+1;
    end
end
%--------------------------------------
% Now read in SEAGUARD data if required
%--------------------------------------
if iiSG>0
    j=1;
    
    % loop to read one file at a time

    for i=1:length(vecSG);
       serialno = vecSG(i);
       disp('*************************************************************')
       disp(['Reading SEAGUARD - ',num2str(serialno)])
       disp('*************************************************************')

       if isunix
           infile = [procpath,moor,'/seaguard/',moor,'_',sprintf('%3.3d',vecSG(i)),'.use'];
       elseif ispc
           infile = [procpath,moor,'\seaguard\',moor,'_',sprintf('%3.3d',vecSG(i)),'.use'];
       end

       % check if file exists
       fileopen=fopen(infile,'r');
       
       if fileopen>0
           % read data into vectors and then into structure array

           [yy,mm,dd,hh,u,v,cs,cd,cssd,mss,hdg,pit,rol,t,c,tc,p,tp,ipow] = ...
            rodbload(infile,'YY:MM:DD:HH:U:V:CS:CD:CSSD:MSS:HDG:PIT:ROL:T:C:TC:P:TP:IPOW');
            
           jd=julian(yy,mm,dd,hh);

           bad_data=find(t==-9999); t(bad_data)=NaN;

           eval_string(iiiSG(j))={['SG_' num2str(serialno)]};

           eval([char(eval_string(iiiSG(j))) '.jd=jd;']);
           eval([char(eval_string(iiiSG(j))) '.t=t;']);
           sampling_rate = 1/median(diff(jd));
           
           if filtered==1

               % Apply a butterworth filter to the data using auto_filt and use for
               % plots

               ii = eval(['find(~isnan(' char(eval_string(iiiSG(j))) '.t));']); 
               eval([char(eval_string(iiiSG(j))) '.t(ii)=auto_filt(' char(eval_string(iiiSG(j)))...
                     '.t(ii), sampling_rate, 1/2,''low'',4);']);
           end
       end
       j=j+1;
    end
end


% ------------------------------
% Plotting section
% ------------------------------
colours = 'bkbkbkbkbkbkbkbkbkbkbkbkbkbkbkbkbkbkbkbkbkbkbkbkbkbk';

emptycellcheck=cellfun('isempty',eval_string);
eval_string(emptycellcheck)=[];  
depths = depths(~emptycellcheck,:);
for i=1:length(eval_string)
    figure(temperature_plot); hold on
    eval(['plot(' char(eval_string(i)) '.jd-jd1,' char(eval_string(i)) '.t,''' colours(i) ''');']);
end

figure(temperature_plot);
ylabel('temperature (deg C)');
xlim([0 jd2-jd1]);
%limits=get(gca,'ylim');
%limits(1)=0;
%set(gca,'ylim',limits)
set(gca,'YMinorTick','on');
%set(gca,'YDir','reverse');
set(gca,'xTickLabel',xticklabels);
set(gca,'XTick',jdxticks-jd1);
s = regexprep(moor,'_','\\_');
if filtered==1
title(['Low-pass filtered temperature from mooring: ' s])
else
title(['Unfiltered temperature from mooring: ' s])
end

% Display year labels on bottom graph
Y_limits=ylim;   X_limits=xlim;
a=(Y_limits(1)-Y_limits(2))*1.05+Y_limits(2);
text(X_limits(1),a,num2str(xticks(1,1)),'FontSize',10);
for i=1:length(year_indexes)
    text((jd2-jd1)*(year_indexes(i)-1)/(length(xticklabels)-1),a,num2str(xticks(year_indexes(i),1)),'FontSize',10);
end


% label data with nominal instrument depth
label_x_positions=(X_limits(2)-X_limits(1))*1.005+X_limits(1);


for i=1:length(eval_string)
    label_y_positions=eval(['nanmedian(' char(eval_string{i}) '.t);']); 
    eval(['text(label_x_positions, label_y_positions,[num2str(depths(i,2)) ''m''],''FontSize'',8,''color'',''' colours(i) ''');'])
end

print('-dpng',[moor '_temperature_overlay_proclvl_' proclvlstr])
savefig([moor '_temperature_overlay_proclvl_' proclvlstr])
