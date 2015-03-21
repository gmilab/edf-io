function [ edfdata ] = edf_getalldata( EDF_PATH, varargin )
%EDF_GETALLDATA read all channels from a given EDF file and will
%       automatically perform a line noise notch filter at 60Hz unless otherwise specified.
%
% Arguments
%   notch -     integer or 'off'  (Default: 60Hz)
%               Set the frequency for notch filter for line noise in Hz, or
%               turn off notch filter completely.
%   notchharms -    integer    (Default: 4)
%                   number of frequency multiples of the line noise frequency should be subtracted.
%                   By default, this would filter at 60, 120, 180, 240, 300Hz.
%
% Returns
%   edfdata.data - EEG recording. (time x channels)
%   edfdata.num_samples - Number of samples
%   edfdata.num_channels - Number of channels
%   edfdata.ch_label - Electrode names for each individual channel (channels x 1 cell array)
%   edfdata.srate - Sampling rate of the EEG recording
%
% Simeon Wong
% simeon.wong@sickkids.ca
% 2015 Feb 2
% 
% Doesburg Lab - Hospital for Sick Children

    %% Parse Inputs
    p = inputParser;
    
    notch_valfn = @(x) assert(isnumeric(x) || strcmp('off', x), 'Parameter "notch" must be numeric or "off"');
    addParameter(p, 'notch', 60, notch_valfn);
    addParameter(p, 'notchharms', 4, @isnumeric);
    
    parse(p, varargin{:});
    
    %% Load file

    edffile = edf_fopen(EDF_PATH);
    edfdata.data = edf_fread(edffile, 0, edffile.total_duration);
    edf_fclose(edffile);

    edfdata.num_samples = edffile.number_of_samples(1);
    edfdata.num_channels = length(edffile.number_of_samples);

    edfdata.ch_label = cellstr(edffile.header.label);

    % ** Sanity Check **
    % If sampling rates are different for different channels
    if max(edffile.sampling_rate) ~= min(edffile.sampling_rate)
        error('Inconsistent sampling rate!');
    else
        edfdata.srate = edffile.sampling_rate(1);
    end

    % If number of samples are different for different channels
    if max(edffile.number_of_samples) ~= min(edffile.number_of_samples)
        error('Inconsistent data length!');
    end
    
    if isnumeric(p.Results.notch)
        % Then perform notch filter
        % Based off fieldtrip notchfilter.m (Pascal Fries, Robert Oostenveld)
        
        Fn = edfdata.srate/2;           % Nyquist frequency
        
        for fq = ((0:p.Results.notchharms)+1) * p.Results.notch
            Fl = fq+[-2,+2];

            [z,p,k] = butter(6, [min(Fl)/Fn max(Fl)/Fn], 'stop');
            sos = zp2sos(z,p,k);
            edfdata.data = filtfilt(sos, 1, edfdata.data);     % filtfilt assumes time x ... dimensions
        end
    end

end

