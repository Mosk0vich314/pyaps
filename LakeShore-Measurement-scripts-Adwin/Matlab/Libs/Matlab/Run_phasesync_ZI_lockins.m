function Run_phasesync_ZI_lockins(mds, devices)

fprintf('Synchronizing phase devices %s ...\n', devices);

ziDAQ('set', mds, 'phasesync', 1)

fprintf('Phase successfully synchronized.\n');