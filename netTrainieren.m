function netTrainieren (auto)
% Training mit ResNet-18!
% Läd Daten
% Liest aus den Dateinamen die Temperatur aus
% Trainiert ein ResNet-18 

    clc;
    fprintf('Netzwerk trainieren ...\n');

    % Wenn man 1 übergibt wird immer alles neu gemacht ohne fragen
    if auto == 1
    antwort = auto;
    else
        antwort = input('Alles neu (1) oder fortsetzen (0)? ');
    end

    if isempty(antwort)
        antwort=0;
    end

    % Alles neu, also Checkpoints löschen
    if antwort==1
        if isfolder('myCheckpoints')
            delete(fullfile('myCheckpoints','*.mat')); 
        end
        fprintf('Checkpoints gelöscht. Training neu.\n');
    else
        fprintf('Weitermachen...\n');
    end

    % Bilder zum Training laden
    imds_alle = imageDatastore('MESS\training_data_pics',...
        'IncludeSubfolders',true,...
        'FileExtensions','.png',...
        'LabelSource','none');

    anzGes = numel(imds_alle.Files);
    if anzGes < 1
        error('Keine Trainingsdaten gefunden!\n');
    end
    fprintf('Gefundene Bilder: %d\n', anzGes);

    % Temperatur aus Dateiname lesen
    [temp, ok_index] = temp_daten_lesen(imds_alle);

    ok_sum = sum(ok_index);
    fprintf('Valide Trainingsdaten: %d\n', ok_sum);

    % nur gültige beibehalten
    imds_alle.Files = imds_alle.Files(ok_index);
    temp      = temp(ok_index);

    % Daten aufteilen 80/20 für schnellen check am Ende
    ok_sum = numel(temp);
    rng('shuffle'); % Zufallgenerator initalizieren
    rand_index = randperm(ok_sum); % zufälligen index erstellen
    trennpunkt = round(0.8 * ok_sum); % Trennpunkt zwischen training und validierungsdaten

    % Trainings daten und validierungs daten trennen und vorher alles mischen
    training_daten = imds_alle.Files(rand_index(1:trennpunkt));
    validierung_daten = imds_alle.Files(rand_index(trennpunkt+1:end));
    % Das selbe mit den temperaturen
    training_temp = temp(rand_index(1:trennpunkt));
    validierung_temp = temp(rand_index(trennpunkt+1:end));

    % Trennen der Bilddaten
    imds_training = imageDatastore(training_daten,'LabelSource','none');
    imds_validierung = imageDatastore(validierung_daten, 'LabelSource','none');
    
    % Trennen der Temperaturen
    ds_training = arrayDatastore(training_temp);
    ds_validierung = arrayDatastore(validierung_temp);

    % Für das Trainingtool müssen datastores verbunden sein
    neu_training_ds = combine(imds_training, ds_training);
    neu_validierung_ds = combine(imds_validierung, ds_validierung);

    % Datastore transformieren damit Trainingtool es versteht
    final_training_ds = transform(neu_training_ds, @cell_format);
    final_validierung_ds = transform(neu_validierung_ds, @cell_format);

    % ResNet-18 laden
    netzwerk = resnet18;
    layer_graph  = layerGraph(netzwerk);

    % Letzte Klassifikations-Layer entfernen (fc1000, prob, ClassificationLayer_predictions)
    layer_graph  = removeLayers(layer_graph, {'fc1000','prob','ClassificationLayer_predictions'});

    % Neue Layer:
    % Ein "fully connected Layer" (ganz gewöhnlicher Layer) und 
    % ein "regression Layer" (hat MSE als loss function) für den output
    neue_layer = [fullyConnectedLayer(1,'Name','fcReg','WeightLearnRateFactor',10,'BiasLearnRateFactor',10), ...
            regressionLayer('Name','regOut')];
    layer_graph = addLayers(layer_graph,neue_layer);

    % An den letzten bisheriegen Layer anschließen, 
    % hier pooling layer "pool5" anschließen
    layer_graph = connectLayers(layer_graph,'pool5','fcReg');

    % Checkpoint ordner bei bedarf erzeugen
    checkpoint_ordner = 'myCheckpoints';
    if ~exist(checkpoint_ordner,'dir')
        mkdir(checkpoint_ordner);
    end

    net_optionen = trainingOptions('sgdm',... % sgdm = statisische Methode fürs training 
        'MiniBatchSize',16,... % Kleistes Trainingsset (für Gradient und loss und Gewichte aktualisieren)
        'MaxEpochs',5,... % Anzahl epochen
        'InitialLearnRate',1e-4,... % Lernrate
        'Shuffle','every-epoch',... % Daten jede Epoche mischen
        'Verbose',true,... % Gibt Fortschritt in Command Window aus
        'VerboseFrequency',200,... % häufigkeit für Conmmand window outputs
        'Plots','training-progress',... % Plots während training
        'CheckpointPath',checkpoint_ordner,... % Wo checkpoints speichern
        'CheckpointFrequency',1); % Wie oft checkpoints speichern

    % Gucken ob checkpoint vorhanden
    checkpoint = finde_neusten_checkpoint(checkpoint_ordner);
    if antwort==1 
        checkpoint='';
    end

    if ~isempty(checkpoint)
        fprintf(['Checkpoint gefunden: ', checkpoint]);
        try
            % Wenn Checkpoint gefunden training fortsetzen
            [trainedNet, infoNet] = resumeTraining(checkpoint, net_optionen);
        catch ex
            fprintf(['Training fortsetzen fehlgeschlagen: ', ex.message]);
            fprintf('Training neustarten.\n');
            % Wenn fortsetzen nicht funktioniert neu trainieren
            [trainedNet, infoNet] = trainNetwork(final_training_ds, layer_graph, net_optionen);
        end
    else
        % Wenn kein Checkpoint, training ohne checkpoint starten
        fprintf('Training starten.\n');
        [trainedNet, infoNet] = trainNetwork(final_training_ds, layer_graph, net_optionen);
    end

    % Wenn training fertig, kurze Validierung
    predict_temp = predict(trainedNet, final_validierung_ds);
    MSE_validierung  = mean((predict_temp - validierung_temp).^2);
    RMSE_validierung = sqrt(MSE_validierung);
    fprintf('RMSE von Validierung: %.3f\n', RMSE_validierung);

    % Netzwerk und wichtige Informationen speichern
    save('trainedTemperatureModel.mat','trainedNet','infoNet','RMSE_validierung');
    fprintf('Training beendet.\n');
