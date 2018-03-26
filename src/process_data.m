path_n = 'E:\Rat_041\EIT\EIT_001';
EIT_n = 'EIT_001.vhdr';
EIT_fname = fullfile(path_n, EIT_n);
EEG_fname = sopen([EIT_fname(1:end-5) '.eeg']);
log_fname = ([EIT_fname(1:end-5) '_log.mat']);

%log_fname = ['freq_1_log.mat'];

load(log_fname);

%Read in information from ExpSetup
%Protocol
info.Prt = ExpSetup.Protocol;
info.Prt_size = size(ExpSetup.Protocol,1);
%Time between stimuli (s)
info.T_window = ExpSetup.StimulatorTriggerTime/1000;
%info.T_window = 250/1000;
%Injection time
info.Meas_time = ExpSetup.MeasurementTime/1000;

%Injection frequency
info.Fc = ExpSetup.Freq;
%Actichamp sample rate
info.Fs = EEG_fname.SampleRate;
%EP cutoff frequency
info.EP_cutoff = 1000;
%Bandwidth around carrier
info.dZ_BW = 500;
%Order of butterworth filter
info.N_butter_EP = 5;
info.N_butter_dZ = 5;

%Create figure
Plot = 1; %Set to 0 if you don't want a figure
if Plot
    figure('units','normalized','outerposition',[0 0 1 1])
end

%Finds time when current injection pair is switched
[inj_switch] = get_switching_time(EEG_fname, info);


% for i=1:length(EEG_fname.EVENT.POS)
%     if strcmp([EEG_fname.EVENT.Desc{i}], ['S  1']);
%         inj_switch(1) = EEG_fname.EVENT.POS(i);
%     end
%     if strcmp([EEG_fname.EVENT.Desc{i}], ['S  8']);
%         inj_switch(2) = EEG_fname.EVENT.POS(i);
%     end  
% end


%Detect carrier frequency from injecting pair just to make sure same as
%info.Fc
get_carrier_freq(inj_switch, info, EIT_fname);

for iPair =1%1:info.Prt_size
    
    %Load in data for ith injection pair
    EEG = pop_loadbv('', EIT_fname, [inj_switch(iPair) round(inj_switch(iPair+1))]);
   % EEG = pop_loadbv('', EIT_fname, [inj_switch(iPair) inj_switch(iPair)+180*info.Fs]);
    %EEG = pop_loadbv('', EIT_fname, [(inj_switch(iPair)+120*info.Fs +1) inj_switch(iPair+1)]);
   % EEG = pop_loadbv('', EIT_fname, [5*25000 120*25000]);
    Data = double(EEG.data(:,:)');
    
    
    
    %Finds the time points where stimulation occurs
    [T_trig] = get_stim_time(EEG, info);
    
    %Apply filters to raw data to extract EPs and dZs
    %[X_ep, A_dz, X_sin] = filter_data(Data, info);
     [X_ep, A_dz, X_dz] = filter_data(Data, info);
     
     %clear Data
    
    %Segment data into trials around stimulation point
     [EP, dZ, BV, T, N_bin, N_chan] = segment_data(X_ep, A_dz,  T_trig, info);
     
     
     %clear X_ep A_dz
    
    %Average over trials
    [avg_EP, avg_dZ_abs, avg_dZ_rel, avg_dZ_std, BV0, idx] = compute_averages(EP, dZ, BV, T, N_bin, N_chan);
    
    %Store data
    EIT{iPair}.Pair = info.Prt(iPair,:);
    EIT{iPair}.EP_avg = avg_EP;
    EIT{iPair}.dZ_avg = avg_dZ_abs;
    EIT{iPair}.dZ_per = avg_dZ_rel;
    EIT{iPair}.dZ_std = avg_dZ_std;
    EIT{iPair}.BV0 = BV0;
    EIT{iPair}.idx = idx;
    
%     for iChan = 1:16
%     dZ_depth{1,iChan} = dZ{1,63+iChan};
%     end
% 
%     trials = size(dZ_depth{1,1},2)-1;
% 
%     for iChan = 1:size(dZ_depth,2)
%         quarter_avg(:,iChan) = mean(dZ_depth{iChan}(:,1:trials/4),2);
%         half_avg(:,iChan) = mean(dZ_depth{iChan}(:,1:trials/2),2);
%         full_avg(:,iChan) = mean(dZ_depth{iChan}(:,1:end),2);
%     end
%     
%     EIT{iPair}.quart_avg = quarter_avg;
%     EIT{iPair}.half_avg = half_avg;
%     EIT{iPair}.full_avg = full_avg;
% clear m_EP
% t = find(T>2 & T<10);
% for iChan = 1:16
%     EP_depth{1,iChan} = EP{1,iChan+63};
% end
% 
% for iChan = 1:16
%      m_EP(iChan,:) = max(EP_depth{1,iChan}(t,:));
% end
% 
% EP_max{iPair} = m_EP;
%clear A_dz X_ep Data BV dZ EP avg_dZ_abs avg_dZ_rel avg_dZ_std BV0    
plot(T,avg_dZ_abs(:,:));
    drawnow;
%     if Plot
%         chan = [1:N_chan];
%         %Bad channels assuming connected in order LA, LB, RA, RB
%         bad_chan = [info.Prt(iPair,1), info.Prt(iPair,2)];
%         plot_chan = setdiff(chan, bad_chan);
%         
%         subplot(round(sqrt(info.Prt_size))+1,round(info.Prt_size/round(sqrt(info.Prt_size))),iPair);
%        % plot(T,detrend(avg_dZ_abs(:,plot_chan)))
%          plot(T,detrend(avg_dZ_abs(:,1:end)))
%         title(['Pair=' num2str(iPair)]);
%         grid on
%         ylabel('dZ (uV)')
%         drawnow
%     end
end

