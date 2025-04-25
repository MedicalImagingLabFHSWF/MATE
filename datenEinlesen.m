function info = datenEinlesen(modus)
% 1) Liest Datensätze ein, je nach modus aus anderem Ordner
% 2) Zurück werden infos über die gefunden Datensätze gegeben:
% {Druchlauf, Leistung, Start, Ende, Name, videopfad, tabellepfad}.

if strcmpi(modus, 'training')
    ordner = 'C:\Users\sarah\Desktop\MESS\training data';
elseif strcmpi(modus, 'testing')
    ordner = 'C:\Users\sarah\Desktop\MESS\testing data';
end
%Alle Datein einlesen
Dateien = dir(fullfile(ordner,'*.*'));
info = {};

fprintf('Dateien gesamt: ', num2str(numel(Dateien)));

 % Alle Daten im Ordner durchgehen
for i=1:numel(Dateien)
    %nächsten Datei, wenn Unterordner
    if Dateien(i).isdir
        continue;
    end

    % lese Dateiname und Dateiendung
    [~, Dateiname, Dateiende] = fileparts(Dateien(i).name); 
    
    % nächsten Datei, wenn Video
    if ~strcmpi(Dateiende,'.mp4')
        continue;
    end 

    % Name an den Unterstrichen aufteilen
    Name_teil = split(Dateiname,'_');

    % Datei überspringen, wenn es nicht passt
    if numel(Name_teil)~=4 
        fprintf(['Überspringe (kein 4 teiliger Name): ', Dateiname]);
        continue;
    end

    % Mit den Namenteilen werden die Variablen definiert
    Durchlauf   = str2double(Name_teil{1});
    Leistung  = Name_teil{2};
    Start = str2double(Name_teil{3});
    Ende   = str2double(Name_teil{4});
    
    % Zugehöriger Videoname heißt wie die Tabelle
    Videopfad  = fullfile(ordner,Dateiname);

    if strcmpi(Dateiende,'.xlsx')||strcmpi(Dateiende,'.csv')
        % Datei gefunden, zu der Liste an Datensätzen anhängen
        info(end+1,:)={Durchlauf,Leistung,Start,Ende,Dateiname,Videopfad,Dateiname};
    else
        fprintf(['Keine Tabelle gefunden: ', Dateiname]);
    end

end
% die Anzahl der Datensätze wird angezeigt
fprintf(['Gefundene ', modus, '-Datensätze: ', num2str(size(info,1))]);
end
