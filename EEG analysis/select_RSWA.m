function [RSWA_data] = select_RSWA(data)
cd ('list_path')
load('RSWA_List.mat');
ind =1;
for D= 1:length(data)
    for L = 1:length(RSWA_List)
        if strcmp(data{2,D}(1:4),RSWA_List{1,L})
            sub_indx(ind) = D;
            RSWA_data{1,ind} = data{1,D};
            RSWA_data{2,ind} = data{2,D};
            ind = ind+1;
        end
    end
end
end