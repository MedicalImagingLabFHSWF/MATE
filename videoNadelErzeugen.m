function videoNadelErzeugen(modus)
% 1) Liest Datensätze ein
% 2) Schneidet und Bearbeitet die Frames fuer das Resnet18 vor. 

clc;
fprintf('Schneide Frames zu...\n');

info = datenEinlesen(modus);
if isempty(info)

    fprintf('Fehler: Keine Datensätze\n');
    return;
end

for i = 1:size(info,1)

    % Dateiname
    name     = info{i,5};
    % Kompletter Pfad zur MP4 Datei
    mp4Pfad  = info{i,6};
    % Kompletter Pfad zur CSV Datei
    tabPfad  = info{i,7};
    % Startzeit
    anfSec = info{i,3};
    % Endzeit
    endSec   = info{i,4};

    % Ausgabe des aktuellen Datensatzes 
    fprintf('%s Datensatz #%d: %s \n',modus, i , name);

    % Falls die tabelle nicht existiert wird der Durchlauf übersprungen
    if ~isfile(tabPfad)
        fprintf('Fehler: Tabelle fehlt %s \n',tabPfad);
        continue;
    end

    % Auslesen der Tabelle
    tab = readtable(tabPfad);

    % Durch den Messaufbau ergeben sich immer 4 Spalten, damit kann ich 
    % überprüfen ob die richtige Datei eingelesen wurde
    if size(tab,2)<4
        fprintf('Zu wenige Spalten, überspringe \n');
        continue;
    end

    % Zeit umwandlen in sekunden. Falls CSV/Excel andere Werte hat (z.B.
    % Datum, statt Sec)

    % tsec speichert die Zeitwerte, ok ist ein rückgabewert der Angibt ob
    % ein Fehler vorliegt
    [tsec, ok] = umwandeln_zu_sek(tab{:,1});
    if ~ok
        fprintf('Fehler: Zeit nicht lesbar \n');
        continue;
    end

    % Abspeichern von Spalte 2 und 3 in Variable, ggf. convertierung in
    % zahlen
    A = toNum(tab{:,2});
    B = toNum(tab{:,3});

    % Summen der Spalten werden gebildet, die mit dem Höchsten Wert ist die
    % bessere Messung und wird weiter verwendet
    % omitnan ignoriert nicht auswertbare Werte

    if sum(A,'omitnan') >= sum(B,'omitnan')
        temp = A;
    else 
        temp = B;
    end

    if ~isfile(mp4Pfad)
        fprintf('Fehler: MP4 %s Fehlt \n',mp4Pfad);
        continue;
    end

    % Zeit des Videos extrahieren und den richtigen endpunkt bestimmen
    video = VideoReader(mp4Pfad);
    zeit = video.Duration;
    endzeit = zeit - endSec;

   % Startzeit definieren
   % überprüfe ob sie startzeit unter 0 sec sind, wenn ja wird nichts
   % geschnitten
   if anfSec < 0
       anfSec = 0;
   end

   % Überprüfen ob die anfganszeit größer ist als die Endzeit, wenn ja
   % Fehler ausgabe
   if endzeit <= anfSec
       fprinft('Fehler: Videozeit \n');
       continue;
   end

    % Festlegen der Framerate, hier wird nur jeder vierte Frame verwendet
    % reduzierung des Rechenaufwands
    rate = 4;
    framerate = video.FrameRate/rate;


    %berrechnung der eigentlichen video zeit
    neuezeit = endzeit - anfSec;
    % erzeugen von vektor mit Zeitpunkten an dene die Frames aus dem Video
    % extrahiert werden
    zvideo = 0 : 1/framerate : neuezeit;

    % Der schwellenwert in secunden wird hier festgelegt, wodurch man
    % erkennen kann ob ein sprung im zeitstempel vorliegt
    schwellenwert = 5;

    % erster Zeitstempel
    erst_t = tsec(1);

    % index 
    neustart = 1;

    % Schleife über tsec ( Zeitwerte )
    for ii = 1:numel(tsec)
        % Falls der  die Differenz zwischen startzeit und aktuell
        % ausgelsenen Zeitstempel, größer als der Schwellenwert liegt
        % (hier 5 sec) wird der index ii zurück gesetzt und die Schleife
        % beendet. Damit kann man Sprünge finden. Das wurde eingebaut, weil
        % bei der Messung mit dem Temperaturmessgerät alles eingestellt
        % wurde und später gestartet wurde. Damit wird der berreich
        % ignoriert.
        if tsec(ii)-erst_t > schwellenwert
            neustart = ii;
            break
        else
            % Andernfalls wird erst_t mit dem neuen Zeitwert übergeben
            erst_t = tsec(ii);
        end
    end

    % Zuschneiden des Neuen Startpunktes
    tsec = tsec(neustart:end);
    % Nomierung, neue Anfang fängt bei 0 an
    tsec = tsec - tsec(1);

    %unique entfernt doppelte zeitstempel, stable  behält die reihenfolge
    %bei, beinhaltet die eindeutigen zeitwerte und i_alle sind die
    %zugehörogen indizes
    [u,i_alle] = unique(tsec, 'stable');
    % durch die Indezierung erhält man die eindeutigen zeitstempel einen
    % zugehörigen Temparturwert in zuordnen
    zuordnen = temp(i_alle);

    % Interpolation der Temperaturwerte

    %lineare Interpolation falls nötig, zwischen Temperaturwerten zu jeden
    %Zeitpunkt von zvideo. u sind die bekannten Zeitpunkte nachzuscheniden,
    %zvideo ist der Vektor der Zeitpunkte, an denen die Video Frames
    %extrahiert werden.
    vall = interp1(u,zuordnen,zvideo,'linear','extrap');
    %index für spätere Schleifen
    anzFrames = numel(zvideo);


    % Fallunterscheidung ob das Script fürs training oder fürs testen
    % aufgerufen wird. Damit werden die Frames jeweils woanders
    % abgespeichert
    if strcmpi(modus,'training')
        tempFolder = 'MESS\training_data_pics';
    elseif strcmpi(modus,'testing')
        tempFolder = 'Mess\testing_data_pics';
    end

    % z.B. "training-NadelData_1_10W_12_5" baut den namen des Unterordners 
    ordner = fullfile(tempFolder,[modus,'-NadelData_',name]);

    % Schaut ob der ordner schon existiert und erstellt ihn falls nicht
    % vorhanden
    if ~exist(ordner,'dir')
        mkdir(ordner);

    end

    % Sucht in ordner nach png die "nadelFrame" heißen 
    existierendePNG = dir(fullfile(ordner,'nadelFrame*.png'));
    % Anzahl der gefunden PNGS
    fstart = numel(existierendePNG);
    
    % Schauen ob die anzahl der frames größer oder gleich der gefunden PNGs
    % ist. Falls ja dann springt er weiter zur nächsten codeabschnitt 
    if fstart >= anzFrames
        fprintf('fertig');
        continue;
    end

    % Vorspulen des Videos, um bearbeite Frames zu überspringen
    % Anfangszeit 
    video.CurrentTime = anfSec;
    %index
    springe = 0;
    % Solange Frames vorhanden sind wird die Schleife weiter vortgeführt 
    while hasFrame(video) && springe < fstart
        for s = 1:rate-1
            readFrame(video);
        end
        %index erhöhen
        springe = springe + 1;
    end

    %berrechnen der gesammten Frames 
    bearbeiteFrames = floor((endzeit-anfSec)*video.FrameRate)/rate;
    % index
    f = fstart;

    % Auselen von Frames
    % Schleife, läuft so lange bis es keine Frames mehr gibt oder endzeit
    % erreicht wurde
    while hasFrame(video) && video.CurrentTime <=  endzeit
        % liest und verwirrt Frames 
        for s = 1:rate-1
            readFrame(video);
        end
        %Frame auslesen
        frame = readFrame(video);
        %index erhöhen
        f = f + 1;
        % zuordnen des Temperatur wertes
        iii = min(f, anzFrames);
        % Entnahme des interpolierten Wertes aus Vall
        interpoliert_temp = vall(iii);
        
        % Falls man nur den berreich 0-90 °C benötigt, schnellere
        % Rechenzeit

        % if interpoliert_temp > 90
        %     fprintf('Temperatur über 90°C: restliche Frames ignoriert, nächstes Video.');
        %     break;
        % end

       % Helligkeitsschwelle zum wegschneiden der schwarzen Ränder
       helligkeit = 20;
       % Entferne schwarze Ränder vom Bild
       frameohnerand = entferne_rand(frame, helligkeit);


       % Danach noch zuschneiden (in Prozent)
       oben    = 0.00;
       unten   = 0.20;
       links   = 0.00;
       rechts  = 0.00;
       %zuschneiden
       zugeschnitten = zuschneiden(frameohnerand, oben, unten, links, rechts);

       % Bild format ändern damit die KI es lesen kann
       fertiges_Bild = imresize(zugeschnitten, [224 224]);

       % Dateiname zusammenstellen und Bild speichern
       Dateiname = sprintf('nadelFrame%05d_%.2f.png', f, interpoliert_temp);
       imwrite(fertiges_Bild, fullfile(ordner, Dateiname));
        
       % Fortschritt ab und zu ausgeben
       if mod(f,30)==0 || f==bearbeiteFrames
                prozent = (f / bearbeiteFrames)*100;
                fprintf('Fortschritt: %d/%d (%.1f%%)\n', f, bearbeiteFrames, prozent);
        end
    end
