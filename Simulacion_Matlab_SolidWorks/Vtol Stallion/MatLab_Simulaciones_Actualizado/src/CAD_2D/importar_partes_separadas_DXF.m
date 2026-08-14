function resPartesDXF = importar_partes_separadas_DXF(cfgProyecto, cfgDXF, bboxReferencia)
%IMPORTAR_PARTES_SEPARADAS_DXF Lee todos los DXF separados del avion.
%
% Lee:
%   cad/estructura_dxf/*.dxf
%   cad/componentes_dxf/*.dxf
%
% Cada archivo representa una parte:
%   FUSELAJE.dxf
%   ALA_IZQ_FIJA.dxf
%   SERVO_ALA_IZQ.dxf
%   MOTOR_DER.dxf
%   etc.
%
% La posicion se conserva usando bboxReferencia del VTOL_GENERAL.
%
% Nota:
%   El DXF general puede venir en mm y los DXF separados pueden venir en m.
%   Por eso se usa cfgDXF.unidadesDXFPartes para las partes separadas.

if nargin < 3
    bboxReferencia = [];
end

if ~isfield(cfgDXF, 'unidadesDXFPartes') || isempty(cfgDXF.unidadesDXFPartes)
    cfgDXF.unidadesDXFPartes = cfgDXF.unidadesDXF;
end

grupos = {
    "estructura", cfgProyecto.cadEstructuraDXF
    "componente", cfgProyecto.cadComponentesDXF
};

parteBase = crear_parte_base();
partes = repmat(parteBase, 0, 1);

fprintf('\nImportando DXF separados:\n');
fprintf('  Unidad usada para DXF separados: %s\n', string(cfgDXF.unidadesDXFPartes));

for g = 1:size(grupos,1)

    categoria = grupos{g,1};
    carpeta = grupos{g,2};

    archivos = listar_dxf_en_carpeta(carpeta);

    fprintf('  %s: %d archivos\n', categoria, numel(archivos));

    for i = 1:numel(archivos)

        archivo = fullfile(archivos(i).folder, archivos(i).name);

        [~, nombreArchivo, ~] = fileparts(archivo);
        nombreParte = string(nombreArchivo);

        fprintf('    Leyendo %s...\n', nombreParte);

        cfgLocal = cfgDXF;
        cfgLocal.dibujar = false;
        cfgLocal.mostrarIndices = false;

        % Al leer DXF separados no usar clasificacion manual del DXF general
        cfgLocal.idsServosManual = [];
        cfgLocal.idBateriaManual = [];
        cfgLocal.idElectronicaManual = [];

        % Usar unidad especial para DXF separados
        cfgLocal.unidadesDXF = cfgDXF.unidadesDXFPartes;

        % Usar bbox del DXF general para mantener sistema del avion
        if ~isempty(bboxReferencia)
            cfgLocal.bboxReferencia = bboxReferencia;
        end

        geomParte = analizar_DXF_avion_2D(archivo, cfgLocal);

        parte = calcular_propiedades_parte_dxf( ...
            geomParte, ...
            archivo, ...
            nombreParte, ...
            categoria);

        partes(end+1,1) = parte; %#ok<AGROW>
    end
end

% Asignar ID global dentro del arreglo de partes
for k = 1:numel(partes)
    partes(k).id_global = k;
end

tablaPartes = crear_tabla_partes_dxf(partes);

resPartesDXF.partes = partes;
resPartesDXF.tablaPartes = tablaPartes;
resPartesDXF.tablaCSV = tablaPartes;

fprintf('\nTotal de partes DXF importadas: %d\n', numel(partes));

end


%% ============================================================
function archivos = listar_dxf_en_carpeta(carpeta)
%LISTAR_DXF_EN_CARPETA Lista archivos DXF sin duplicarlos.
%
% En Windows, *.dxf tambien puede encontrar archivos .DXF.
% Por eso se eliminan duplicados por ruta completa en minuscula.

archivos1 = dir(fullfile(carpeta, '*.dxf'));
archivos2 = dir(fullfile(carpeta, '*.DXF'));

archivos = [archivos1; archivos2];

if isempty(archivos)
    return;
end

rutas = strings(numel(archivos),1);

for i = 1:numel(archivos)
    rutas(i) = lower(string(fullfile(archivos(i).folder, archivos(i).name)));
end

[~, idxUnicos] = unique(rutas, 'stable');
archivos = archivos(idxUnicos);

[~, idxOrden] = sort(lower(string({archivos.name})));
archivos = archivos(idxOrden);

end


%% ============================================================
function parte = crear_parte_base()
%CREAR_PARTE_BASE Crea la estructura base para una parte importada.

parte = struct( ...
    'id_global', NaN, ...
    'categoria', "", ...
    'tipo', "", ...
    'nombre', "", ...
    'archivoDXF', "", ...
    'x_mm', NaN, ...
    'y_mm', NaN, ...
    'z_mm', 0, ...
    'x_min_mm', NaN, ...
    'x_max_mm', NaN, ...
    'y_min_mm', NaN, ...
    'y_max_mm', NaN, ...
    'largo_x_mm', NaN, ...
    'ancho_y_mm', NaN, ...
    'area_mm2', NaN, ...
    'masa_g', NaN, ...
    'material', "", ...
    'fuente_posicion', "DXF_separado", ...
    'fuente_masa', "manual", ...
    'detectada', false, ...
    'num_puntos', 0, ...
    'notas', "", ...
    'puntos_m', zeros(0,2), ...
    'contorno_m', zeros(0,2), ...
    'geom2D', []);

end


%% ============================================================
function parte = calcular_propiedades_parte_dxf(geomParte, archivo, nombreParte, categoria)
%CALCULAR_PROPIEDADES_PARTE_DXF Calcula centro, area y dimensiones de una parte.

P = extraer_puntos_geom2D_completo(geomParte);

parte = crear_parte_base();

parte.categoria = string(categoria);
parte.nombre = string(nombreParte);
parte.tipo = clasificar_tipo_por_nombre(nombreParte, categoria);
parte.archivoDXF = string(archivo);
parte.z_mm = 0;
parte.masa_g = NaN;
parte.material = "";
parte.fuente_posicion = "DXF_separado";
parte.fuente_masa = "manual";
parte.notas = "Completar masa_g, z_mm y material manualmente";
parte.puntos_m = P;
parte.geom2D = geomParte;
parte.num_puntos = size(P,1);
parte.detectada = size(P,1) >= 3;

if isempty(P) || size(P,1) < 2
    return;
end

x = P(:,1);
y = P(:,2);

parte.x_min_mm = 1000 * min(x);
parte.x_max_mm = 1000 * max(x);
parte.y_min_mm = 1000 * min(y);
parte.y_max_mm = 1000 * max(y);

parte.largo_x_mm = parte.x_max_mm - parte.x_min_mm;
parte.ancho_y_mm = parte.y_max_mm - parte.y_min_mm;

if size(P,1) >= 3
    [area_m2, contorno, centro] = calcular_area_contorno_centro(P);

    parte.area_mm2 = area_m2 * 1e6;
    parte.contorno_m = contorno;
    parte.x_mm = 1000 * centro(1);
    parte.y_mm = 1000 * centro(2);
else
    parte.x_mm = 1000 * mean(x);
    parte.y_mm = 1000 * mean(y);
end

end


%% ============================================================
function tipo = clasificar_tipo_por_nombre(nombreParte, categoria)
%CLASIFICAR_TIPO_POR_NOMBRE Clasifica cada archivo por su nombre.
%
% Orden importante:
%   SERVO_MOTOR_DER debe ser servo, no motor.
%   ELEVON_COLA_DER debe ser superficie_control, no cola.
%   ALERON_DER debe ser superficie_control, no ala.

n = upper(string(nombreParte));
categoria = string(categoria);

if categoria == "estructura"

    if contains(n, "ALERON") || contains(n, "ELEVON") || contains(n, "FLAP")
        tipo = "superficie_control";

    elseif contains(n, "FUSELAJE") && (contains(n, "COLA") || contains(n, "TRASERO") || contains(n, "TAIL"))
        tipo = "fuselaje_cola";

    elseif contains(n, "FUSELAJE")
        tipo = "fuselaje";

    elseif contains(n, "ALA")
        tipo = "ala";

    elseif contains(n, "COLA")
        tipo = "cola";

    elseif contains(n, "BOOM")
        tipo = "boom";

    elseif contains(n, "SOPORTE")
        tipo = "soporte_motor";

    else
        tipo = "estructura";
    end

else

    if contains(n, "SERVO")
        tipo = "servo";

    elseif contains(n, "MOTOR")
        tipo = "motor";

    elseif contains(n, "BATERIA")
        tipo = "bateria";

    elseif contains(n, "ELECTRONICA")
        tipo = "electronica";

    else
        tipo = "componente";
    end
end

tipo = string(tipo);

end


%% ============================================================
function [area, contorno, centro] = calcular_area_contorno_centro(P)
%CALCULAR_AREA_CONTORNO_CENTRO Calcula area, contorno y centroide aproximado.

P2 = P(all(isfinite(P),2),:);
P2 = unique(round(P2/1e-6)*1e-6, 'rows');

if size(P2,1) < 3
    area = NaN;
    contorno = zeros(0,2);
    centro = mean(P2,1);
    return;
end

x = P2(:,1);
y = P2(:,2);

try
    k = boundary(x, y, 0.85);
catch
    k = convhull(x, y);
end

contorno = [x(k), y(k)];
area = polyarea(contorno(:,1), contorno(:,2));

centro = calcular_centroide_poligono(contorno);

if any(~isfinite(centro))
    centro = mean(P2,1);
end

end


%% ============================================================
function c = calcular_centroide_poligono(P)
%CALCULAR_CENTROIDE_POLIGONO Calcula centroide de un poligono 2D.

if isempty(P) || size(P,1) < 3
    c = [NaN NaN];
    return;
end

if norm(P(1,:) - P(end,:)) > 1e-12
    P = [P; P(1,:)];
end

x = P(:,1);
y = P(:,2);

crossVal = x(1:end-1).*y(2:end) - x(2:end).*y(1:end-1);
A = 0.5 * sum(crossVal);

if abs(A) < eps
    c = mean(P(1:end-1,:),1);
    return;
end

cx = sum((x(1:end-1) + x(2:end)) .* crossVal) / (6*A);
cy = sum((y(1:end-1) + y(2:end)) .* crossVal) / (6*A);

c = [cx cy];

end


%% ============================================================
function P = extraer_puntos_geom2D_completo(geom2D)
%EXTRAER_PUNTOS_GEOM2D_COMPLETO Junta puntos de lineas, arcos, splines,
% circulos y rectangulos.

P = [];

if isfield(geom2D, 'lines')
    for i = 1:numel(geom2D.lines)
        P = [P; geom2D.lines(i).p1; geom2D.lines(i).p2]; %#ok<AGROW>
    end
end

if isfield(geom2D, 'polylines')
    for i = 1:numel(geom2D.polylines)
        P = [P; geom2D.polylines(i).points]; %#ok<AGROW>
    end
end

if isfield(geom2D, 'arcs')
    for i = 1:numel(geom2D.arcs)
        P = [P; geom2D.arcs(i).points]; %#ok<AGROW>
    end
end

if isfield(geom2D, 'splines')
    for i = 1:numel(geom2D.splines)
        P = [P; geom2D.splines(i).points]; %#ok<AGROW>
    end
end

if isfield(geom2D, 'circles')
    for i = 1:numel(geom2D.circles)
        c = geom2D.circles(i).center;
        r = geom2D.circles(i).radius;

        th = linspace(0, 2*pi, 100)';
        Pc = [c(1) + r*cos(th), c(2) + r*sin(th)];

        P = [P; Pc]; %#ok<AGROW>
    end
end

if isfield(geom2D, 'rectangulos')
    for i = 1:numel(geom2D.rectangulos)
        P = [P; geom2D.rectangulos(i).vertices]; %#ok<AGROW>
    end
end

if ~isempty(P)
    P = P(all(isfinite(P),2),:);
end

end


%% ============================================================
function T = crear_tabla_partes_dxf(partes)
%CREAR_TABLA_PARTES_DXF Convierte las partes importadas en una tabla.

n = numel(partes);

id_global = (1:n)';
categoria = strings(n,1);
tipo = strings(n,1);
nombre = strings(n,1);
archivoDXF = strings(n,1);

x_mm = NaN(n,1);
y_mm = NaN(n,1);
z_mm = NaN(n,1);

x_min_mm = NaN(n,1);
x_max_mm = NaN(n,1);
y_min_mm = NaN(n,1);
y_max_mm = NaN(n,1);

largo_x_mm = NaN(n,1);
ancho_y_mm = NaN(n,1);
area_mm2 = NaN(n,1);

masa_g = NaN(n,1);
material = strings(n,1);
fuente_posicion = strings(n,1);
fuente_masa = strings(n,1);
detectada = false(n,1);
num_puntos = zeros(n,1);
notas = strings(n,1);

for i = 1:n

    categoria(i) = partes(i).categoria;
    tipo(i) = partes(i).tipo;
    nombre(i) = partes(i).nombre;
    archivoDXF(i) = partes(i).archivoDXF;

    x_mm(i) = partes(i).x_mm;
    y_mm(i) = partes(i).y_mm;
    z_mm(i) = partes(i).z_mm;

    x_min_mm(i) = partes(i).x_min_mm;
    x_max_mm(i) = partes(i).x_max_mm;
    y_min_mm(i) = partes(i).y_min_mm;
    y_max_mm(i) = partes(i).y_max_mm;

    largo_x_mm(i) = partes(i).largo_x_mm;
    ancho_y_mm(i) = partes(i).ancho_y_mm;
    area_mm2(i) = partes(i).area_mm2;

    masa_g(i) = partes(i).masa_g;
    material(i) = partes(i).material;
    fuente_posicion(i) = partes(i).fuente_posicion;
    fuente_masa(i) = partes(i).fuente_masa;
    detectada(i) = partes(i).detectada;
    num_puntos(i) = partes(i).num_puntos;
    notas(i) = partes(i).notas;
end

T = table(id_global, categoria, tipo, nombre, archivoDXF, ...
          x_mm, y_mm, z_mm, ...
          x_min_mm, x_max_mm, y_min_mm, y_max_mm, ...
          largo_x_mm, ancho_y_mm, area_mm2, ...
          masa_g, material, fuente_posicion, fuente_masa, ...
          detectada, num_puntos, notas);

end