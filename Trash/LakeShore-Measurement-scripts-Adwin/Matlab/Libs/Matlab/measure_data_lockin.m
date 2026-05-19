%This function measures the x and y channel of the lockin and returns data
%the first column is x data and the second is the y data. 100 instances of
%the x and y data are taken over 10s and the averaged value is returned.
%this is only made for EGG7265. Wont work for other lockins
function data = measure_data_lockin(Lockin)
temp_data=zeros(100,2);
        for k=1:100
            temp_data(k,1)=Lockin.dev.read_ch_x();
            temp_data(k,2)=Lockin.dev.read_ch_y();
            pause(0.1);
        end
        data(1,1)= mean(temp_data(:,1));
        data(1,2)= mean(temp_data(:,2));