end

fprintf(['Fertig: ', modus,'-videoNadelErzeugen']);
end

% Hilfsfunktionen

% Wandelt gängige Zeitformate in Sekunden um
function [sek, ok] = umwandeln_zu_sek(Zeit)
    sek=[]; ok=false;

    % Schon eine Zahl, dann ist schon Zeit in Sekunden
    if isnumeric(Zeit)
        sek=Zeit; 
        ok=true; 
        return;
    end

    % Ist datetime typ, dann zu relativer Zeit machen
    % danach zu Sekunden machen
    if isdatetime(Zeit)
        sek=seconds(Zeit - Zeit(1));
        ok=true; 
        return;
    end

    % Versuchen Eingangswert zu einem Datum umzuwandeln,
    % Probiere ein paar typische Datumformate
    fm = ["dd.MM.yyyy HH:mm:ss.SSS","dd.MM.yyyy HH:mm:ss"];
    for k=1:numel(fm)
        try
            % Versuche umzuwandeln und zum nächsten wenn es nicht geht
            d = datetime(Zeit,'InputFormat',fm(k));
            % Falls es geklappt hat zu relativer Zeit machen und in sek
            % umwandeln
            sek = seconds(d - d(1));
            ok=true; 
            return;
        catch
        end
    end
end
 
