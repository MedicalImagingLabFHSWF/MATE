function vernichten(pattern)
d = dir(pattern);

for i = 1:numel(d)
    % Creates the full path
    path = fullfile(d(i).folder, d(i).name); 
    % Ignores . and .. (not visible but can appear)
    if strcmp(d(i).name, '.') || strcmp(d(i).name, '..')
        continue;
    end
    % 7 is the return value indicating that a folder was found by `exist`.
    % This checks if the path in the variable `path` exists.
    if d(i).isdir
        if exist(path, 'dir') == 7

            % Attempts to delete the folder recursively (works only for directories)
            try
                rmdir(path, 's');
            % If an error occurs, it is caught to prevent the script from crashing
            % `ME` contains error information
            catch ME
                fprintf('Error at "%s": %s\n', path, ME.message);
            end
        else
            fprintf('"%s" is not a valid directory.\n', path);
        end
    else 
        try 
            % If not a folder, then deletes the file (works only for files)
            delete(path);
        catch ME
            fprintf('Error at "%s": %s\n', path, ME.message);
        end
    end
end
end
