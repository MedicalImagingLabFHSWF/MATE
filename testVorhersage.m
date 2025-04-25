function testVorhersage
% Validierung mit unbekanntem Datensatz.
% Ließt daten ein und vergleicht Messung mit Vorhersage
% Erzeugt einen plot und speichert die Ergebnisse
clc;
fprintf('Vorhersage starten ...\n');

% Trainiertes Modell laden
model='trainedTemperatureModel.mat';
if ~isfile(model)
    fprintf([model,' nicht gefunden!\n']);
    return;
end

% Testdaten laden
ordner='MESS\testing_data_pics';
imds = imageDatastore(ordner,'IncludeSubfolders',true, ...
    'FileExtensions', '.png','LabelSource','none');

 % Temperatur aus Dateiname lesen
[temp, ok_index] = temp_daten_lesen(imds);

ok_sum = sum(ok_index);
fprintf('Anzahl Testdaten: %d\n', ok_sum);

% nur gültige beibehalten
imds.Files = imds.Files(ok_index);
temp = temp(ok_index);

anz=numel(imds.Files);

% Vortrainiertes Netzwerk laden vorhersage machen
load(model,'trainedNet');
predict_temp = predict(trainedNet, imds);

% MSE und RSME berechnen 
MSE = mean((predict_temp - temp).^2);
RMSE = sqrt(MSE);
fprintf('Testlauf RMSE: %.3f\n', RMSE);

% Plot vorbereiten
figure('Name','Testergebnisse','Position',[100 100 1200 500]);

% Liniendiagramm von Vorhersage und echten Daten
subplot(1,2,1);
hold on;
plot(1:anz, temp, '-b','LineWidth',1.2);
plot(1:anz, predict_temp, '-r','LineWidth',1.2);
legend({'Gemessen','Vorhersage'}, 'Location','best');
xlabel('Index');
ylabel('Temperatur (°C)');
grid on;

% Streudiagramm zwischen Vorhersage und echten Daten
subplot(1,2,2);
scatter(temp, predict_temp, 10, 'filled');
xlabel('Gemessene Temperatur (°C)');
ylabel('Vorhersage (°C)');
grid on;

% Tabelle vom Ergebniss erstellen und speichern
testIndex = (1:anz)';
T = table(testIndex, temp, predict_temp, ...
    'VariableNames',{'Index','WahreTemp','VorhersageTemp'});
writetable(T,'TestResults.xlsx','Sheet','Ergebnisse');

fprintf('Ergebnisse in "TestResults.xlsx" gespeichert.\n');
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
