function T = actualizar_tabla_maestra_desde_csv(Tnuevo, archivoCSV)
%ACTUALIZAR_TABLA_MAESTRA_DESDE_CSV
% Recupera datos manuales desde un CSV existente.
%
% Uso:
%   T = actualizar_tabla_maestra_desde_csv(Tnuevo, archivoCSV)
%
% Objetivo:
%   Cuando MATLAB vuelve a generar la tabla desde los DXF, no queremos
%   perder los valores que el usuario ya completo manualmente en el CSV:
%
%       masa_g
%       z_mm
%       material
%       notas
%       fuente_masa
%
% La coincidencia entre filas se hace usando:
%
%       categoria + nombre
%
% Ejemplo de clave:
%
%       estructura|FUSELAJE
%       componente|BATERIA
%       componente|SERVO_ALA_DER

T = Tnuevo;

%% ============================================================
% 1. Validaciones iniciales
% ============================================================

if nargin < 2 || isempty(archivoCSV)
    return;
end

if ~isfile(archivoCSV)
    % Si el CSV todavia no existe, no hay nada que recuperar.
    return;
end

if isempty(Tnuevo) || height(Tnuevo) == 0
    return;
end

%% ============================================================
% 2. Leer CSV anterior
% ============================================================

try
    Told = readtable(archivoCSV, ...
        'TextType', 'string', ...
        'VariableNamingRule', 'preserve');
catch ME
    warning('No se pudo leer el CSV existente: %s\nMotivo: %s', ...
        archivoCSV, ME.message);
    return;
end

if isempty(Told) || height(Told) == 0
    return;
end

%% ============================================================
% 3. Verificar columnas clave
% ============================================================

varsNew = string(T.Properties.VariableNames);
varsOld = string(Told.Properties.VariableNames);

if ~all(ismember(["categoria","nombre"], varsNew))
    warning('La tabla nueva no tiene las columnas categoria y nombre.');
    return;
end

if ~all(ismember(["categoria","nombre"], varsOld))
    warning('El CSV anterior no tiene las columnas categoria y nombre.');
    return;
end

%% ============================================================
% 4. Crear claves de coincidencia
% ============================================================

keyNew = crear_clave(T.categoria, T.nombre);
keyOld = crear_clave(Told.categoria, Told.nombre);

[tf, loc] = ismember(keyNew, keyOld);

idxMatch = find(tf);

if isempty(idxMatch)
    fprintf('No se encontraron coincidencias entre la tabla nueva y el CSV anterior.\n');
    return;
end

%% ============================================================
% 5. Recuperar columnas manuales
% ============================================================

colsPreservar = ["masa_g", "z_mm", "material", "notas", "fuente_masa"];

for c = 1:numel(colsPreservar)

    col = colsPreservar(c);

    if ~ismember(col, varsNew) || ~ismember(col, varsOld)
        continue;
    end

    try
        T = copiar_columna(T, Told, col, idxMatch, loc);
    catch ME
        warning('No se pudo recuperar la columna %s. Motivo: %s', ...
            col, ME.message);
    end
end

%% ============================================================
% 6. Actualizar fuente_masa si ya hay masa valida
% ============================================================

varsNew = string(T.Properties.VariableNames);

if ismember("masa_g", varsNew) && ismember("fuente_masa", varsNew)

    try
        masa = T.masa_g;

        if isnumeric(masa)
            idxMasaValida = isfinite(masa);

            if any(idxMasaValida)
                if ~isstring(T.fuente_masa)
                    T.fuente_masa = string(T.fuente_masa);
                end

                T.fuente_masa(idxMasaValida) = "csv_manual";
            end
        end
    catch
        % No detener el programa por este ajuste secundario.
    end
end

fprintf('Datos manuales recuperados desde CSV anterior: %d filas coincidentes.\n', ...
    numel(idxMatch));

end


%% ============================================================
function key = crear_clave(categoria, nombre)
%CREAR_CLAVE Crea clave categoria|nombre normalizada.

categoria = upper(strtrim(string(categoria)));
nombre = upper(strtrim(string(nombre)));

key = categoria + "|" + nombre;

end


%% ============================================================
function T = copiar_columna(T, Told, col, idxMatch, loc)
%COPIAR_COLUMNA Copia una columna del CSV anterior a la tabla nueva.
%
% Maneja columnas numericas y texto/string.

idxOld = loc(idxMatch);

valorOld = Told.(col)(idxOld);

% Caso 1: columna nueva numerica
if isnumeric(T.(col))

    if isnumeric(valorOld)
        T.(col)(idxMatch) = valorOld;
    else
        T.(col)(idxMatch) = str2double(string(valorOld));
    end

    return;
end

% Caso 2: columna nueva string
if isstring(T.(col))

    T.(col)(idxMatch) = string(valorOld);
    return;
end

% Caso 3: columna nueva cellstr o similar
if iscell(T.(col))

    T.(col)(idxMatch) = cellstr(string(valorOld));
    return;
end

% Caso 4: intento directo
T.(col)(idxMatch) = valorOld;

end