end

% Hilfsfunktionen

function output = cell_format(daten)
    % transform => {Bild, numeric} => {Input, Response}
    output = {daten{1}, daten{2}};
end

function datei = finde_neusten_checkpoint(checkpoint_ordner)
    Dateien=dir(fullfile(checkpoint_ordner,'checkpoint_epoch_*.mat'));
    if isempty(Dateien)
        datei='';
        return;
    end
    % Mit max das letzte Datum finden, Wert egal nur index ist wichtig
    [~,index_neuster]=max([Dateien.datenum]);
    datei=fullfile(checkpoint_ordner,Dateien(index_neuster).name);
end

function [temp, ok_index] = temp_daten_lesen(imds)
    % Liest aus Dateinamen die Temperatur: xx.yy, 
    % indem wir den letzten Unterstrich suchen und den Rest als Zahl lesen.
    Dateien = imds.Files;
    n = numel(Dateien);
    temp = nan(n,1);
    ok_index = false(n,1);

    % Einmal durch alle Dateien
    for i=1:n
        [~, Dateiname, ~] = fileparts(Dateien{i});
        
        % Falls "_aug#" vorhanden, weg damit weil am Ende:
        Dateiname = regexprep(Dateiname,'_aug\d+$','');

        % Letzter Unterstrich ist temperatur
        index_us = strfind(Dateiname, '_');
        if isempty(index_us)
            continue; 
        end
        index_letzter_us = index_us(end);

        % Zu temperatur umwandeln
        temp_str = Dateiname(index_letzter_us+1:end);
        temp_temp= str2double(temp_str);

        % Merken ob umwandeln ok war
        if ~isnan(temp_temp)
            temp(i) = temp_temp;
            ok_index(i) = true;
        end
    end
end
