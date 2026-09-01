function resEstructura2D = extraer_partes_estructurales_2D(geom2D, cfgPartes)
%EXTRAER_PARTES_ESTRUCTURALES_2D Extrae partes estructurales desde el DXF.
%
% Usa las regiones definidas en configurar_partes_estructurales_vtol.m
% para calcular:
%   - centro geometrico aproximado
%   - area en planta aproximada
%   - largo en x
%   - ancho en y
%   - numero de puntos encontrados
%
% Sistema interno:
%   x = longitudinal desde nariz hacia cola [m]
%   y = lateral [m]

if ~isfield(cfgPartes, 'usar') || ~cfgPartes.usar
    resEstructura2D.tablaPartes = table();
    resEstructura2D.partes = struct([]);
    return;
end

partesCfg = cfgPartes.partes;

parteBase = struct( ...
    'nombre', "", ...
    'tipo', "", ...
    'metodo', "", ...
    'layer', "", ...
    'x_mm', NaN, ...
    'y_mm', NaN, ...
    'z_mm', NaN, ...
    'x_min_mm', NaN, ...
    'x_max_mm', NaN, ...
    'y_min_mm', NaN, ...
    'y_max_mm', NaN, ...
    'largo_x_mm', NaN, ...
    'ancho_y_mm', NaN, ...
    'area_mm2', NaN, ...
    'masa_g', NaN, ...
    'material', "", ...
    'detectada', false, ...
    'num_puntos', 0, ...
    'notas', "");

partesOut = repmat(parteBase, 0, 1);

for i = 1:numel(partesCfg)

    cfgP = partesCfg(i);

    switch lower(string(cfgP.metodo))
        case "region"
            P = extraer_puntos_por_region(geom2D, cfgP);

        case "layer"
            P = extraer_puntos_por_layer(geom2D, cfgP.layer);

        otherwise
            warning("Metodo no reconocido para la parte: %s", cfgP.nombre);
            P = zeros(0,2);
    end

    parte = calcular_propiedades_parte(P, cfgP, cfgPartes);
    partesOut(end+1,1) = parte; %#ok<AGROW>
end

tablaPartes = crear_tabla_partes_estructurales(partesOut);

resEstructura2D.partes = partesOut;
resEstructura2D.tablaPartes = tablaPartes;

end


%% ============================================================
function Pregion = extraer_puntos_por_region(geom2D, cfgP)

P = extraer_puntos_geom2D_completo(geom2D);

if isempty(P)
    Pregion = zeros(0,2);
    return;
end

x_mm = 1000 * P(:,1);
y_mm = 1000 * P(:,2);

mask = x_mm >= cfgP.x_min_mm & x_mm <= cfgP.x_max_mm & ...
       y_mm >= cfgP.y_min_mm & y_mm <= cfgP.y_max_mm;

Pregion = P(mask,:);

end


%% ============================================================
function Player = extraer_puntos_por_layer(geom2D, layerBuscada)

Player = [];
layerBuscada = string(layerBuscada);

if isfield(geom2D, 'lines')
    for i = 1:numel(geom2D.lines)
        if string(geom2D.lines(i).layer) == layerBuscada
            Player = [Player; geom2D.lines(i).p1; geom2D.lines(i).p2]; %#ok<AGROW>
        end
    end
end

if isfield(geom2D, 'polylines')
    for i = 1:numel(geom2D.polylines)
        if string(geom2D.polylines(i).layer) == layerBuscada
            Player = [Player; geom2D.polylines(i).points]; %#ok<AGROW>
        end
    end
end

if isfield(geom2D, 'arcs')
    for i = 1:numel(geom2D.arcs)
        if string(geom2D.arcs(i).layer) == layerBuscada
            Player = [Player; geom2D.arcs(i).points]; %#ok<AGROW>
        end
    end
end

if isfield(geom2D, 'splines')
    for i = 1:numel(geom2D.splines)
        if string(geom2D.splines(i).layer) == layerBuscada
            Player = [Player; geom2D.splines(i).points]; %#ok<AGROW>
        end
    end
end

if isfield(geom2D, 'circles')
    for i = 1:numel(geom2D.circles)
        if string(geom2D.circles(i).layer) == layerBuscada
            c = geom2D.circles(i).center;
            r = geom2D.circles(i).radius;

            th = linspace(0, 2*pi, 80)';
            Pc = [c(1) + r*cos(th), c(2) + r*sin(th)];

            Player = [Player; Pc]; %#ok<AGROW>
        end
    end
