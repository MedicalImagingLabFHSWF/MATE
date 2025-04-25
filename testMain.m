function testMain(auto)
% Main program for testing after training
% Load new data and then compare with predictions

clc;
fprintf('Test started.');
mode = 'testing';

% Here too, if auto = 1, all prompts are skipped
% Then everything will be deleted and redone, otherwise you can choose.
if auto == 1
    choice = auto;
else
    choice = input('Start fresh (1) or continue (0)? ');
end

if isempty(choice)
    choice = 0;
end

% If choice = 1, all test data will be deleted
if choice == 1
    fprintf('Deleting old test data...');
    destroy(fullfile('MESS', 'testing_data_pics'));
else
    fprintf('Continuing test...');
end

% Convert test video into images and associate temperatures
videoNadelErzeugen(mode)

% Try new data with the trained network
testPrediction;

fprintf('Test ended.');
end
