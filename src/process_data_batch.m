files = dir('EIT_*.vhdr');
files = {files.name};

for iN = 6:length(files)
    
    
    path_n = 'E:\Rat_049\EIT';
    EIT_n = files{iN};
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
    Plot = 0; %Set to 0 if you don't want a figure
    if Plot
        figure('units','normalized','outerposition',[0 0 1 1])
    end

    %Finds time when current injection pair is switched
    [inj_switch] = get_switching_time(EEG_fname, info);


%     for i=1:length(EEG_fname.EVENT.POS)
%         if strcmp([EEG_fname.EVENT.Desc{i}], ['S  1']);
%             inj_switch(1) = EEG_fname.EVENT.POS(i);
%         end
%         if strcmp([EEG_fname.EVENT.Desc{i}], ['S  8']);
%             inj_switch(2) = EEG_fname.EVENT.POS(i);
%         end  
%     end

%inj_switch(2) = EEG_fname.EVENT.POS(256);
    %Detect carrier frequency from injecting pair just to make sure same as
    %info.Fc
    get_carrier_freq(inj_switch, info, EIT_fname);

    for iPair =1:info.Prt_size

        %Load in data for ith injection pair
        EEG = pop_loadbv('', EIT_fname, [inj_switch(iPair) round(inj_switch(iPair+1))]);
         Data = double(EEG.data(:,:)');



        %Finds the time points where stimulation occurs
        [T_trig] = get_stim_time(EEG, info);

        %Apply filters to raw data to extract EPs and dZs
        %[X_ep, A_dz, X_sin] = filter_data(Data, info);
         [X_ep, A_dz] = filter_data(Data, info);

         clear Data

        %Segment data into trials around stimulation point
         [EP, dZ, BV, T, N_bin, N_chan] = segment_data(X_ep, A_dz,  T_trig, info);


         clear X_ep A_dz

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

   save([files{iN}(1:end-5)], 'EIT', '-v7.3');
    
    end
  clearvars -except iN files
end

