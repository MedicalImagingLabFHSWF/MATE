function info = datenEinlesen(modus)
% 1) Reads datasets, depending on the mode, from different folders
% 2) Returns information about the found datasets:
% {Run, Power, Start, End, Name, video path, table path}.

if strcmpi(modus, 'training')
    % Set folder for training data
    ordner = 'C:\Users\sarah\Desktop\MESS\training data';
elseif strcmpi(modus, 'testing')
    % Set folder for testing data
    ordner = 'C:\Users\sarah\Desktop\MESS\testing data';
end

% Read all files in the folder
Dateien = dir(fullfile(ordner, '*.*'));
info = {};

fprintf('Total files: ', num2str(numel(Dateien)));

% Iterate through all files in the folder
for i = 1:numel(Dateien)
    % Skip if it is a subfolder
    if Dateien(i).isdir
        continue;
    end

    % Read file name and file extension
    [~, Dateiname, Dateiende] = fileparts(Dateien(i).name); 
    
    % Skip the file if it is not a video
    if ~strcmpi(Dateiende, '.mp4')
        continue;
    end 

    % Split the file name by underscores
    Name_teil = split(Dateiname, '_');

    % Skip the file if the name does not have 4 parts
    if numel(Name_teil) ~= 4 
        fprintf(['Skipping (not a 4-part name): ', Dateiname]);
        continue;
    end

    % Define variables from the file name parts
    Durchlauf = str2double(Name_teil{1}); % Run
    Leistung = Name_teil{2};             % Power
    Start = str2double(Name_teil{3});    % Start time
    Ende = str2double(Name_teil{4});     % End time
    
    % The associated video name matches the table name
    Videopfad = fullfile(ordner, Dateiname);

    if strcmpi(Dateiende, '.xlsx') || strcmpi(Dateiende, '.csv')
        % Found a file, append it to the list of datasets
        info(end+1, :) = {Durchlauf, Leistung, Start, Ende, Dateiname, Videopfad, Dateiname};
    else
        fprintf(['No table found: ', Dateiname]);
    end
end

% Display the number of datasets found
fprintf(['Found ', modus, '-datasets: ', num2str(size(info, 1))]);
end