end

end


%% ============================================================
function parte = calcular_propiedades_parte(P, cfgP, cfgPartes)

parte = struct( ...
    'nombre', string(cfgP.nombre), ...
    'tipo', string(cfgP.tipo), ...
    'metodo', string(cfgP.metodo), ...
    'layer', string(cfgP.layer), ...
    'x_mm', NaN, ...
    'y_mm', NaN, ...
    'z_mm', cfgP.z_mm, ...
    'x_min_mm', NaN, ...
    'x_max_mm', NaN, ...
    'y_min_mm', NaN, ...
    'y_max_mm', NaN, ...
    'largo_x_mm', NaN, ...
    'ancho_y_mm', NaN, ...
    'area_mm2', NaN, ...
    'masa_g', cfgP.masa_g, ...
    'material', string(cfgP.material), ...
    'detectada', false, ...
    'num_puntos', size(P,1), ...
    'notas', string(cfgP.notas));

if isempty(P) || size(P,1) < 2
    return;
end

x = P(:,1);
y = P(:,2);

parte.detectada = size(P,1) >= 3;

parte.x_mm = 1000 * mean(x);
parte.y_mm = 1000 * mean(y);

parte.x_min_mm = 1000 * min(x);
parte.x_max_mm = 1000 * max(x);
parte.y_min_mm = 1000 * min(y);
parte.y_max_mm = 1000 * max(y);

parte.largo_x_mm = parte.x_max_mm - parte.x_min_mm;
parte.ancho_y_mm = parte.y_max_mm - parte.y_min_mm;

if size(P,1) >= 3
    area_m2 = calcular_area_aproximada(P, cfgPartes.shrinkFactorBoundary);
    parte.area_mm2 = area_m2 * 1e6;
end

end


%% ============================================================
function area = calcular_area_aproximada(P, shrinkFactor)

P2 = unique(round(P/1e-6)*1e-6, 'rows');

if size(P2,1) < 3
    area = NaN;
    return;
end

x = P2(:,1);
y = P2(:,2);

try
    k = boundary(x, y, shrinkFactor);
catch
    k = convhull(x, y);
end

area = polyarea(x(k), y(k));

end


%% ============================================================
function P = extraer_puntos_geom2D_completo(geom2D)

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

        th = linspace(0, 2*pi, 80)';
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
function T = crear_tabla_partes_estructurales(partes)

nombre = strings(0,1);
tipo = strings(0,1);
metodo = strings(0,1);
x_mm = [];
y_mm = [];
z_mm = [];
area_mm2 = [];
largo_x_mm = [];
ancho_y_mm = [];
masa_g = [];
material = strings(0,1);
detectada = [];
num_puntos = [];
notas = strings(0,1);

for i = 1:numel(partes)

    nombre(end+1,1) = partes(i).nombre; %#ok<AGROW>
    tipo(end+1,1) = partes(i).tipo; %#ok<AGROW>
    metodo(end+1,1) = partes(i).metodo; %#ok<AGROW>

    x_mm(end+1,1) = partes(i).x_mm; %#ok<AGROW>
    y_mm(end+1,1) = partes(i).y_mm; %#ok<AGROW>
    z_mm(end+1,1) = partes(i).z_mm; %#ok<AGROW>

    area_mm2(end+1,1) = partes(i).area_mm2; %#ok<AGROW>
    largo_x_mm(end+1,1) = partes(i).largo_x_mm; %#ok<AGROW>
    ancho_y_mm(end+1,1) = partes(i).ancho_y_mm; %#ok<AGROW>

    masa_g(end+1,1) = partes(i).masa_g; %#ok<AGROW>
    material(end+1,1) = partes(i).material; %#ok<AGROW>

    detectada(end+1,1) = partes(i).detectada; %#ok<AGROW>
    num_puntos(end+1,1) = partes(i).num_puntos; %#ok<AGROW>

    notas(end+1,1) = partes(i).notas; %#ok<AGROW>
end

T = table(nombre, tipo, metodo, x_mm, y_mm, z_mm, ...
          area_mm2, largo_x_mm, ancho_y_mm, ...
          masa_g, material, detectada, num_puntos, notas);

end