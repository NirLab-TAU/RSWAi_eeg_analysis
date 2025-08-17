function [nonRSWA_data] = select_nonRSWA(data)
cd ('list_path')
load('nonRSWA_List.mat');
ind =1;
for D= 1:length(data)
    for L = 1:length(nonRSWA_List)
        if strcmp(data{2,D}(1:4),nonRSWA_List{1,L})
            sub_indx(ind) = D;
            nonRSWA_data{1,ind} = data{1,D};
            nonRSWA_data{2,ind} = data{2,D};
            ind = ind+1;
        end
    end
end
end