function Main(auto)
% Matlab files must be located in a folder called 'Mess' on the desktop

    clc;
    fprintf('Training started\n');
    % Important for subprograms
    mode = 'training';
    
    % Checks whether another script specifies 'auto', in which case everything runs automatically.
    % Or if everything is controlled manually.
    if auto == 1
        response = auto;
    else
        response = input('Start fresh (1) or continue (0)?\n');
    end
    
    % If there is no input, it will continue (Enter, Space)
    if isempty(response)
        response = 0;
    end
    
    if response == 1
        fprintf('Deleting everything...\n');
    
       % Function deletes local folders
       destroy(fullfile('Mess','testing_data_pics'));
       destroy(fullfile('Mess','training_data_pics'));
    
       % Deletes checkpoints, if present
       if isfolder('myCheckpoints')
           delete(fullfile('myCheckpoints','*.mat'));
       end
       % Deletes the trained model, if present
       if exist('trainedTemperatureModel.mat','file')
           delete('trainedTemperatureModel.mat');
       end
       fprintf('Everything deleted\n');
    
    else
        fprintf('Continuing\n');
    
    end
    
    % Executes the scripts
    if exist('videoNadelErzeugen.m','file')
        fprintf('Starting videoNadelErzeugen\n');
        videoNadelErzeugen(mode);
    else
        fprintf('Error, videoNadelErzeugen not found\n');
    end
    
    if exist('nadelAugmentieren.m','file')
        fprintf('Starting nadelAugmentieren\n');
        nadelAugmentieren;
    else
        fprintf('Error, nadelAugmentieren not found\n')
    end
    if exist('netTrainieren.m','file')
        fprintf('Starting netTrainieren\n');
        netTrainieren(auto)
    else
        fprintf('Error, netTrainieren not found\n');
    end
    
    fprintf('Main finished\n');
end
