function [info] = edf_info(path)

info = edf_fopen(path);
edf_fclose(info);

info.fid = [];


end

