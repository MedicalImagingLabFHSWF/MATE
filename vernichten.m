function vernichten(pattern)
d = dir(pattern);

for i = 1:numel(d)
    %erstellt den vollständigen Pfad 
    pfad = fullfile(d(i).folder, d(i).name); 
    % ignoriert . und ..   sind nicht sichtbar, tauchen aber auf
    if strcmp(d(i).name,'.')||strcmp(d(i).name,'..')
        continue;
    end
    % 7 ist die rückgabe die zeigt das bei exist ein Ordner gefunden wurde.
    % damit wird überprüft ob der Pfad in der Variable pfad sich befindet.
    if d(i).isdir
        if exist(pfad,'dir') == 7

            % versucht den ordner zu löschen, rekusiv (Funktioniert nur
            %  bei Verzeichnissen)
            try
                rmdir(pfad,'s');
            % Falls ein Fehler passiert, wird dieser abgefangen, damit das
            % Script nicht abstürzt
            % Me beinhaltet die Fehlerinformation 
            catch ME
                fprintf('Fehler bei "%s": %s\n',pfad, ME.message);
            end
        else
            fprintf('"%s" ist kein gueltiges Verzeichnis. \n', pfad);
        end
    else 
        try 
            % Falls kein Ordner, dann Datei die gelöscht
            % wird.(Funktioniert nur bei Datein)
            delete(pfad);
        catch ME
            fprintf('Fehler: "%s": %s\n',pfad, ME.message);
        end
    end
end
end