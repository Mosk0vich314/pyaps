function Settings = Save_data(varargin)

%% retrieve settings and save
Settings = varargin{1};
filename = varargin{end};

%% create timestamp
Settings.timestamp_stop = datetime;

save(filename, 'Settings', '-v7.3')

%% append remaining structures
for i = 2:nargin-1
    data = varargin{i};
    if isstruct(data)

        name = inputname(i);
        
        % create variable with name corresponding to type
        eval([name '= data;'])
        
        % save mat file
        save(filename, name, '-append')
        
    end
end