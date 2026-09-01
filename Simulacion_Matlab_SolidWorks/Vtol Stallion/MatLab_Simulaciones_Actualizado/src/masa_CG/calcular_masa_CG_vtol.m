function resMasaCG = calcular_masa_CG_vtol(entrada)
%CALCULAR_MASA_CG_VTOL Calcula masa total y centro de gravedad del VTOL.
%
% Entrada:
%   entrada puede ser:
%       1) una tabla MATLAB
%       2) la ruta al CSV componentes_vtol_base.csv
%
% Requiere columnas:
%   categoria
%   tipo
%   nombre
%   x_mm
%   y_mm
%   z_mm
%   masa_g
%
% Salida:
%   resMasaCG con:
%       masa total
%       peso total
%       CG en mm y m
%       tabla usada
%       tabla de validacion
%       masa por categoria
%       masa por tipo

%% ============================================================
% 1. Leer entrada
% ============================================================

if istable(entrada)
    T = entrada;
    fuente = "tabla_MATLAB";
elseif ischar(entrada) || isstring(entrada)
    archivoCSV = string(entrada);

    if ~isfile(archivoCSV)
        error('No se encontro el archivo CSV: %s', archivoCSV);
    end

    T = readtable(archivoCSV, ...
        'TextType', 'string', ...
        'VariableNamingRule', 'preserve');

    fuente = archivoCSV;
else
    error('La entrada debe ser una tabla MATLAB o una ruta CSV.');
end

if isempty(T) || height(T) == 0
    error('La tabla de entrada esta vacia.');
end

%% ============================================================
% 2. Validar columnas obligatorias
% ============================================================

colsReq = ["categoria","tipo","nombre","x_mm","y_mm","z_mm","masa_g"];
colsTabla = string(T.Properties.VariableNames);

faltantes = colsReq(~ismember(colsReq, colsTabla));

if ~isempty(faltantes)
    error('Faltan columnas obligatorias en la tabla: %s', strjoin(faltantes, ', '));
end

%% ============================================================
% 3. Normalizar columnas numericas
% ============================================================

T.x_mm = convertir_a_numero(T.x_mm);
T.y_mm = convertir_a_numero(T.y_mm);
T.z_mm = convertir_a_numero(T.z_mm);
T.masa_g = convertir_a_numero(T.masa_g);

if ismember("area_mm2", string(T.Properties.VariableNames))
    T.area_mm2 = convertir_a_numero(T.area_mm2);
else
    T.area_mm2 = NaN(height(T),1);
end

% Normalizar texto
T.categoria = string(T.categoria);
T.tipo = string(T.tipo);
T.nombre = string(T.nombre);

if ismember("material", string(T.Properties.VariableNames))
    T.material = string(T.material);
else
    T.material = strings(height(T),1);
end

%% ============================================================
% 4. Crear columnas en unidades SI
% ============================================================

T.x_m = T.x_mm / 1000;
T.y_m = T.y_mm / 1000;
T.z_m = T.z_mm / 1000;
T.masa_kg = T.masa_g / 1000;
T.area_m2 = T.area_mm2 / 1e6;

%% ============================================================
% 5. Validar filas utilizables
% ============================================================

idxMasaValida = isfinite(T.masa_g) & T.masa_g > 0;
idxPosValida = isfinite(T.x_mm) & isfinite(T.y_mm) & isfinite(T.z_mm);

idxUsar = idxMasaValida & idxPosValida;

T.usada_calculo = idxUsar;

if ~any(idxUsar)
    error(['No hay ninguna fila valida para calcular masa y CG. ', ...
           'Revisa masa_g, x_mm, y_mm y z_mm.']);
end

Tval = T(idxUsar,:);

%% ============================================================
% 6. Calcular masa total y peso
% ============================================================

g = 9.80665;

masa_total_g = sum(Tval.masa_g);
masa_total_kg = masa_total_g / 1000;
peso_total_N = masa_total_kg * g;

%% ============================================================
% 7. Calcular centro de gravedad
% ============================================================

CG_x_mm = sum(Tval.masa_g .* Tval.x_mm) / masa_total_g;
CG_y_mm = sum(Tval.masa_g .* Tval.y_mm) / masa_total_g;
CG_z_mm = sum(Tval.masa_g .* Tval.z_mm) / masa_total_g;

