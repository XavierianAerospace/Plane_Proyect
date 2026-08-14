function geom = analizar_DXF_avion_2D(nombreDXF, cfg)
%ANALIZAR_DXF_AVION_2D Lee un DXF 2D de SolidWorks y detecta elementos
% principales del avion: silueta, motores, servos, bateria y electronica.
%
% Uso:
%   geom = analizar_DXF_avion_2D("avion_2D.dxf");
%
% Con configuracion:
%   cfg = configuracion personalizada;
%   geom = analizar_DXF_avion_2D("avion_2D.dxf", cfg);
%
% Sistema interno:
%   x = longitudinal desde la nariz hacia la cola
%   y = lateral
%
% Visualizacion:
%   Puede rotarse para que la punta quede arriba.

if nargin < 2
    cfg = configuracion_default();
else
    cfg = completar_configuracion(cfg);
end

fprintf("\nLeyendo DXF: %s\n", nombreDXF);

raw = leer_dxf_ascii_basico(nombreDXF);
geom = transformar_dxf_a_sistema_avion(raw, cfg);

geom.rectangulos = detectar_rectangulos(geom, cfg);
geom.componentes = clasificar_componentes(geom, cfg);

if cfg.dibujar
    dibujar_resultado_DXF(geom, cfg);
end

imprimir_resumen(geom);

end


%% ============================================================
function cfg = configuracion_default()
%CONFIGURACION_DEFAULT Parametros editables para adaptar el lector DXF.

cfg.unidadesDXF = "mm";            % "mm", "cm" o "m"

% Para tu croquis actual:
% nariz arriba en SolidWorks.
% Sistema interno:
% x longitudinal = max(Y) - Y
% y lateral      = X - centro
cfg.orientacion = "nariz_maxY";

cfg.dibujar = true;
cfg.mostrarIndices = true;

% Rotacion SOLO visual para que la punta quede arriba.
% El sistema interno NO cambia.
cfg.rotarVistaPuntaArriba = true;

% Tolerancias geometricas en metros, despues de escalar
cfg.tol = 1e-4;

% Numero esperado de elementos
cfg.numMotores = 3;
cfg.numServos = 4;

% Filtros para circulos de motores
cfg.radioMotorMin = 0.004;         % [m]
cfg.radioMotorMax = 0.080;         % [m]

% Filtros para rectangulos
cfg.areaRectMin = 1e-5;            % [m^2]
cfg.areaRectMax = 0.040;           % [m^2]

% Servos: rectangulos pequeños
cfg.areaServoMax = 0.004;          % [m^2]

% Bateria/electronica: rectangulos cerca del eje central
cfg.maxAbsYCentral = 0.20;         % [m]

% Discretizacion
cfg.numPuntosArco = 40;
cfg.numPuntosSpline = 120;

end


%% ============================================================
function cfg = completar_configuracion(cfg)
%COMPLETAR_CONFIGURACION Rellena campos faltantes con valores por defecto.

def = configuracion_default();
campos = fieldnames(def);

for i = 1:numel(campos)
    campo = campos{i};
    if ~isfield(cfg, campo)
        cfg.(campo) = def.(campo);
    end
end

end


%% ============================================================
function raw = leer_dxf_ascii_basico(nombreDXF)
%LEE_DXF_ASCII_BASICO Parser sencillo y robusto para DXF ASCII.
% Lee LINE, LWPOLYLINE, POLYLINE/VERTEX, CIRCLE, ARC y SPLINE.

if ~isfile(nombreDXF)
    error("No se encontro el archivo DXF: %s", nombreDXF);
end

txt = fileread(nombreDXF);

primerosCaracteres = txt(1:min(numel(txt),300));

if contains(primerosCaracteres, "AutoCAD Binary DXF", "IgnoreCase", true)
    error("El archivo parece ser DXF binario. Exportalo desde SolidWorks como DXF ASCII.");
end

lineas = splitlines(string(txt));

% Quitar solo lineas vacias al final del archivo
while ~isempty(lineas) && strlength(strip(lineas(end))) == 0
    lineas(end) = [];
end

if mod(numel(lineas),2) ~= 0
    warning("El DXF tiene numero impar de lineas. Se ignorara la ultima linea.");
    lineas(end) = [];
end

codes = str2double(strip(lineas(1:2:end)));
vals  = strip(lineas(2:2:end));

tipos0 = upper(vals(codes == 0));

fprintf("Conteo rapido de entidades codigo 0:\n");
fprintf("  LINE:       %d\n", sum(tipos0 == "LINE"));
fprintf("  LWPOLYLINE: %d\n", sum(tipos0 == "LWPOLYLINE"));
fprintf("  POLYLINE:   %d\n", sum(tipos0 == "POLYLINE"));
fprintf("  CIRCLE:     %d\n", sum(tipos0 == "CIRCLE"));
fprintf("  ARC:        %d\n", sum(tipos0 == "ARC"));
fprintf("  SPLINE:     %d\n", sum(tipos0 == "SPLINE"));
fprintf("  INSERT:     %d\n", sum(tipos0 == "INSERT"));
fprintf("\n");

raw.lines = struct('layer',{},'p1',{},'p2',{});
raw.polylines = struct('layer',{},'points',{},'closed',{});
raw.circles = struct('layer',{},'center',{},'radius',{});
raw.arcs = struct('layer',{},'center',{},'radius',{},'a1',{},'a2',{});
raw.splines = struct('layer',{},'degree',{},'controlPoints',{}, ...
                     'fitPoints',{},'knots',{},'weights',{});

