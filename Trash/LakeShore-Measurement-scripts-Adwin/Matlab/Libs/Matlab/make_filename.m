function filename = make_filename()
% generates new filename based on date with format %y%m%d

try
    load('../../filename.mat');
    Date_old = data.Date;
catch
    Date_old = date;
    data.runnumber = 1;
end

data.Date = date;


if regexp(data.Date, Date_old)
    data.runnumber = data.runnumber + 1;
else
    data.runnumber = 1;
end
 
save('../../filename.mat','data');

[Y,M,D] = datevec(data.Date);
filename = sprintf('%01d-%02d-%02d_run%01d',Y,M,D,data.runnumber);

