function archivosGuardados = guardar_figuras_abiertas_vtol(carpetaSalida, prefijo)
%GUARDAR_FIGURAS_ABIERTAS_VTOL Guarda todas las figuras abiertas.
%
% Guarda cada figura en:
%   .fig  editable en MATLAB
%   .png  imagen de alta resolucion
%   .pdf  vectorial para informes

if nargin < 1 || isempty(carpetaSalida)
    carpetaSalida = fullfile(pwd, 'resultados', 'figuras');
end

if nargin < 2 || isempty(prefijo)
    prefijo = "figura";
end

if ~isfolder(carpetaSalida)
    mkdir(carpetaSalida);
end

figs = findall(groot, 'Type', 'figure');

archivosGuardados = strings(0,1);

if isempty(figs)
    fprintf('\nNo hay figuras abiertas para guardar.\n');
    return;
end

% ============================================================
% Ordenar figuras de forma robusta
% ============================================================

figNums = zeros(numel(figs),1);

for k = 1:numel(figs)
    try
        n = figs(k).Number;

        if isnumeric(n) && isscalar(n) && isfinite(n)
            figNums(k) = double(n);
        else
            figNums(k) = k;
        end
    catch
        figNums(k) = k;
    end
end

[~, ord] = sort(figNums, 'ascend');
figs = figs(ord);

% ============================================================
% Guardar cada figura
% ============================================================

for i = 1:numel(figs)

    fig = figs(i);

    try
        nombreFig = string(fig.Name);
    catch
        nombreFig = "";
    end

    if strlength(nombreFig) == 0
        nombreFig = "Figura_" + string(i);
    end

    nombreFig = limpiar_nombre_archivo(nombreFig);

    nombreBase = sprintf('%02d_%s_%s', ...
        i, char(prefijo), char(nombreFig));

    archivoFIG = fullfile(carpetaSalida, nombreBase + ".fig");
    archivoPNG = fullfile(carpetaSalida, nombreBase + ".png");
    archivoPDF = fullfile(carpetaSalida, nombreBase + ".pdf");

    archivoFIG = char(archivoFIG);
    archivoPNG = char(archivoPNG);
    archivoPDF = char(archivoPDF);

    % Guardar editable MATLAB
    try
        savefig(fig, archivoFIG);
    catch ME
        warning('No se pudo guardar FIG: %s\nMotivo: %s', archivoFIG, ME.message);
    end

    % Guardar PNG
    try
        exportgraphics(fig, archivoPNG, 'Resolution', 300);
    catch
        try
            saveas(fig, archivoPNG);
        catch ME
            warning('No se pudo guardar PNG: %s\nMotivo: %s', archivoPNG, ME.message);
        end
    end

    % Guardar PDF
    try
        exportgraphics(fig, archivoPDF, 'ContentType', 'vector');
    catch
        try
            saveas(fig, archivoPDF);
        catch ME
            warning('No se pudo guardar PDF: %s\nMotivo: %s', archivoPDF, ME.message);
        end
    end

    archivosGuardados(end+1,1) = string(archivoFIG); %#ok<AGROW>
    archivosGuardados(end+1,1) = string(archivoPNG); %#ok<AGROW>
    archivosGuardados(end+1,1) = string(archivoPDF); %#ok<AGROW>

    fprintf('Figura guardada: %s\n', archivoPNG);
end

end


%% ============================================================
function nombreLimpio = limpiar_nombre_archivo(nombre)
%LIMPIAR_NOMBRE_ARCHIVO Elimina caracteres invalidos para nombres de archivo.

nombreLimpio = string(nombre);

caracteresInvalidos = ["\", "/", ":", "*", "?", """", "<", ">", "|"];

for k = 1:numel(caracteresInvalidos)
    nombreLimpio = replace(nombreLimpio, caracteresInvalidos(k), "_");
end

nombreLimpio = replace(nombreLimpio, " ", "_");
nombreLimpio = replace(nombreLimpio, "-", "_");

while contains(nombreLimpio, "__")
    nombreLimpio = replace(nombreLimpio, "__", "_");
end

end