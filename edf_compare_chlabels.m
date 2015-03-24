function [out] = edf_compare_chlabels(main_list, sub_list)
% EDF_COMPARE_CHLABELS - compares channel label cell arrays coming from edf_getalldata, and some
% cell array list that has been generated through analysis code
%
% Simeon Wong
% 2015 March 24

out = false(length(main_list),1);
for kk = 1:length(sub_list)
    out = out | strcmp(main_list, sub_list{kk});
end

end