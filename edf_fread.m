function edf_data = edf_fread(edf_file, start_time, duration, varargin)
% EDF_FREAD  read data from an EDF+ file
%
% edf_fread(edf_file, start_time, duration)
% 
% Arguments:
%     edf_file: structure for an EDF+ file (from edf_fopen)
%     start_time: starting from 0 second
%     duration: in seconds
%
% Outputs:
%     .data(n_timepoints, n_ch): read data
%     .annotations: cell array of structures with annotation information
%
% Script came from unknown origins, but seems to work?
%
% Edited by Simeon Wong (2015 Feb 6)
%  - use inputparser to clarify conversion option
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Check inputs
p = inputParser;
addOptional(p, 'start_time', 0);
addOptional(p, 'duration', edf_file.total_duration);
addParameter(p, 'conversion', true, @islogical);
addParameter(p, 'annotations', false, @islogical);
parse(p, start_time, duration, varargin{:});

if p.Results.start_time < 0
    error('Start time must be >= 0');
end

if p.Results.duration < 1
    error('Duration must be >= 1');
end

%% Do stuff
start_point = round(edf_file.sampling_rate * p.Results.start_time);
end_point = start_point + round(edf_file.sampling_rate * p.Results.duration) - 1;

ch_max_sampling_rate = find(edf_file.sampling_rate == max(edf_file.sampling_rate));
ch_max_sampling_rate = ch_max_sampling_rate(1);

start_record_number = floor(start_point(ch_max_sampling_rate) ...
    / edf_file.header.number_of_samples_in_each_data_record(ch_max_sampling_rate)) + 1;
end_record_number = floor(end_point(ch_max_sampling_rate) ...
    / edf_file.header.number_of_samples_in_each_data_record(ch_max_sampling_rate)) + 1;

start_offset = mod(start_point, edf_file.header.number_of_samples_in_each_data_record(ch_max_sampling_rate));
end_offset = mod(end_point, edf_file.header.number_of_samples_in_each_data_record(ch_max_sampling_rate));

if end_record_number > edf_file.header.number_of_data_records
    end_record_number = edf_file.header.number_of_data_records;
    end_offset = edf_file.header.number_of_samples_in_each_data_record - 1;
end

data_record = edf_fread_record(edf_file, start_record_number, end_record_number - start_record_number + 1, 'conversion', false);

for ch = edf_file.header.number_of_signals_in_data_record:-1:1
    start = start_offset(ch) + 1;
    finish = (end_record_number - start_record_number) * ...
        edf_file.header.number_of_samples_in_each_data_record(ch) + end_offset(ch) + 1;
    edf_data.data(:, ch) = data_record(start:finish, ch);
    
end

if p.Results.annotations
    ann_ch = find(strcmp(cellstr(edf_file.header.label), 'EDF Annotations'));
    for ch = ann_ch
        
    end
end

% Convert from raw integer values to actual values
if p.Results.conversion
    for ch = 1:edf_file.header.number_of_signals_in_data_record
        edf_data.data(:,ch) = (edf_data.data(:,ch) - edf_file.header.digital_minimum(ch)) * ...
            (edf_file.header.physical_maximum(ch) - edf_file.header.physical_minimum(ch)) / ...
            (edf_file.header.digital_maximum(ch) - edf_file.header.digital_minimum(ch))...
            + edf_file.header.physical_minimum(ch);
    end
end


if size(edf_data.data, 1) ~= edf_file.sampling_rate * p.Results.duration
    edf_data.data((end + 1):edf_file.sampling_rate * p.Results.duration, :) = 0;
end
