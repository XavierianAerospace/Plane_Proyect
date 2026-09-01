%% editar_csv_prueba_masas.m
% Llena masas, z_mm y material de prueba en componentes_vtol_base.csv
%
% Este script es solo para probar la logica de:
%   - lectura del CSV
%   - masa total
%   - centro de gravedad
%   - graficas de masa y CG
%
% No son valores finales de validacion del avion.

clear;
clc;

%% ============================================================
% 1. UBICAR PROYECTO Y CSV
% ============================================================

rootProyecto = fileparts(fileparts(mfilename('fullpath')));

if isempty(rootProyecto)
    rootProyecto = pwd;
end

archivoCSV = fullfile( ...
    rootProyecto, ...
    'resultados', ...
    'datos_procesados', ...
    'componentes_vtol_base.csv');

if ~isfile(archivoCSV)
    error('No se encontro el CSV: %s', archivoCSV);
end

fprintf('\nLeyendo CSV:\n%s\n', archivoCSV);

T = readtable(archivoCSV, ...
    'TextType', 'string', ...
    'VariableNamingRule', 'preserve');

%% ============================================================
% 2. LIMPIAR Y ASEGURAR FORMATOS
% ============================================================

% Asegurar columnas base como texto
T.nombre = string(T.nombre);
T.tipo = string(T.tipo);
T.categoria = string(T.categoria);

% Asegurar masa_g
if ~ismember("masa_g", string(T.Properties.VariableNames))
    T.masa_g = NaN(height(T),1);
else
    T.masa_g = convertir_a_numero(T.masa_g);
end

% Asegurar z_mm
if ~ismember("z_mm", string(T.Properties.VariableNames))
    T.z_mm = zeros(height(T),1);
else
    T.z_mm = convertir_a_numero(T.z_mm);
end

% Asegurar material como texto
if ~ismember("material", string(T.Properties.VariableNames))
    T.material = strings(height(T),1);
else
    T.material = string(T.material);
end

% Limpiar material vacio o NaN
idxMaterialVacio = ismissing(T.material) | ...
                   strlength(strtrim(T.material)) == 0 | ...
                   upper(strtrim(T.material)) == "NAN" | ...
                   upper(strtrim(T.material)) == "<MISSING>";

T.material(idxMaterialVacio) = "Sin_definir";

% Asegurar fuente_masa como texto
if ismember("fuente_masa", string(T.Properties.VariableNames))
    T.fuente_masa = string(T.fuente_masa);

    idxFuenteVacia = ismissing(T.fuente_masa) | ...
                     strlength(strtrim(T.fuente_masa)) == 0 | ...
                     upper(strtrim(T.fuente_masa)) == "NAN" | ...
                     upper(strtrim(T.fuente_masa)) == "<MISSING>";

    T.fuente_masa(idxFuenteVacia) = "manual";
end

%% ============================================================
% 3. MASAS, Z Y MATERIAL DE PRUEBA
% ============================================================

T = poner_valores(T, "ALA_DER_FIJA",       120,   0,  "PLA");
T = poner_valores(T, "ALA_IZQ_FIJA",       120,   0,  "PLA");

T = poner_valores(T, "ALERON_DER",          20,   0,  "PLA");
T = poner_valores(T, "ALERON_IZQ",          20,   0,  "PLA");

T = poner_valores(T, "BOOM_TRASERO",        35, -10,  "Carbono");

T = poner_valores(T, "COLA_DER_FIJA",       35,   0,  "PLA");
T = poner_valores(T, "COLA_IZQ_FIJA",       35,   0,  "PLA");

T = poner_valores(T, "ELEVON_COLA_DER",     12,   0,  "PLA");
T = poner_valores(T, "ELEVON_COLA_IZQ",     12,   0,  "PLA");

T = poner_valores(T, "FUSELAJE",           250,   0,  "PLA");
T = poner_valores(T, "FUSELAJE_COLA",       80, -10,  "PLA");

T = poner_valores(T, "SOPORTE_MOTOR_DER",   45,  10,  "PLA");
T = poner_valores(T, "SOPORTE_MOTOR_IZQ",   45,  10,  "PLA");

T = poner_valores(T, "BATERIA",            450, -25,  "Bateria");
T = poner_valores(T, "ELECTRONICA",        120,  15,  "Electronica");

T = poner_valores(T, "MOTOR_DER",           80,  40,  "Motor");
T = poner_valores(T, "MOTOR_IZQ",           80,  40,  "Motor");
T = poner_valores(T, "MOTOR_TRASERO",       80,  40,  "Motor");

T = poner_valores(T, "SERVO_ALA_DER",       12,   5,  "Servo");
T = poner_valores(T, "SERVO_ALA_IZQ",       12,   5,  "Servo");

T = poner_valores(T, "SERVO_COLA_DER",      12,   0,  "Servo");
T = poner_valores(T, "SERVO_COLA_IZQ",      12,   0,  "Servo");

T = poner_valores(T, "SERVO_MOTOR_DER",     12,  20,  "Servo");
T = poner_valores(T, "SERVO_MOTOR_IZQ",     12,  20,  "Servo");

%% ============================================================
% 4. MATERIAL POR DEFECTO PARA FILAS NO MODIFICADAS
% ============================================================

idxMaterialVacio = ismissing(T.material) | ...
                   strlength(strtrim(T.material)) == 0 | ...
                   upper(strtrim(T.material)) == "NAN" | ...
                   upper(strtrim(T.material)) == "<MISSING>";

T.material(idxMaterialVacio) = "Sin_definir";

%% ============================================================
% 5. GUARDAR CSV
% ============================================================

writetable(T, archivoCSV);

fprintf('\nCSV actualizado correctamente:\n%s\n', archivoCSV);

fprintf('\nVista previa de columnas editadas:\n');
colsVista = ["nombre","masa_g","z_mm","material"];

colsVista = colsVista(ismember(colsVista, string(T.Properties.VariableNames)));

disp(T(:, colsVista));

fprintf('\nMasa total de prueba: %.2f g\n', sum(T.masa_g, 'omitnan'));
fprintf('Listo. Ahora puedes correr Main_Vtol.\n\n');


%% ============================================================
function T = poner_valores(T, nombreParte, masa_g, z_mm, material)
%PONER_VALORES Actualiza masa, z y material de una parte por nombre.

nombreParte = string(nombreParte);

idx = upper(strtrim(T.nombre)) == upper(strtrim(nombreParte));

if ~any(idx)
    warning('No se encontro la parte: %s', nombreParte);
    return;
end

T.masa_g(idx) = masa_g;
T.z_mm(idx) = z_mm;
T.material(idx) = string(material);

if ismember("fuente_masa", string(T.Properties.VariableNames))
    T.fuente_masa(idx) = "manual_prueba";
end

end


%% ============================================================
function x = convertir_a_numero(v)
%CONVERTIR_A_NUMERO Convierte columnas numericas o texto a double.

if isnumeric(v)
    x = double(v);
    return;
end

s = string(v);
s = strrep(s, ",", ".");
s = strtrim(s);

idxVacio = ismissing(s) | ...
           strlength(s) == 0 | ...
           upper(s) == "NAN" | ...
           upper(s) == "<MISSING>";

x = str2double(s);
x(idxVacio) = NaN;

end