N = numel(codes);
i = 1;

while i <= N

    if codes(i) ~= 0
        i = i + 1;
        continue;
    end

    tipo = upper(strtrim(vals(i)));

    switch tipo

        case "LINE"
            [gcodes, gvals, iNext] = leer_grupo_entidad(codes, vals, i+1);

            layer = get_str(gcodes, gvals, 8, "");
            x1 = get_num_first(gcodes, gvals, 10, NaN);
            y1 = get_num_first(gcodes, gvals, 20, NaN);
            x2 = get_num_first(gcodes, gvals, 11, NaN);
            y2 = get_num_first(gcodes, gvals, 21, NaN);

            if all(isfinite([x1 y1 x2 y2]))
                raw.lines(end+1) = struct( ...
                    'layer', layer, ...
                    'p1', [x1 y1], ...
                    'p2', [x2 y2]);
            end

            i = iNext;

        case "LWPOLYLINE"
            [gcodes, gvals, iNext] = leer_grupo_entidad(codes, vals, i+1);

            layer = get_str(gcodes, gvals, 8, "");
            flags = get_num_first(gcodes, gvals, 70, 0);
            closed = bitand(round(flags),1) == 1;

            pts = extraer_vertices_lwpolyline(gcodes, gvals);

            if size(pts,1) >= 2
                raw.polylines(end+1) = struct( ...
                    'layer', layer, ...
                    'points', pts, ...
                    'closed', closed);
            end

            i = iNext;

        case "POLYLINE"
            [poly, iNext] = leer_polyline_clasica(codes, vals, i);

            if size(poly.points,1) >= 2
                raw.polylines(end+1) = poly;
            end

            i = iNext;

        case "CIRCLE"
            [gcodes, gvals, iNext] = leer_grupo_entidad(codes, vals, i+1);

            layer = get_str(gcodes, gvals, 8, "");
            cx = get_num_first(gcodes, gvals, 10, NaN);
            cy = get_num_first(gcodes, gvals, 20, NaN);
            r  = get_num_first(gcodes, gvals, 40, NaN);

            if all(isfinite([cx cy r])) && r > 0
                raw.circles(end+1) = struct( ...
                    'layer', layer, ...
                    'center', [cx cy], ...
                    'radius', r);
            end

            i = iNext;

        case "ARC"
            [gcodes, gvals, iNext] = leer_grupo_entidad(codes, vals, i+1);

            layer = get_str(gcodes, gvals, 8, "");
            cx = get_num_first(gcodes, gvals, 10, NaN);
            cy = get_num_first(gcodes, gvals, 20, NaN);
            r  = get_num_first(gcodes, gvals, 40, NaN);
            a1 = get_num_first(gcodes, gvals, 50, NaN);
            a2 = get_num_first(gcodes, gvals, 51, NaN);

            if all(isfinite([cx cy r a1 a2])) && r > 0
                raw.arcs(end+1) = struct( ...
                    'layer', layer, ...
                    'center', [cx cy], ...
                    'radius', r, ...
                    'a1', a1, ...
                    'a2', a2);
            end

            i = iNext;

        case "SPLINE"
            [gcodes, gvals, iNext] = leer_grupo_entidad(codes, vals, i+1);

            layer = get_str(gcodes, gvals, 8, "");
            degree = get_num_first(gcodes, gvals, 71, 3);

            controlPoints = extraer_puntos_repetidos(gcodes, gvals, 10, 20);
            fitPoints     = extraer_puntos_repetidos(gcodes, gvals, 11, 21);
            knots         = extraer_valores_repetidos(gcodes, gvals, 40);
            weights       = extraer_valores_repetidos(gcodes, gvals, 41);

            if size(controlPoints,1) >= 2 || size(fitPoints,1) >= 2
                raw.splines(end+1) = struct( ...
                    'layer', layer, ...
                    'degree', degree, ...
                    'controlPoints', controlPoints, ...
                    'fitPoints', fitPoints, ...
                    'knots', knots, ...
                    'weights', weights);
            end

            i = iNext;

        otherwise
            i = i + 1;
    end
end

fprintf("Entidades leidas:\n");
fprintf("  Lineas:      %d\n", numel(raw.lines));
fprintf("  Polilineas:  %d\n", numel(raw.polylines));
fprintf("  Circulos:    %d\n", numel(raw.circles));
fprintf("  Arcos:       %d\n", numel(raw.arcs));
fprintf("  Splines:     %d\n", numel(raw.splines));

end


%% ============================================================
function [gcodes, gvals, iNext] = leer_grupo_entidad(codes, vals, iStart)
% Lee hasta encontrar el siguiente codigo 0.

N = numel(codes);
iEnd = iStart;

while iEnd <= N && codes(iEnd) ~= 0
    iEnd = iEnd + 1;
end

gcodes = codes(iStart:iEnd-1);
gvals  = vals(iStart:iEnd-1);
iNext  = iEnd;

end


%% ============================================================
function poly = leer_polyline_clasica(codes, vals, iStart)
% Lee POLYLINE clasica con VERTEX hasta SEQEND.

[gcodes, gvals, iNext] = leer_grupo_entidad(codes, vals, iStart+1);

layer = get_str(gcodes, gvals, 8, "");
flags = get_num_first(gcodes, gvals, 70, 0);
closed = bitand(round(flags),1) == 1;

pts = [];

N = numel(codes);
i = iNext;