% Eingang zu Zahl machen wenn noch nicht Zahl
function v = toNum(x)
    % Schon Zahl, Eingang = Ausgang
    if isnumeric(x)
        v = x;
    else
        % Zu Zahl konvertieren und zurückgeben
        v = str2double(string(x));
    end
end

% Entfernt schwarzen Rand vom Bild.
% Ignoriert kleine Symbole durch Schwelle
function frameohnerand = entferne_rand(inBild, schwelle)
    % Bild zu Grau machen fall noch nicht ist
    if ndims(inBild) == 3
        g = rgb2gray(inBild);
    else
        g = inBild;
    end


    reihe_mittel = mean(g,2);
    spalte_mittel = mean(g,1);

    % Suchen nach dem Rand
    % Wenn Mittel einer Reihe/Spalte Schwelle erreicht
    oben   = find(reihe_mittel >= schwelle, 1, 'first');
    unten  = find(reihe_mittel >= schwelle, 1, 'last');
    links  = find(spalte_mittel >= schwelle, 1, 'first');
    rechts = find(spalte_mittel >= schwelle, 1, 'last');

    % Ein Rand wurde nicht gefunden
    % Bild wieder zurück wie es war
    if isempty(oben) || isempty(unten) || isempty(links) || isempty(rechts)
        frameohnerand = inBild;
        return;
    end

    % Bild zuschneiden an den gefundenen Rändern
    frameohnerand = inBild(oben:unten, links:rechts, :);
end

function zugeschnitten = zuschneiden(inBild, oben, unten, links, rechts)
    [H,B,~] = size(inBild);

    % Prozente zu Pixel umrechnen
    obenPx    = round(H * oben);
    untenPx = round(H * unten);
    linksPx   = round(B * links);
    rechtsPx  = round(B * rechts);

    % Neue Ränder aus Pixeln berechnen
    Reihe_Start = 1 + obenPx;
    Reihe_Ende   = H - untenPx;
    Spalte_Start = 1 + linksPx;
    Spalte_Ende   = B - rechtsPx;
    
    % Falls komisch zugeschnitten werden soll, ursprüngliches Bild zurück
    if Reihe_Start > Reihe_Ende || Spalte_Start > Spalte_Ende
        fprintf('Ungültige Parameter! Original zurückgegeben.');
        zugeschnitten = inBild;
        return;
    end
    
    % Bild zuschneiden
    zugeschnitten = inBild(Reihe_Start:Reihe_Ende, Spalte_Start:Spalte_Ende, :);
end