CG_x_m = CG_x_mm / 1000;
CG_y_m = CG_y_mm / 1000;
CG_z_m = CG_z_mm / 1000;

%% ============================================================
% 8. Agregar columnas de distancia al CG
% ============================================================

T.dx_CG_mm = NaN(height(T),1);
T.dy_CG_mm = NaN(height(T),1);
T.dz_CG_mm = NaN(height(T),1);

T.dx_CG_m = NaN(height(T),1);
T.dy_CG_m = NaN(height(T),1);
T.dz_CG_m = NaN(height(T),1);

T.fraccion_masa_pct = NaN(height(T),1);

T.dx_CG_mm(idxUsar) = T.x_mm(idxUsar) - CG_x_mm;
T.dy_CG_mm(idxUsar) = T.y_mm(idxUsar) - CG_y_mm;
T.dz_CG_mm(idxUsar) = T.z_mm(idxUsar) - CG_z_mm;

T.dx_CG_m(idxUsar) = T.dx_CG_mm(idxUsar) / 1000;
T.dy_CG_m(idxUsar) = T.dy_CG_mm(idxUsar) / 1000;
T.dz_CG_m(idxUsar) = T.dz_CG_mm(idxUsar) / 1000;

T.fraccion_masa_pct(idxUsar) = 100 * T.masa_g(idxUsar) / masa_total_g;

Tval = T(idxUsar,:);

%% ============================================================
% 9. Tablas resumen
% ============================================================

tablaPorCategoria = resumir_masa_por_columna(T, idxUsar, "categoria");
tablaPorTipo = resumir_masa_por_columna(T, idxUsar, "tipo");

tablaFaltantes = T(~idxUsar, :);

%% ============================================================
% 10. Empaquetar resultados
% ============================================================

resMasaCG.fuente = fuente;

resMasaCG.const.g = g;

resMasaCG.masa.total_g = masa_total_g;
resMasaCG.masa.total_kg = masa_total_kg;
resMasaCG.masa.peso_N = peso_total_N;

resMasaCG.CG.x_mm = CG_x_mm;
resMasaCG.CG.y_mm = CG_y_mm;
resMasaCG.CG.z_mm = CG_z_mm;

resMasaCG.CG.x_m = CG_x_m;
resMasaCG.CG.y_m = CG_y_m;
resMasaCG.CG.z_m = CG_z_m;

resMasaCG.validacion.n_filas_total = height(T);
resMasaCG.validacion.n_filas_usadas = sum(idxUsar);
resMasaCG.validacion.n_filas_ignoradas = sum(~idxUsar);
resMasaCG.validacion.idx_usar = idxUsar;
resMasaCG.validacion.tabla_faltantes = tablaFaltantes;

resMasaCG.tablaCompleta = T;
resMasaCG.tablaUsada = Tval;

resMasaCG.resumen.porCategoria = tablaPorCategoria;
resMasaCG.resumen.porTipo = tablaPorTipo;

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

x = str2double(s);

end


%% ============================================================
function Tsum = resumir_masa_por_columna(T, idxUsar, col)
%RESUMIR_MASA_POR_COLUMNA Resume masa por categoria, tipo, etc.

Tv = T(idxUsar,:);

grupo = string(Tv.(col));
grupo(ismissing(grupo) | strlength(strtrim(grupo)) == 0) = "sin_dato";

gruposUnicos = unique(grupo, 'stable');

masa_g = zeros(numel(gruposUnicos),1);
masa_kg = zeros(numel(gruposUnicos),1);
porcentaje_masa = zeros(numel(gruposUnicos),1);
n_partes = zeros(numel(gruposUnicos),1);

masaTotal = sum(Tv.masa_g);

for i = 1:numel(gruposUnicos)
    idx = grupo == gruposUnicos(i);

    masa_g(i) = sum(Tv.masa_g(idx));
    masa_kg(i) = masa_g(i) / 1000;
    porcentaje_masa(i) = 100 * masa_g(i) / masaTotal;
    n_partes(i) = sum(idx);
end

Tsum = table(gruposUnicos, n_partes, masa_g, masa_kg, porcentaje_masa);
Tsum.Properties.VariableNames{1} = char(col);

end