while i <= N

    if codes(i) ~= 0
        i = i + 1;
        continue;
    end

    tipo = upper(strtrim(vals(i)));

    if tipo == "SEQEND"
        i = i + 1;
        break;

    elseif tipo == "VERTEX"
        [vcodes, vvals, iNextVertex] = leer_grupo_entidad(codes, vals, i+1);

        x = get_num_first(vcodes, vvals, 10, NaN);
        y = get_num_first(vcodes, vvals, 20, NaN);

        if all(isfinite([x y]))
            pts(end+1,:) = [x y]; %#ok<AGROW>
        end

        i = iNextVertex;

    else
        i = i + 1;
    end
end

poly = struct('layer', layer, 'points', pts, 'closed', closed);
iNext = i;

end


%% ============================================================
function pts = extraer_vertices_lwpolyline(gcodes, gvals)
% Extrae vertices 10/20 de una LWPOLYLINE.

pts = [];
i = 1;

while i <= numel(gcodes)

    if gcodes(i) == 10
        x = str2double(gvals(i));
        y = NaN;

        j = i + 1;
        while j <= numel(gcodes)
            if gcodes(j) == 20
                y = str2double(gvals(j));
                break;
            elseif gcodes(j) == 10
                break;
            end
            j = j + 1;
        end

        if isfinite(x) && isfinite(y)
            pts(end+1,:) = [x y]; %#ok<AGROW>
        end
    end

    i = i + 1;
end

end


%% ============================================================
function pts = extraer_puntos_repetidos(gcodes, gvals, codeX, codeY)
% Extrae puntos repetidos de una entidad DXF.

pts = [];
i = 1;

while i <= numel(gcodes)

    if gcodes(i) == codeX
        x = str2double(gvals(i));
        y = NaN;

        j = i + 1;

        while j <= numel(gcodes)
            if gcodes(j) == codeY
                y = str2double(gvals(j));
                break;
            elseif gcodes(j) == codeX
                break;
            end
            j = j + 1;
        end

        if isfinite(x) && isfinite(y)
            pts(end+1,:) = [x y]; %#ok<AGROW>
        end
    end

    i = i + 1;
end

end


%% ============================================================
function valsNum = extraer_valores_repetidos(gcodes, gvals, code)
% Extrae todos los valores numericos de un codigo DXF.

idx = find(gcodes == code);
valsNum = zeros(numel(idx),1);

for i = 1:numel(idx)
    valsNum(i) = str2double(gvals(idx(i)));
end

valsNum = valsNum(isfinite(valsNum));

end


%% ============================================================
function val = get_num_first(gcodes, gvals, code, defaultVal)
% Devuelve el primer valor numerico asociado a un codigo DXF.

idx = find(gcodes == code, 1, 'first');

if isempty(idx)
    val = defaultVal;
else
    val = str2double(gvals(idx));

    if ~isfinite(val)
        val = defaultVal;
    end
end

end


%% ============================================================
function val = get_str(gcodes, gvals, code, defaultVal)
% Devuelve el primer valor string asociado a un codigo DXF.

idx = find(gcodes == code, 1, 'first');

if isempty(idx)
    val = defaultVal;
else
    val = char(gvals(idx));
end

end


%% ============================================================
function geom = transformar_dxf_a_sistema_avion(raw, cfg)
% Convierte coordenadas DXF al sistema interno del avion:
% x = longitudinal desde nariz hacia cola
% y = lateral

escala = obtener_escala(cfg.unidadesDXF);

pts = recolectar_puntos_raw(raw, cfg) * escala;

if isempty(pts)
    error("No se encontraron puntos utiles dentro del DXF.");
end

% Usar bbox de referencia si existe.
% Esto es clave cuando se importan DXF separados:
% FUSELAJE.dxf, ALA_IZQ_FIJA.dxf, etc.
% Todos se mapean con el bbox del VTOL_GENERAL.
if isfield(cfg, 'bboxReferencia') && ~isempty(cfg.bboxReferencia)
    bbox = cfg.bboxReferencia;
else
    bbox.minX = min(pts(:,1));
    bbox.maxX = max(pts(:,1));
    bbox.minY = min(pts(:,2));
    bbox.maxY = max(pts(:,2));
    bbox.centroX = 0.5*(bbox.minX + bbox.maxX);
    bbox.centroY = 0.5*(bbox.minY + bbox.maxY);
end

geom.lines = struct('layer',{},'p1',{},'p2',{});
geom.polylines = struct('layer',{},'points',{},'closed',{});
geom.circles = struct('layer',{},'center',{},'radius',{});
geom.arcs = struct('layer',{},'points',{});
geom.splines = struct('layer',{},'points',{});

for i = 1:numel(raw.lines)
    p1 = mapear_puntos(raw.lines(i).p1 * escala, bbox, cfg);
    p2 = mapear_puntos(raw.lines(i).p2 * escala, bbox, cfg);

    geom.lines(end+1) = struct( ...
        'layer', raw.lines(i).layer, ...
        'p1', p1, ...
        'p2', p2);
end

for i = 1:numel(raw.polylines)
    P = mapear_puntos(raw.polylines(i).points * escala, bbox, cfg);

    geom.polylines(end+1) = struct( ...
        'layer', raw.polylines(i).layer, ...
        'points', P, ...
        'closed', raw.polylines(i).closed);
end

for i = 1:numel(raw.circles)
    c = mapear_puntos(raw.circles(i).center * escala, bbox, cfg);

    geom.circles(end+1) = struct( ...
        'layer', raw.circles(i).layer, ...
        'center', c, ...
        'radius', raw.circles(i).radius * escala);
