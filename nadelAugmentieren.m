function nadelAugmentieren
% Erweitert Trainingsdaten durch Augmentieren

clc;
fprintf('Daten augmentieren ...\n');

%  Alle Bilder für training suchen und Datastore erzeugen
ordner = fullfile('MESS\training_data_pics');
imds = imageDatastore(ordner, 'IncludeSubfolders',true,...
    'FileExtensions','.png', 'LabelSource','none');

% Anzahl Trainingsdaten ohne Augmentierung
anzahl = numel(imds.Files);
fprintf(['Gefundene Bilder im training Ordner: ', num2str(anzahl),'\n']);
if anzahl<1
    fprintf('Keine Bilder! Abbruch.\n');
    return;
end

% Ordner für neue Bilder
aug_ordner = fullfile('MESS\training_data_pics','NadelAugData');
if ~exist(aug_ordner,'dir')
    mkdir(aug_ordner);
end

anz_pro_aug = 3; % 3 Bilder pro original hinzu
i_original = 0;
i_aug  = 0;

reset(imds); 
% Durch alle Bilder gehen
while hasdata(imds)
    % Bild und Infos zum Bild aus Datastore laden
    [original, infos] = read(imds);
    [~, Dateiname, Dateiendung] = fileparts(infos.Filename);

    % Prüfen, ob für dieses Bild schon augmentierte Versionen existieren
    fertig_aug = dir(fullfile(aug_ordner, [Dateiname,'_aug*', Dateiendung]));
    anz_fertig_aug  = numel(fertig_aug);
    if anz_fertig_aug >= anz_pro_aug
        i_original = i_original + 1;
        continue;
    end

    % Falls noch welche für das Bild fehlen erzeuge mehr
    for a = (anz_fertig_aug+1) : anz_pro_aug
        aug_Bild = zufall_aug(original);
        aug_Name= sprintf('%s_aug%d%s', Dateiname, a, Dateiendung);
        % => Bsp: "nadelFrame00001_35.20_aug1.png"
        imwrite(aug_Bild, fullfile(aug_ordner, aug_Name));
        i_aug = i_aug+1;
    end

    i_original = i_original+1;
    % Fortschritt ausrechnen und anzeigen
    prozent=(i_original/anzahl)*100;
    fprintf('Original: %d/%d (%.1f%%)\n',i_original, anzahl, prozent);
end

fprintf('Fertig mit Augmentieren!\n');
fprintf(['Erzeugte Aug-Bilder: ', num2str(i_aug),'\n']);
end


function aug_Bild = zufall_aug(inBild)
% Erzeugt ein einziges Augmentiertes Bild:

% 1) Zufällige Rotation +/-15°
winkel=randi([-15,15],1);
aug_Bild=imrotate(inBild,winkel,'bicubic','crop');

% 2) Zufällig Spiegeln um verschiedene Achsen
if rand<0.5
    aug_Bild=flip(aug_Bild,2);
end
if rand<0.3
    aug_Bild=flip(aug_Bild,1);
end

% 3) Zufällig Skalieren zwischen 0.9..1.1
skala=0.9+0.2*rand;
aug_Bild=imresize(aug_Bild,skala);
[H,B,~]=size(aug_Bild);

if H<224 || B<224 % Bild zu klein, Seiten auffüllen
    padH=224-H; padB=224-B;
    t= floor(padH/2);
    l= floor(padB/2);
    aug_Bild=padarray(aug_Bild,[t l],'replicate','pre'); 
    aug_Bild=padarray(aug_Bild,[padH-t, padB-l],'replicate','post'); 
else % Bild zu groß, Seiten zuschneiden
    erste_zeile=floor((H-224)/2)+1;
    erste_spalte=floor((B-224)/2)+1;
    aug_Bild=imcrop(aug_Bild,[erste_spalte erste_zeile 223 223]);
end

% 4) Zufällig Helligkeit +/-10%
aug_Bild=im2double(aug_Bild);
helligkeit=1+0.2*(rand-0.5);
aug_Bild=aug_Bild*helligkeit;
aug_Bild=mat2gray(aug_Bild);
% Bild mit 0 bis 255 Graustufen
aug_Bild=im2uint8(aug_Bild);
end