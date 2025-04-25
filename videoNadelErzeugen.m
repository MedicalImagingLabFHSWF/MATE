function videoNadelErzeugen(mode)
% 1) Reads datasets
% 2) Cuts and preprocesses frames for ResNet18.

clc;
fprintf('Cutting frames...\n');

info = datenEinlesen(mode);
if isempty(info)
    fprintf('Error: No datasets found\n');
    return;
end

for i = 1:size(info, 1)

    % File name
    name = info{i, 5};
    % Full path to the MP4 file
    mp4Path = info{i, 6};
    % Full path to the CSV file
    tablePath = info{i, 7};
    % Start time
    startSec = info{i, 3};
    % End time
    endSec = info{i, 4};

    % Output the current dataset
    fprintf('%s Dataset #%d: %s \n', mode, i, name);

    % Skip this iteration if the table does not exist
    if ~isfile(tablePath)
        fprintf('Error: Table missing %s \n', tablePath);
        continue;
    end

    % Read the table
    tab = readtable(tablePath);

    % Ensure the table has 4 columns due to the measurement setup
    % This checks if the correct file was read
    if size(tab, 2) < 4
        fprintf('Too few columns, skipping \n');
        continue;
    end

    % Convert time to seconds. If the CSV/Excel has other values (e.g., date instead of seconds)
    % tsec stores time values, ok is a return value indicating whether an error occurred
    [tsec, ok] = convert_to_seconds(tab{:, 1});
    if ~ok
        fprintf('Error: Time not readable \n');
        continue;
    end

    % Save columns 2 and 3 in variables, with possible conversion to numbers
    A = toNum(tab{:, 2});
    B = toNum(tab{:, 3});

    % Sum the columns, the one with the highest value is the better measurement and is used
    % omitnan ignores non-evaluable values
    if sum(A, 'omitnan') >= sum(B, 'omitnan')
        temp = A;
    else
        temp = B;
    end

    if ~isfile(mp4Path)
        fprintf('Error: MP4 %s Missing \n', mp4Path);
        continue;
    end

    % Extract video duration and determine the correct endpoint
    video = VideoReader(mp4Path);
    duration = video.Duration;
    endtime = duration - endSec;

    % Define start time
    % Check if the start time is less than 0 seconds; if yes, no cutting is done
    if startSec < 0
        startSec = 0;
    end

    % Check if the start time is greater than the end time; if yes, output an error
    if endtime <= startSec
        fprintf('Error: Video time \n');
        continue;
    end

    % Specify frame rate; only every fourth frame is used
    % Reduces computational effort
    rate = 4;
    framerate = video.FrameRate / rate;

    % Calculate actual video time
    newtime = endtime - startSec;
    % Generate a vector with times at which frames are extracted from the video
    zvideo = 0 : 1 / framerate : newtime;

    % Set threshold in seconds to detect jumps in the timestamp
    threshold = 5;

    % First timestamp
    first_t = tsec(1);

    % Index
    restart = 1;

    % Loop over tsec (time values)
    for ii = 1:numel(tsec)
        % If the difference between start time and the current timestamp
        % exceeds the threshold (here 5 seconds), reset the index ii and exit the loop.
        % This helps detect skips. This was added because during measurement,
        % the temperature device was set up and started later. These sections are ignored.
        if tsec(ii) - first_t > threshold
            restart = ii;
            break;
        else
            % Otherwise, update first_t with the new time value
            first_t = tsec(ii);
        end
    end

    % Cut the new start point
    tsec = tsec(restart:end);
    % Normalize, new start begins at 0
    tsec = tsec - tsec(1);

    % Remove duplicate timestamps; stable retains order
    % u contains unique time values, and i_all contains the corresponding indices
    [u, i_all] = unique(tsec, 'stable');
    % Using the indices, assign a unique temperature value to each timestamp
    assign = temp(i_all);

    % Interpolate temperature values
    % Perform linear interpolation, if needed, between temperature values for each
    % timestamp in zvideo. u are the known timestamps, zvideo is the vector of timestamps
    % where video frames are extracted.
    vall = interp1(u, assign, zvideo, 'linear', 'extrap');
    % Index for later loops
    totalFrames = numel(zvideo);

    % Check whether the script is called for training or testing.
    % Frames are saved in different locations accordingly
    if strcmpi(mode, 'training')
        tempFolder = 'MESS\training_data_pics';
    elseif strcmpi(mode, 'testing')
        tempFolder = 'Mess\testing_data_pics';
    end

    % For example, "training-NadelData_1_10W_12_5" constructs the subfolder name
    folder = fullfile(tempFolder, [mode, '-NadelData_', name]);

    % Check if the folder already exists; if not, create it
    if ~exist(folder, 'dir')
        mkdir(folder);
    end

    % Search in the folder for PNG files named "nadelFrame"
    existingPNG = dir(fullfile(folder, 'nadelFrame*.png'));
    % Number of found PNGs
    startFrames = numel(existingPNG);

    % Check if the number of frames is greater than or equal to the found PNGs
    % If yes, skip to the next code section
    if startFrames >= totalFrames
        fprintf('Done');
        continue;
    end

    % Skip ahead in the video to skip processed frames
    % Start time
    video.CurrentTime = startSec;
    % Index
    skip = 0;
    % Continue the loop as long as there are frames
    while hasFrame(video) && skip < startFrames
        for s = 1:rate-1
            readFrame(video);
        end
        % Increment index
        skip = skip + 1;
    end

    % Calculate total frames
    processedFrames = floor((endtime - startSec) * video.FrameRate) / rate;
    % Index
    f = startFrames;

    % Extract frames
    % Loop continues until no more frames are available or end time is reached
    while hasFrame(video) && video.CurrentTime <= endtime
        % Read and skip frames
        for s = 1:rate-1
            readFrame(video);
        end
        % Read frame
        frame = readFrame(video);
        % Increment index
        f = f + 1;
        % Assign temperature value
        iii = min(f, totalFrames);
        % Extract interpolated value from vall
        interpolated_temp = vall(iii);

        % If only the range 0-90°C is needed, faster computation
        % Uncomment below for that:
        % if interpolated_temp > 90
        %     fprintf('Temperature above 90°C: remaining frames ignored, next video.');
        %     break;
        % end

        % Brightness threshold to remove black borders
        brightness = 20;
        % Remove black borders from the image
        frameWithoutBorders = remove_borders(frame, brightness);

        % Further crop the image (in percentages)
        top = 0.00;
        bottom = 0.20;
        left = 0.00;
        right = 0.00;
        % Apply cropping
        cropped = crop_image(frameWithoutBorders, top, bottom, left, right);

        % Change image format so the AI can read it
        finalImage = imresize(cropped, [224 224]);

        % Construct filename and save image
        filename = sprintf('nadelFrame%05d_%.2f.png', f, interpolated_temp);
        imwrite(finalImage, fullfile(folder, filename));

        % Occasionally output progress
        if mod(f, 30) == 0 || f == processedFrames
            percent = (f / processedFrames) * 100;
            fprintf('Progress: %d/%d (%.1f%%)\n', f, processedFrames, percent);
        end
    end
end

fprintf(['Done: ', mode, '-videoNadelErzeugen']);
end