end

for i = 1:numel(raw.arcs)
    Praw = discretizar_arco(raw.arcs(i), cfg) * escala;
    P = mapear_puntos(Praw, bbox, cfg);

    geom.arcs(end+1) = struct( ...
        'layer', raw.arcs(i).layer, ...
        'points', P);
end

for i = 1:numel(raw.splines)
    Praw = discretizar_spline(raw.splines(i), cfg) * escala;
    P = mapear_puntos(Praw, bbox, cfg);

    if size(P,1) >= 2
        geom.splines(end+1) = struct( ...
            'layer', raw.splines(i).layer, ...
            'points', P);
    end
end

geom.bbox = bbox;
geom.cfg = cfg;

end


%% ============================================================
function escala = obtener_escala(unidades)

switch lower(string(unidades))
    case "m"
        escala = 1.0;
    case "cm"
        escala = 0.01;
    case "mm"
        escala = 0.001;
    otherwise
        error("Unidad no reconocida. Usa 'mm', 'cm' o 'm'.");
end

end


%% ============================================================
function P = recolectar_puntos_raw(raw, cfg)

P = [];

for i = 1:numel(raw.lines)
    P(end+1,:) = raw.lines(i).p1; %#ok<AGROW>
    P(end+1,:) = raw.lines(i).p2; %#ok<AGROW>
end

for i = 1:numel(raw.polylines)
    P = [P; raw.polylines(i).points]; %#ok<AGROW>
end

for i = 1:numel(raw.circles)
    c = raw.circles(i).center;
    r = raw.circles(i).radius;

    P = [P; ...
        c + [ r  0]; ...
        c + [-r  0]; ...
        c + [ 0  r]; ...
        c + [ 0 -r]]; %#ok<AGROW>
end

for i = 1:numel(raw.arcs)
    P = [P; discretizar_arco(raw.arcs(i), cfg)]; %#ok<AGROW>
end

for i = 1:numel(raw.splines)
    P = [P; discretizar_spline(raw.splines(i), cfg)]; %#ok<AGROW>
end

end


%% ============================================================
function P = mapear_puntos(Pin, bbox, cfg)

X = Pin(:,1);
Y = Pin(:,2);

switch string(cfg.orientacion)

    case "nariz_maxY"
        x = bbox.maxY - Y;
        y = X - bbox.centroX;

    case "nariz_minY"
        x = Y - bbox.minY;
        y = X - bbox.centroX;

    case "nariz_minX"
        x = X - bbox.minX;
        y = Y - bbox.centroY;

    case "nariz_maxX"
        x = bbox.maxX - X;
        y = Y - bbox.centroY;

    otherwise
        error("Orientacion no reconocida.");
end

P = [x y];

end


%% ============================================================
function P = discretizar_arco(arc, cfg)

a1 = arc.a1;
a2 = arc.a2;

if a2 < a1
    a2 = a2 + 360;
end

theta = linspace(deg2rad(a1), deg2rad(a2), cfg.numPuntosArco);

cx = arc.center(1);
cy = arc.center(2);
r  = arc.radius;

P = [cx + r*cos(theta(:)), cy + r*sin(theta(:))];

end


%% ============================================================
function P = discretizar_spline(splineEnt, cfg)
% Convierte una entidad SPLINE en puntos para dibujar.
% Prioridad:
% 1. Fit points si existen.
% 2. B-spline/NURBS con puntos de control.
% 3. Polilinea de respaldo con puntos de control.

nPts = cfg.numPuntosSpline;

% Caso 1: fit points
if size(splineEnt.fitPoints,1) >= 2

    FP = splineEnt.fitPoints;

    t = linspace(0,1,size(FP,1));
    tq = linspace(0,1,nPts);

    if size(FP,1) >= 4
        xq = spline(t, FP(:,1), tq);
        yq = spline(t, FP(:,2), tq);
    else
        xq = interp1(t, FP(:,1), tq, 'linear');
        yq = interp1(t, FP(:,2), tq, 'linear');
    end

    P = [xq(:), yq(:)];
    return;
end

% Caso 2: puntos de control
CP = splineEnt.controlPoints;

if size(CP,1) < 2
    P = zeros(0,2);
    return;
end

degree = round(splineEnt.degree);

if ~isfinite(degree) || degree < 1
    degree = min(3, size(CP,1)-1);
end

degree = min(degree, size(CP,1)-1);

knots = splineEnt.knots(:);
weights = splineEnt.weights(:);

try
    P = evaluar_bspline_2D(CP, degree, knots, weights, nPts);
catch
    % Respaldo: unir puntos de control
    t = linspace(0,1,size(CP,1));
    tq = linspace(0,1,nPts);

    xq = interp1(t, CP(:,1), tq, 'linear');
    yq = interp1(t, CP(:,2), tq, 'linear');

    P = [xq(:), yq(:)];
end

end


%% ============================================================
function P = evaluar_bspline_2D(CP, p, U, W, nPts)
% Evalua una curva B-spline/NURBS 2D.

nCtrl = size(CP,1);

if isempty(W) || numel(W) ~= nCtrl
    W = ones(nCtrl,1);
end

% Si no hay knots validos, crear vector abierto uniforme
if isempty(U) || numel(U) ~= nCtrl + p + 1
    nInner = nCtrl - p - 1;

    if nInner > 0
        inner = (1:nInner) / (nInner + 1);
    else
        inner = [];
    end

    U = [zeros(1,p+1), inner, ones(1,p+1)];
end

U = U(:)';

