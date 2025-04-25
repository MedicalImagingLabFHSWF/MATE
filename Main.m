function Main(auto)
% Matlab Datein müssen in einem Ordner Namens 'Mess' auf dem Desktop liegen


    clc;
    fprintf('Training gestartet\n');
    % für Unterprogramme wichtig
    modus ='training';
    
    % Schaut ob ein anderes skript mit auto vorgibt, damit läuft alles durch.
    % oder ob man analoge alles steuert.
    if auto == 1
        antwort = auto;
    else
        antwort = input('Alles neu (1) oder fortsetzen (0)?\n');
    end
    
    % Bei nicht eingabe wird Fortgestzt (Enter,Leertaste)
    if isempty(antwort)
        antwort = 0;
    end
    
    if antwort == 1
        fprintf(' Lösche alles...\n');
    
       % Function löscht lokal die Ordner
       vernichten(fullfile('Mess','testing_data_pics'));
       vernichten(fullfile('Mess','training_data_pics'));
    
       % Löscht Checkpoints, falls vorhanden
       if isfolder('myChekpoints')
           delete(fullfilfe('myChekpoints','*.mat'));
       end
       % Löscht das Trainierte Model, falls vorhanden
       if exist('trainedTemperatureModel.mat','file')
           delte('trainedTemperatureModel.mat');
    
       end
       fprintf('Alles gelöscht\n');
    
    else
        fprintf('Fortsetzen\n');
    
    end
    
    % Ausführen der Skripte 
    if exist('videoNadelErzeugen.m','file')
        fprintf('Starte VideoNadelErzeugen\n');
        videoNadelErzeugen(modus);
    else
        fprintf('Fehler, VideoNadelErzeugen nicht gefunden\n');
    end
    
    
    if exist('nadelAugmentieren.m','file')
        fprintf('Starte nadelAugemntieren\n');
        nadelAugmentieren;
    else
        fprintf('Fehler, nadelAugmentieren nicht gefunden\n')
    end
    if exist('netTrainieren.m','file')
        fprintf('Starte netTrainieren\n');
        netTrainieren(auto)
    else
        fprintf('Fehler, netTrainieren nicht gefunden\n');
    end
    
    fprintf('Main beendet\n');
end
    

