function mds = Sync_ZI_lockins(mds)

ziDAQ('set', mds, 'start', 1)

timeout = 20;
tic;
start = toc;
status = 0;
while status ~= 2
    pause(0.2)
    status = ziDAQ('getInt', mds, 'status');
    if status == -1
        error('Error during device sync');
    end
    if (toc - start) > timeout
        error('Timeout during device sync');
    end
end

ziDAQ('set', mds, 'phasesync', 1)