uStart = U(p+1);
uEnd   = U(end-p);

if uEnd <= uStart
    uStart = min(U);
    uEnd = max(U);
end

uVals = linspace(uStart, uEnd, nPts);

P = zeros(nPts,2);

for k = 1:nPts
    u = uVals(k);

    if k == nPts
        u = uEnd - eps;
    end

    N = zeros(nCtrl,1);

    for i = 1:nCtrl
        N(i) = basis_bspline(i-1, p, u, U);
    end

    NW = N .* W;
    den = sum(NW);

    if abs(den) < eps
        P(k,:) = CP(min(k,nCtrl),:);
    else
        P(k,:) = (NW' * CP) / den;
    end
end

end


%% ============================================================
function val = basis_bspline(i, p, u, U)
% Funcion base B-spline, algoritmo Cox-de Boor.
% i en base 0.

if p == 0
    if U(i+1) <= u && u < U(i+2)
        val = 1;
    else
        val = 0;
    end
    return;
end

den1 = U(i+p+1) - U(i+1);
den2 = U(i+p+2) - U(i+2);

term1 = 0;
term2 = 0;

if abs(den1) > eps
    term1 = ((u - U(i+1)) / den1) * basis_bspline(i, p-1, u, U);
end

if abs(den2) > eps
    term2 = ((U(i+p+2) - u) / den2) * basis_bspline(i+1, p-1, u, U);
end

val = term1 + term2;

end


%% ============================================================
function rects = detectar_rectangulos(geom, cfg)
% Detecta rectangulos desde polilineas cerradas y desde grupos de lineas.

rects_poly = detectar_rectangulos_polilineas(geom, cfg);
rects_line = detectar_rectangulos_lineas(geom, cfg);

rects = [rects_poly, rects_line];
rects = eliminar_rectangulos_duplicados(rects, cfg);

for i = 1:numel(rects)
    rects(i).id = i;
end

fprintf("Rectangulos detectados: %d\n", numel(rects));

end


%% ============================================================
function rects = detectar_rectangulos_polilineas(geom, cfg)

rects = struct('id',{},'layer',{},'center',{},'vertices',{}, ...
               'area',{},'width',{},'height',{},'source',{});

for i = 1:numel(geom.polylines)

    P = geom.polylines(i).points;

    if geom.polylines(i).closed
        Pcheck = P;
    else
        if size(P,1) >= 2 && norm(P(1,:) - P(end,:)) < cfg.tol
            Pcheck = P(1:end-1,:);
        else
            continue;
        end
    end

    Pcheck = quitar_vertices_repetidos(Pcheck, cfg.tol);

    [ok, r] = crear_rectangulo_desde_vertices(Pcheck, cfg);

    if ok
        r.layer = geom.polylines(i).layer;
        r.source = "polyline";
        rects(end+1) = r; %#ok<AGROW>
    end
end

end


%% ============================================================
function rects = detectar_rectangulos_lineas(geom, cfg)
% Detecta rectangulos formados por 4 lineas horizontales/verticales.
% Funciona bien para rectangulos alineados.

rects = struct('id',{},'layer',{},'center',{},'vertices',{}, ...
               'area',{},'width',{},'height',{},'source',{});

L = geom.lines;
tol = max(cfg.tol, 5e-4);

H = struct('x1',{},'x2',{},'y',{},'layer',{});
V = struct('x',{},'y1',{},'y2',{},'layer',{});

for i = 1:numel(L)
    p1 = L(i).p1;
    p2 = L(i).p2;

    dx = p2(1) - p1(1);
    dy = p2(2) - p1(2);

    if abs(dy) < tol && abs(dx) > tol
        x1 = min(p1(1), p2(1));
        x2 = max(p1(1), p2(1));
        y  = 0.5*(p1(2) + p2(2));

        H(end+1).x1 = x1; %#ok<AGROW>
        H(end).x2 = x2;
        H(end).y = y;
        H(end).layer = L(i).layer;

    elseif abs(dx) < tol && abs(dy) > tol
        y1 = min(p1(2), p2(2));
        y2 = max(p1(2), p2(2));
        x  = 0.5*(p1(1) + p2(1));

        V(end+1).x = x; %#ok<AGROW>
        V(end).y1 = y1;
        V(end).y2 = y2;
        V(end).layer = L(i).layer;
    end
end

for a = 1:numel(H)-1
    for b = a+1:numel(H)

        y1 = min(H(a).y, H(b).y);
        y2 = max(H(a).y, H(b).y);

        if abs(y2 - y1) < tol
            continue;
        end

        x1a = H(a).x1;
        x2a = H(a).x2;
        x1b = H(b).x1;
        x2b = H(b).x2;

        if abs(x1a - x1b) > tol || abs(x2a - x2b) > tol
            continue;
        end

        x1 = 0.5*(x1a + x1b);
        x2 = 0.5*(x2a + x2b);

        hayV1 = existe_vertical(V, x1, y1, y2, tol);
        hayV2 = existe_vertical(V, x2, y1, y2, tol);

        if hayV1 && hayV2
            P = [x1 y1; x2 y1; x2 y2; x1 y2];

            [ok, r] = crear_rectangulo_desde_vertices(P, cfg);

            if ok
                r.layer = H(a).layer;
                r.source = "lines";
                rects(end+1) = r; %#ok<AGROW>
            end
        end
    end
end

end


%% ============================================================
function ok = existe_vertical(V, x, y1, y2, tol)

ok = false;

for i = 1:numel(V)
    if abs(V(i).x - x) < tol && ...
       abs(V(i).y1 - y1) < tol && ...
       abs(V(i).y2 - y2) < tol
        ok = true;
        return;
    end
end

end


%% ============================================================
function Pout = quitar_vertices_repetidos(P, tol)

Pout = [];

for i = 1:size(P,1)
    if isempty(Pout)
        Pout = P(i,:);
    else
        if norm(P(i,:) - Pout(end,:)) > tol
            Pout(end+1,:) = P(i,:); %#ok<AGROW>
        end
    end
end

if size(Pout,1) > 1 && norm(Pout(1,:) - Pout(end,:)) < tol
    Pout(end,:) = [];
end

end


%% ============================================================
function [ok, rect] = crear_rectangulo_desde_vertices(P, cfg)

ok = false;

rect = struct('id',[], 'layer',"", 'center',[NaN NaN], ...
              'vertices',[], 'area',NaN, 'width',NaN, ...
              'height',NaN, 'source',"");

if size(P,1) ~= 4
    return;
end

c = mean(P,1);
ang = atan2(P(:,2)-c(2), P(:,1)-c(1));
[~, ord] = sort(ang);
Q = P(ord,:);

v = diff([Q; Q(1,:)],1,1);
len = sqrt(sum(v.^2,2));

if any(len < cfg.tol)
    return;
end

cos12 = abs(dot(v(1,:),v(2,:))/(len(1)*len(2)));
cos23 = abs(dot(v(2,:),v(3,:))/(len(2)*len(3)));

if cos12 > 0.30 || cos23 > 0.30
    return;
end

area = polyarea(Q(:,1), Q(:,2));
width = max(Q(:,1)) - min(Q(:,1));
height = max(Q(:,2)) - min(Q(:,2));

if area < cfg.areaRectMin || area > cfg.areaRectMax
    return;
end

ok = true;
rect.center = c;
rect.vertices = Q;
rect.area = area;
rect.width = width;
rect.height = height;

end


%% ============================================================
function rects2 = eliminar_rectangulos_duplicados(rects, cfg)

rects2 = struct('id',{},'layer',{},'center',{},'vertices',{}, ...
                'area',{},'width',{},'height',{},'source',{});

for i = 1:numel(rects)

    duplicado = false;

    for j = 1:numel(rects2)
        dc = norm(rects(i).center - rects2(j).center);
        da = abs(rects(i).area - rects2(j).area);

        if dc < 5*cfg.tol && da < 0.10*max(rects(i).area, rects2(j).area)
            duplicado = true;
            break;
        end
    end

    if ~duplicado
        rects2(end+1) = rects(i); %#ok<AGROW>
    end
end

end


%% ============================================================
function componentes = clasificar_componentes(geom, cfg)
%CLASIFICAR_COMPONENTES Clasifica motores, servos, bateria y electronica.
%
% Sistema interno:
%   x = longitudinal desde nariz hacia cola
%   y = lateral
%
% Si cfg.idsServosManual existe y no esta vacio, se usa esa seleccion.
% Eso permite corregir directamente rectangulos que ya fueron detectados
% pero no clasificados automaticamente.

componentes.motores = struct([]);
componentes.servos = struct([]);
componentes.bateria = struct([]);
componentes.electronica = struct([]);
componentes.otrosRectangulos = struct([]);

%% ============================================================
% 1. MOTORES
% ============================================================

circs = geom.circles;
idxMotores = [];

for i = 1:numel(circs)
    r = circs(i).radius;

    if r >= cfg.radioMotorMin && r <= cfg.radioMotorMax
        idxMotores(end+1) = i; %#ok<AGROW>
    end
end

if isempty(idxMotores) && ~isempty(circs)
    idxMotores = 1:numel(circs);
end

if ~isempty(idxMotores)
    radios = [circs(idxMotores).radius];
    [~, ord] = sort(radios, 'descend');

    idxMotores = idxMotores(ord);
    idxMotores = idxMotores(1:min(cfg.numMotores, numel(idxMotores)));

    componentes.motores = circs(idxMotores);
end


%% ============================================================
% 2. RECTANGULOS
% ============================================================

rects = geom.rectangulos;

if isempty(rects)
    return;
end

idsRect = [rects.id];

%% ============================================================
% 3. BATERIA Y ELECTRONICA MANUAL, SI EXISTE
% ============================================================

if isfield(cfg,'idBateriaManual') && ~isempty(cfg.idBateriaManual)
    idx = find(idsRect == cfg.idBateriaManual, 1);

    if ~isempty(idx)
        componentes.bateria = rects(idx);
    end
end

if isfield(cfg,'idElectronicaManual') && ~isempty(cfg.idElectronicaManual)
    idx = find(idsRect == cfg.idElectronicaManual, 1);

    if ~isempty(idx)
        componentes.electronica = rects(idx);
    end
end


%% ============================================================
% 4. BATERIA Y ELECTRONICA AUTOMATICAS
% ============================================================

if isempty(componentes.bateria) || isempty(componentes.electronica)

    centros = vertcat(rects.center);
    areas = [rects.area];

    idxValidos = find(areas >= cfg.areaRectMin & areas <= cfg.areaRectMax);

    if ~isempty(idxValidos)

        rectValidos = rects(idxValidos);
        centrosValidos = vertcat(rectValidos.center);
        areasValidas = [rectValidos.area];

        % Rectangulos cerca del eje central lateral y = 0
        idxCentralesLocal = find(abs(centrosValidos(:,2)) <= cfg.maxAbsYCentral);

        rectCentrales = rectValidos(idxCentralesLocal);

        if ~isempty(rectCentrales)

            centrosCentrales = vertcat(rectCentrales.center);
            areasCentrales = [rectCentrales.area];

            % Evitar detalles demasiado pequeños
            areaMediana = median(areasCentrales);
            idxTamanoOK = find(areasCentrales >= 0.40 * areaMediana);

            if isempty(idxTamanoOK)
                idxTamanoOK = 1:numel(rectCentrales);
            end

            rectCandidatos = rectCentrales(idxTamanoOK);
            centrosCand = vertcat(rectCandidatos.center);

            % Menor x = mas cerca de la nariz
            [~, ordX] = sort(centrosCand(:,1), 'ascend');

            if isempty(componentes.bateria)
                componentes.bateria = rectCandidatos(ordX(1));
            end

            if isempty(componentes.electronica) && numel(ordX) >= 2
                componentes.electronica = rectCandidatos(ordX(2));
            end
        end
    end
end


%% ============================================================
% 5. SERVOS MANUALES, SI EXISTEN
% ============================================================

if isfield(cfg,'idsServosManual') && ~isempty(cfg.idsServosManual)

    idsServos = cfg.idsServosManual(:)';
    idxServos = [];

    for k = 1:numel(idsServos)
        idx = find(idsRect == idsServos(k), 1);

        if ~isempty(idx)
            idxServos(end+1) = idx; %#ok<AGROW>
        else
            warning('No se encontro rectangulo con ID %d para servo manual.', idsServos(k));
        end
    end

    if ~isempty(idxServos)
        componentes.servos = rects(idxServos);
    end

else

    %% ============================================================
    % 6. SERVOS AUTOMATICOS MEJORADOS
    % ============================================================

    idxExcluir = [];

    if ~isempty(componentes.bateria)
        idxExcluir(end+1) = componentes.bateria.id; %#ok<AGROW>
    end

    if ~isempty(componentes.electronica)
        idxExcluir(end+1) = componentes.electronica.id; %#ok<AGROW>
    end

    idxServoCand = [];

    areas = [rects.area];

    % Tomar rectangulos pequeños, pero con margen para no dejar por fuera
    % servos que hayan salido un poco mas grandes por el DXF.
    areaServoMaxAuto = max(cfg.areaServoMax, prctile(areas, 45));

    for i = 1:numel(rects)

        if ismember(rects(i).id, idxExcluir)
            continue;
        end

        if rects(i).area >= cfg.areaRectMin && rects(i).area <= areaServoMaxAuto
            idxServoCand(end+1) = i; %#ok<AGROW>
        end
    end

    if ~isempty(idxServoCand)

        score = zeros(numel(idxServoCand),1);

        for k = 1:numel(idxServoCand)
            r = rects(idxServoCand(k));

            % Priorizar:
            % 1. rectangulos alejados del eje central lateral,
            % 2. rectangulos pequeños,
            % 3. pero sin castigar demasiado los servos inferiores.
            score(k) = 10*abs(r.center(2)) - 2*r.area;
        end

        [~, ord] = sort(score, 'descend');

        idxServoCand = idxServoCand(ord);
        idxServoCand = idxServoCand(1:min(cfg.numServos, numel(idxServoCand)));

        componentes.servos = rects(idxServoCand);
    end
end


%% ============================================================
% 7. OTROS RECTANGULOS
% ============================================================

idxUsados = [];

if ~isempty(componentes.bateria)
    idxUsados(end+1) = componentes.bateria.id; %#ok<AGROW>
end

if ~isempty(componentes.electronica)
    idxUsados(end+1) = componentes.electronica.id; %#ok<AGROW>
end

if ~isempty(componentes.servos)
    idxUsados = [idxUsados, [componentes.servos.id]];
end

otros = [];

for i = 1:numel(rects)
    if ~ismember(rects(i).id, idxUsados)
        otros = [otros, rects(i)]; %#ok<AGROW>
    end
end

componentes.otrosRectangulos = otros;

end

%% ============================================================
function dibujar_resultado_DXF(geom, cfg)

figure('Name','DXF avion 2D - deteccion inicial','Color','w');
hold on;
grid on;
axis equal;

% Lineas sueltas
for i = 1:numel(geom.lines)
    p1 = aplicar_rotacion_vista(geom.lines(i).p1, cfg);
    p2 = aplicar_rotacion_vista(geom.lines(i).p2, cfg);

    plot([p1(1) p2(1)], [p1(2) p2(2)], ...
        '-', 'Color',[0.55 0.55 0.55], 'LineWidth',0.8);
end

% Polilineas
for i = 1:numel(geom.polylines)
    P = geom.polylines(i).points;

    if geom.polylines(i).closed
        Pplot = [P; P(1,:)];
    else
        Pplot = P;
    end

    Pplot = aplicar_rotacion_vista(Pplot, cfg);

    plot(Pplot(:,1), Pplot(:,2), ...
        '-', 'Color',[0.25 0.25 0.25], 'LineWidth',1.2);
end

% Arcos
for i = 1:numel(geom.arcs)
    P = aplicar_rotacion_vista(geom.arcs(i).points, cfg);
    plot(P(:,1), P(:,2), '-', 'Color',[0.25 0.25 0.25], 'LineWidth',1.0);
end

% Splines
for i = 1:numel(geom.splines)
    P = aplicar_rotacion_vista(geom.splines(i).points, cfg);
    plot(P(:,1), P(:,2), '-', 'Color',[0.25 0.25 0.25], 'LineWidth',1.2);
end

% Circulos no clasificados
for i = 1:numel(geom.circles)
    dibujar_circulo(geom.circles(i).center, geom.circles(i).radius, ...
        [0.70 0.70 0.70], 0.8, false, cfg);
end

% Rectangulos detectados no clasificados
for i = 1:numel(geom.rectangulos)
    dibujar_rectangulo(geom.rectangulos(i), [0.75 0.75 0.75], 1.0, false, cfg);
end

comp = geom.componentes;

% Motores
for i = 1:numel(comp.motores)
    dibujar_circulo(comp.motores(i).center, comp.motores(i).radius, ...
        [0.10 0.55 0.55], 2.0, true, cfg);
end

% Servos
for i = 1:numel(comp.servos)
    dibujar_rectangulo(comp.servos(i), [0.55 0.75 1.00], 2.0, true, cfg);
end

% Bateria
if ~isempty(comp.bateria)
    dibujar_rectangulo(comp.bateria, [1.00 0.85 0.10], 2.2, true, cfg);
end

% Electronica
if ~isempty(comp.electronica)
    dibujar_rectangulo(comp.electronica, [0.65 0.50 0.20], 2.2, true, cfg);
end

if cfg.rotarVistaPuntaArriba
    xlabel('y [m] lateral');
    ylabel('x [m] longitudinal desde nariz');
else
    xlabel('x [m] longitudinal desde nariz');
    ylabel('y [m] lateral');
end

title('Geometria 2D importada desde DXF y elementos detectados');

hGeom  = plot(nan,nan,'-','Color',[0.25 0.25 0.25]);
hMotor = plot(nan,nan,'o','MarkerFaceColor',[0.10 0.55 0.55],'MarkerEdgeColor','k');
hServo = plot(nan,nan,'s','MarkerFaceColor',[0.55 0.75 1.00],'MarkerEdgeColor','k');
hBat   = plot(nan,nan,'s','MarkerFaceColor',[1.00 0.85 0.10],'MarkerEdgeColor','k');
hElec  = plot(nan,nan,'s','MarkerFaceColor',[0.65 0.50 0.20],'MarkerEdgeColor','k');

legend([hGeom hMotor hServo hBat hElec], ...
    {'Geometria DXF','Motor','Servo','Bateria','Electronica'}, ...
    'Location','bestoutside');

if cfg.mostrarIndices
    for i = 1:numel(geom.rectangulos)
        c = aplicar_rotacion_vista(geom.rectangulos(i).center, cfg);

        text(c(1), c(2), sprintf('%d', geom.rectangulos(i).id), ...
            'FontSize',8, 'Color','r', 'FontWeight','bold', ...
            'HorizontalAlignment','center');
    end
end

hold off;

end


%% ============================================================
function Pout = aplicar_rotacion_vista(Pin, cfg)
% Rota solo la visualizacion.
% Internamente sigue siendo:
% x = longitudinal
% y = lateral
%
% Vista rotada:
% punta arriba -> eje vertical visual representa x longitudinal.

if cfg.rotarVistaPuntaArriba
    x = Pin(:,1);
    y = Pin(:,2);

    % Rotacion visual 90 grados a la izquierda:
    % Xvisual = -y
    % Yvisual =  x
    Pout = [-y, x];
else
    Pout = Pin;
end

end


%% ============================================================
function dibujar_circulo(c, r, color, lw, fillOn, cfg)

theta = linspace(0, 2*pi, 80);
P = [c(1) + r*cos(theta(:)), c(2) + r*sin(theta(:))];

P = aplicar_rotacion_vista(P, cfg);

if fillOn
    patch(P(:,1), P(:,2), color, ...
        'EdgeColor','k', ...
        'LineWidth',lw, ...
        'FaceAlpha',0.85);
else
    plot(P(:,1), P(:,2), '-', 'Color',color, 'LineWidth',lw);
end

end


%% ============================================================
function dibujar_rectangulo(rect, color, lw, fillOn, cfg)

P = rect.vertices;
P = [P; P(1,:)];

P = aplicar_rotacion_vista(P, cfg);

if fillOn
    patch(P(:,1), P(:,2), color, ...
        'EdgeColor','k', ...
        'LineWidth',lw, ...
        'FaceAlpha',0.85);
else
    plot(P(:,1), P(:,2), '-', ...
        'Color',color, ...
        'LineWidth',lw);
end

end


%% ============================================================
function imprimir_resumen(geom)

fprintf("\nResumen de deteccion:\n");

fprintf("  Motores detectados:    %d\n", numel(geom.componentes.motores));
fprintf("  Servos detectados:     %d\n", numel(geom.componentes.servos));

if isempty(geom.componentes.bateria)
    fprintf("  Bateria:               no detectada\n");
else
    c = geom.componentes.bateria.center;
    fprintf("  Bateria:               detectada en x=%.4f m, y=%.4f m\n", c(1), c(2));
end

if isempty(geom.componentes.electronica)
    fprintf("  Electronica:           no detectada\n");
else
    c = geom.componentes.electronica.center;
    fprintf("  Electronica:           detectada en x=%.4f m, y=%.4f m\n", c(1), c(2));
end

fprintf("\nNotas:\n");
fprintf("  - El sistema interno sigue siendo x longitudinal, y lateral.\n");
fprintf("  - La rotacion de punta arriba es solo visual.\n");
fprintf("  - Si algun componente queda mal clasificado, ajusta los umbrales cfg.\n\n");

end