function netTrainieren (auto)
% Training with ResNet-18!
% Loads data
% Reads the temperature from the filenames
% Trains a ResNet-18

    clc;
    fprintf('Training network ...\n');

    % If 1 is passed, everything will always be redone without asking
    if auto == 1
        response = auto;
    else
        response = input('Start fresh (1) or continue (0)? ');
    end

    if isempty(response)
        response = 0;
    end

    % Start fresh, so delete checkpoints
    if response == 1
        if isfolder('myCheckpoints')
            delete(fullfile('myCheckpoints','*.mat')); 
        end
        fprintf('Checkpoints deleted. Starting fresh.\n');
    else
        fprintf('Continuing...\n');
    end

    % Load images for training
    imds_all = imageDatastore('MESS\training_data_pics',...
        'IncludeSubfolders', true, ...
        'FileExtensions', '.png', ...
        'LabelSource', 'none');

    total_count = numel(imds_all.Files);
    if total_count < 1
        error('No training data found!\n');
    end
    fprintf('Found images: %d\n', total_count);

    % Read temperature from filename
    [temp, valid_indices] = read_temp_data(imds_all);

    valid_count = sum(valid_indices);
    fprintf('Valid training data: %d\n', valid_count);

    % Keep only valid data
    imds_all.Files = imds_all.Files(valid_indices);
    temp = temp(valid_indices);

    % Split data 80/20 for quick validation at the end
    valid_count = numel(temp);
    rng('shuffle'); % Initialize random generator
    rand_indices = randperm(valid_count); % Create random index
    split_point = round(0.8 * valid_count); % Split point between training and validation data

    % Split training and validation data and shuffle them beforehand
    training_data = imds_all.Files(rand_indices(1:split_point));
    validation_data = imds_all.Files(rand_indices(split_point+1:end));
    % Do the same for temperatures
    training_temp = temp(rand_indices(1:split_point));
    validation_temp = temp(rand_indices(split_point+1:end));

    % Separate image data
    imds_training = imageDatastore(training_data, 'LabelSource', 'none');
    imds_validation = imageDatastore(validation_data, 'LabelSource', 'none');
    
    % Separate temperatures
    ds_training = arrayDatastore(training_temp);
    ds_validation = arrayDatastore(validation_temp);

    % Datastores must be combined for the training tool
    combined_training_ds = combine(imds_training, ds_training);
    combined_validation_ds = combine(imds_validation, ds_validation);

    % Transform datastore so that the training tool understands it
    final_training_ds = transform(combined_training_ds, @cell_format);
    final_validation_ds = transform(combined_validation_ds, @cell_format);

    % Load ResNet-18
    network = resnet18;
    layer_graph = layerGraph(network);

    % Remove the last classification layers (fc1000, prob, ClassificationLayer_predictions)
    layer_graph = removeLayers(layer_graph, {'fc1000', 'prob', 'ClassificationLayer_predictions'});

    % New layers:
    % A "fully connected layer" (regular layer) and
    % a "regression layer" (uses MSE as loss function) for the output
    new_layers = [fullyConnectedLayer(1, 'Name', 'fcReg', 'WeightLearnRateFactor', 10, 'BiasLearnRateFactor', 10), ...
                  regressionLayer('Name', 'regOut')];
    layer_graph = addLayers(layer_graph, new_layers);

    % Connect to the last existing layer, 
    % here connect to pooling layer "pool5"
    layer_graph = connectLayers(layer_graph, 'pool5', 'fcReg');

    % Create checkpoint folder if needed
    checkpoint_folder = 'myCheckpoints';
    if ~exist(checkpoint_folder, 'dir')
        mkdir(checkpoint_folder);
    end

    net_options = trainingOptions('sgdm',... % sgdm = stochastic gradient descent method for training
        'MiniBatchSize', 16,... % Smallest training set (for gradient, loss, and weight updates)
        'MaxEpochs', 5,... % Number of epochs
        'InitialLearnRate', 1e-4,... % Learning rate
        'Shuffle', 'every-epoch',... % Shuffle data every epoch
        'Verbose', true,... % Display progress in Command Window
        'VerboseFrequency', 200,... % Frequency of Command Window outputs
        'Plots', 'training-progress',... % Plots during training
        'CheckpointPath', checkpoint_folder,... % Where to save checkpoints
        'CheckpointFrequency', 1); % How often to save checkpoints

    % Check if a checkpoint exists
    checkpoint = find_latest_checkpoint(checkpoint_folder);
    if response == 1 
        checkpoint = '';
    end

    if ~isempty(checkpoint)
        fprintf(['Checkpoint found: ', checkpoint]);
        try
            % If checkpoint found, resume training
            [trainedNet, infoNet] = resumeTraining(checkpoint, net_options);
        catch ex
            fprintf(['Failed to resume training: ', ex.message]);
            fprintf('Restarting training.\n');
            % If resuming fails, start training from scratch
            [trainedNet, infoNet] = trainNetwork(final_training_ds, layer_graph, net_options);
        end
    else
        % If no checkpoint, start training from scratch
        fprintf('Starting training.\n');
        [trainedNet, infoNet] = trainNetwork(final_training_ds, layer_graph, net_options);
    end

    % After training, perform a quick validation
    predicted_temp = predict(trainedNet, final_validation_ds);
    MSE_validation = mean((predicted_temp - validation_temp).^2);
    RMSE_validation = sqrt(MSE_validation);
    fprintf('Validation RMSE: %.3f\n', RMSE_validation);

    % Save the network and important information
    save('trainedTemperatureModel.mat', 'trainedNet', 'infoNet', 'RMSE_validation');
    fprintf('Training finished.\n');
end

% Helper functions

function output = cell_format(data)
    % transform => {Image, numeric} => {Input, Response}
    output = {data{1}, data{2}};
end

function file = find_latest_checkpoint(checkpoint_folder)
    files = dir(fullfile(checkpoint_folder, 'checkpoint_epoch_*.mat'));
    if isempty(files)
        file = '';
        return;
    end
    % Find the latest date using max, only the index is important
    [~, latest_index] = max([files.datenum]);
    file = fullfile(checkpoint_folder, files(latest_index).name);
end

function [temp, valid_indices] = read_temp_data(imds)
    % Reads the temperature from filenames: xx.yy,
    % by searching for the last underscore and reading the rest as a number.
    files = imds.Files;
    n = numel(files);
    temp = nan(n, 1);
    valid_indices = false(n, 1);

    % Iterate through all files
    for i = 1:n
        [~, filename, ~] = fileparts(files{i});
        
        % If "_aug#" exists, remove it because it's at the end:
        filename = regexprep(filename, '_aug\d+$', '');

        % Last underscore indicates temperature
        us_index = strfind(filename, '_');
        if isempty(us_index)
            continue; 
        end
        last_us_index = us_index(end);

        % Convert to temperature
        temp_str = filename(last_us_index + 1:end);
        temp_temp = str2double(temp_str);

        % Record whether conversion was successful
        if ~isnan(temp_temp)
            temp(i) = temp_temp;
            valid_indices(i) = true;
        end
    end
end
