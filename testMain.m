function testMain (auto)
% Hauptprogramm für den Test nach dem Trainieren
% Neue Daten einladen und dann mit vorhersage vergleichen

clc;
fprintf('Test gestartet.');
modus ='testing';

% Auch hier kann mit auto = 1, alle eingeben übersprungen werden
% Dann wird alles gelöscht und neu gemacht, sonst kann man wählen.
if auto == 1
    choice = auto;
else
    choice = input('Alles neu (1) oder fortsetzen (0)? ');
end

if isempty(choice)
    choice=0;
end

% Wenn choice = 1 werden alle Testdaten gelöscht
if choice==1
    fprintf('Lösche alte Testdaten...');
    vernichten(fullfile('MESS','testing_data_pics'));
else
    fprintf('Test fortsetzen...');
end

% Testvideo zu Bildern machen und Temperaturen dazu
videoNadelErzeugen(modus)

% Neue Daten mit dem trainierten Netzwerk ausprobieren
testVorhersage;

fprintf('Test beendet.');
end