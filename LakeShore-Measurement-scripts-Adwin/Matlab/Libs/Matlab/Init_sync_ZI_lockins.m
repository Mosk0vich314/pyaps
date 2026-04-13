function [mds, devices] = Init_sync_ZI_lockins(device_ids)

devices = lower(strjoin(device_ids, ','));

%% Start MDS
mds = ziDAQ('multiDeviceSyncModule');
ziDAQ('set', mds, 'start', 0);
ziDAQ('set', mds, 'group', 0)
ziDAQ('execute', mds);
ziDAQ('set', mds, 'devices', devices);

end