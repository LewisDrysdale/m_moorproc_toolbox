function [oxygen_out]=mcoxyhyst(oxygen_sbe,time,press,H1,H2,H3)
% [oxygen_out]=mcoxyhyst(oxygen_sbe,time,press,H1,H2,H3)
%
% gdm on di346
% function to apply an adjustment for hysteresis in the oxygen sensor
% the algorithm is the one used by SeaBird from April 2009 to correct for
% hysteresis. oxygen_sbe should not have been processed using the 
% hysteresis correction before input here. 
% 
% the default values and ranges for the constants are:
% H1     -0.033     [-0.02 to -0.05]   - pressure scale factor
% H2      5000                         - pressure normalization
% H3      1450      [1200  to  2000]   - time normalization

oxygen_out=oxygen_sbe;

kfirst = min(find(isfinite(oxygen_sbe)));
klastgood = kfirst; % keep track of most recent good cycle

for k=kfirst+1:length(time)
    % bak: 23 jan 2010 need to be able to step over nans
    %     oxygen_out(k)=((oxygen_sbe(k)+(oxygen_out(k-1)*C*D))-(oxygen_sbe(k-1)*C))/D;
    % bak: 29 feb 2012 there are some nans in press after cleaning up raw
    %     file on jc069_064. raw file has spikes due to noisy telemetry
    %     through slip rings
    %     therefore oxygen is nan if eitehr oxygen_sbe or press is nan
    if isnan(oxygen_sbe(k)+press(k))
        oxygen_out(k) = nan; %already the case because of initialisation of oxygen_out
    else
        if press(k) < 0; press(k) = 0; end
        D=1+H1*(exp(press(k)/H2)-1);
        C=exp(-1*(time(k)-time(klastgood))/H3);
        oxygen_out(k)=((oxygen_sbe(k)+(oxygen_out(klastgood)*C*D))-(oxygen_sbe(klastgood)*C))/D;
        klastgood = k;
    end
end;
