function Timetrace = Run_timetrace_poll(Timetrace, Lockin)

%% settings
poll_timeout = 0.01;

%% remove data fields, if existing
try
    Timetrace = rmfield(Timetrace, 'data');
    Timetrace = rmfield(Timetrace, 'time');
end

%% run measurement
done = 0;
Attempts = 1;
timeout = 20;

tic
while done == 0 && toc < timeout
    try % try loop is to make sure data is acquired, not always the case, for example just after autoranging

        %% run poll, with a minimum added time of 5ms and a maximum of 50ms.
        data = ziDAQ('poll', Timetrace.runtime + min([0.05 max([0.005 Timetrace.runtime*0.05])]) , poll_timeout);

        %% sort data
        L = zeros(Timetrace.N_devices, 1);
        counter =1 ;
        for i = 1:Timetrace.N_devices

            dev = lower(Timetrace.device_list{i});

            for k = 1:Timetrace.N_demods(i)

                demod = sprintf('demod%01d', k);

                %% find large interuptions in time by looking for big jumps in diff(timestamps)
                [B, I] = sort(double(diff(data.(dev).demods(k).sample.timestamp)));
                B = fliplr(B);
                I = fliplr(I);
                if B(1) > 10*B(2)
                    start_idx = I(1) + 1;
                else
                    start_idx = 1;
                end

                %% find end time
                time = data.(dev).demods(k).sample.timestamp(1:end);
                time(start_idx:end) = time(start_idx:end) - B(1) + B(end);

                %% find time
                time = (double(time) - double(time(1))) / Timetrace.clockbase;
                start_time = max([0 time(end)-Timetrace.runtime]);

                start_idx = find(min(abs(time - start_time)) == abs((time - start_time)));
                time = time(start_idx:end);

                %% shift time to zero
                time = time - time(1);

                %% cut data to timetrace length
                for j = 1:Timetrace.N_channels
                    Data.(dev).(demod).(Lockin.dev1.channels{j}) = data.(dev).demods(k).sample.(Lockin.dev1.channels{j})(start_idx:end);
                end

                Timetrace.time.(dev) = time';
                Timetrace.data.(dev) = Data.(dev);

                L(counter) = numel(Timetrace.time.(dev));
                counter = counter + 1;
            end
        end

        %% check is time trace length is same for each device and demodulator
        if numel(unique(L)) == 1
            done = 1;
        else
            fprintf('%s - Polling length error, restarting timetrace, try %01d ... \n', datetime('now'), Attempts);
        end

        Attempts = Attempts + 1;

    catch
        fprintf('%s - Waiting for successful poll\n', datetime('now'));
    end
end
