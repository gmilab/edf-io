function data = edf_fread_record(edf_file, start_record_number, number_of_records, varargin)
% EDF_FREAD_RECORD  read a data record from an EDF+ file
%
% edf_fread_record(edf_file, start_record_number)
%
% Arguments:
%     edf_file: structure for an EDF+ file
%     start_record_number: starting from 1
%     number_of_records: number_of_records to read
%
% Outputs:
%     data_record (n_timepoints, n_ch): read data record
%
% Script came from unknown origins, but seems to work?
%
% Edited by Simeon Wong (2015 Feb 6)
%  - use inputparser to clarify conversion option
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parse inputs

p = inputParser;
addParameter(p, 'conversion', true, @islogical);
parse(p, varargin{:});

if start_record_number < 1 || start_record_number > edf_file.header.number_of_data_records
    error('Start record number is out of range');
end

if number_of_records < 1 || start_record_number + number_of_records - 1 > edf_file.header.number_of_data_records
    error('Number of records to read is too big');
end

%% Read stuff
file_position = edf_file.header.number_of_bytes_in_header_record + ...
    (start_record_number - 1) * edf_file.number_of_bytes_in_data_record;
fseek(edf_file.fid, file_position, 'bof');

data = zeros(edf_file.header.number_of_samples_in_each_data_record(1) * number_of_records, edf_file.header.number_of_signals_in_data_record);
for count = 1:number_of_records
    for ch = 1:edf_file.header.number_of_signals_in_data_record
        data_record = fread(edf_file.fid, edf_file.header.number_of_samples_in_each_data_record(ch), 'int16');
        
        % Convert from raw integer values to actual values
        if p.Results.conversion
            data_record = (data_record - edf_file.header.digital_minimum(ch)) * ...
                (edf_file.header.physical_maximum(ch) - edf_file.header.physical_minimum(ch)) / ...
                (edf_file.header.digital_maximum(ch) - edf_file.header.digital_minimum(ch))...
                + edf_file.header.physical_minimum(ch);
        end
        
        start = (count - 1) * edf_file.header.number_of_samples_in_each_data_record(ch) + 1;
        finish = start + edf_file.header.number_of_samples_in_each_data_record(ch) - 1;
        data(start:finish, ch) = data_record;
    end
end

