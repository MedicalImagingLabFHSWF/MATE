function testVorhersage
% Validation with an unknown dataset.
% Reads data and compares measurement with prediction
% Generates a plot and saves the results
clc;
fprintf('Starting prediction ...\n');

% Load trained model
model = 'trainedTemperatureModel.mat';
if ~isfile(model)
    fprintf([model, ' not found!\n']);
    return;
end

% Load test data
folder = 'MESS\testing_data_pics';
imds = imageDatastore(folder, 'IncludeSubfolders', true, ...
    'FileExtensions', '.png', 'LabelSource', 'none');

% Read temperature from filename
[temp, ok_index] = read_temp_data(imds);

ok_sum = sum(ok_index);
fprintf('Number of test data: %d\n', ok_sum);

% Keep only valid data
imds.Files = imds.Files(ok_index);
temp = temp(ok_index);

count = numel(imds.Files);

% Load pretrained network and make predictions
load(model, 'trainedNet');
predict_temp = predict(trainedNet, imds);

% Calculate MSE and RMSE
MSE = mean((predict_temp - temp).^2);
RMSE = sqrt(MSE);
fprintf('Test run RMSE: %.3f\n', RMSE);

% Prepare plot
figure('Name', 'Test Results', 'Position', [100 100 1200 500]);

% Line plot of predictions and actual data
subplot(1, 2, 1);
hold on;
plot(1:count, temp, '-b', 'LineWidth', 1.2);
plot(1:count, predict_temp, '-r', 'LineWidth', 1.2);
legend({'Measured', 'Prediction'}, 'Location', 'best');
xlabel('Index');
ylabel('Temperature (°C)');
grid on;

% Scatter plot between predictions and actual data
subplot(1, 2, 2);
scatter(temp, predict_temp, 10, 'filled');
xlabel('Measured Temperature (°C)');
ylabel('Prediction (°C)');
grid on;

% Create and save a table of the results
testIndex = (1:count)';
T = table(testIndex, temp, predict_temp, ...
    'VariableNames', {'Index', 'ActualTemp', 'PredictedTemp'});
writetable(T, 'TestResults.xlsx', 'Sheet', 'Results');

fprintf('Results saved in "TestResults.xlsx".\n');
end

function [temp, ok_index] = read_temp_data(imds)
    % Reads temperature from filenames: xx.yy, 
    % by searching for the last underscore and reading the rest as a number.
    files = imds.Files;
    n = numel(files);
    temp = nan(n, 1);
    ok_index = false(n, 1);

    % Iterate through all files
    for i = 1:n
        [~, filename, ~] = fileparts(files{i});
        
        % Remove "_aug#" if present, as it's at the end:
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
            ok_index(i) = true;
        end
    end
end
