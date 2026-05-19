function Save_data_dat(Settings, running_var_struct, stepped_var_structure, filename, data_name)


%% make directory
if ~exist(sprintf('%s/dat/', Settings.save_dir),'dir')
    mkdir(sprintf('%s/dat/', Settings.save_dir));
end

%% selected measurement type
if strcmp(Settings.type,'IVs')
    running_variable = running_var_struct.bias;
    stepped_variable = 1:running_var_struct.repeat;
end
if strcmp(Settings.type,'Stability')
    running_variable = running_var_struct.bias;
    stepped_variable = stepped_var_structure.voltage;
end
if strcmp(Settings.type,'Gatesweep')
    running_variable = running_var_struct.bias;
    stepped_variable = stepped_var_structure.voltage;
end
if strcmp(Settings.type,'Gatesweep_4p_I')
    running_variable = running_var_struct.bias;
    stepped_variable = stepped_var_structure.DCcurrent;
end
if strcmp(Settings.type,'Gatesweep_4p_V')
    running_variable = running_var_struct.bias;
    stepped_variable = stepped_var_structure.voltage;
end
if strcmp(Settings.type,'Gatesweep_4p_Vac')
    running_variable = running_var_struct.bias;
    stepped_variable = stepped_var_structure.voltage;
end
if strcmp(Settings.type,'Gatesweep_lockin_ampl')
    running_variable = running_var_struct.bias;
    stepped_variable = stepped_var_structure.amplitude;
end
if strcmp(Settings.type,'Gt')
    running_variable = running_var_struct.time;
    stepped_variable = 1:running_var_struct.repeat;
end
if strcmp(Settings.type,'Thermocurrent')
    running_variable = running_var_struct.bias;
    stepped_variable = 1:running_var_struct.repeat;
end

%% create files
fID = zeros(Settings.N_ADC,1);
filenames = cell(Settings.N_ADC,1);
[~,name,~] = fileparts(filename);

if Settings.N_ADC > 1
    for k = 1:Settings.N_ADC
        filenames{k} = sprintf('%s/dat/%s_channel_%01d.dat', Settings.save_dir, name, Settings.ADC_idx(k));
        fID(k) = fopen(filenames{k},'w');
    end
else
    filenames = sprintf('%s/dat/%s.dat', Settings.save_dir, name);
    fID = fopen(filenames,'w');
end

%% export settings
for k = 1:Settings.N_ADC
    names = fieldnames(Settings);
    fprintf(fID(k), 'Settings:\t' );
    
    data = Settings;
    for j=1:length(names)
        text = names{j};
        value =  getfield(data, names{j});
        
        if iscell(getfield(data, names{j}))
            fprintf(fID(k), '%s=\t' , text );
            for i=1:length(value)
                fprintf(fID(k), '%s\t' , value{i});
            end
            fprintf(fID(k), ' ; ');
        end
        
        if ~iscell(getfield(data, names{j})) && length(value)~=1 && ~ischar(value)
            fprintf(fID(k), '%s=\t' , text );
            for i=1:length(value)
                fprintf(fID(k), '%1.0f\t' , value(i));
            end
            fprintf(fID(k), ' ; ');
        end
        
        
        if ischar(value)
            fprintf(fID(k), '%s=\t%s ; ' , text, value);
        end
        
        if isfloat(value) && ~sum((round(value)==value)) && length(value)==1
            if value > 1e3
                fprintf(fID(k), '%s=\t%1.4e ; ' , text, value);
            else
                fprintf(fID(k), '%s=\t%1.4f ; ' , text, value);
            end
        end
        
        if isfloat(value) && sum((round(value)==value)) && length(value)==1
            fprintf(fID(k), '%s=\t%1.0f ; ' , text, value);
        end
    end
    fprintf(fID(k),'\n');
end

%% export running variable structures
names = fieldnames(running_var_struct);

for k = 1:Settings.N_ADC
    
    fprintf(fID(k), '%s:\t'     , running_var_struct.type);
    
    for j=1:length(names)
        if ~iscell(getfield(running_var_struct, names{j})) && length(getfield(running_var_struct, names{j}))==1
            text = names{j};
            value =  getfield(running_var_struct, names{j});
            if ischar(value)
                fprintf(fID(k), '%s=\t%s ; ' , text, value);
            end
            if isfloat(value) && ~(round(value)==value)
                if value > 1e3
                    fprintf(fID(k), '%s=\t%1.4e ; ' , text, value);
                else
                    fprintf(fID(k), '%s=\t%1.4f ; ' , text, value);
                end
            end
            if isfloat(value) && (round(value)==value)
                fprintf(fID(k), '%s=\t%1.0f ; ' , text, value);
            end
        end
    end
    
    fprintf(fID(k),'\n');
end

%% export stepped variable structures
try
    names = fieldnames(stepped_var_structure);
    
    for k = 1:Settings.N_ADC
        
        fprintf(fID(k), '%s:\t'     , stepped_var_structure.type);
        
        for j=1:length(names)
            if ~iscell(getfield(stepped_var_structure, names{j})) && length(getfield(stepped_var_structure, names{j}))==1
                text = names{j};
                value =  getfield(stepped_var_structure, names{j});
                if ischar(value)
                    fprintf(fID(k), '%s=\t%s ; ' , text, value);
                end
                if isfloat(value) && ~(round(value)==value)
                    if value > 1e3
                        fprintf(fID(k), '%s=\t%1.4e ; ' , text, value);
                    else
                        fprintf(fID(k), '%s=\t%1.4f ; ' , text, value);
                    end
                end
                if isfloat(value) && (round(value)==value)
                    fprintf(fID(k), '%s=\t%1.0f ; ' , text, value);
                end
            end
        end
        
        fprintf(fID(k),'\n');
        fprintf(fID(k),'[Data]\n');
        
        fclose(fID(k));
    end
    
catch
    disp('No stepped variable found');
end

%% export data
data = getfield(running_var_struct, data_name);

[n1, n2] = size(running_variable);
if n1<n2
    running_variable = running_variable';
end

for k = 1:Settings.N_ADC
    data_formated = data{k};
    
    [n1, n2] = size(data_formated);
    if n1<n2
        data_formated = data_formated';
    end

    data_formated = [running_variable data_formated];
    data_formated = vertcat([NaN stepped_variable], data_formated);
    if Settings.N_ADC > 1
        dlmwrite(filenames{k}, data_formated,'delimiter','\t','-append','precision','%.6e')
    else
        dlmwrite(filenames, data_formated,'delimiter','\t','-append','precision','%.6e')
    end
end