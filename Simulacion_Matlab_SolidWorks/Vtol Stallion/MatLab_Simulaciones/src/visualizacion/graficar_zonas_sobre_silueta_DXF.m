function graficar_zonas_sobre_silueta_DXF(geom2D, resPartesDXF, cfgDXF)
%GRAFICAR_ZONAS_SOBRE_SILUETA_DXF
% Grafica SOLO las piezas DXF separadas.
%
% Version corregida:
%   - Dibuja lineas finas reales del DXF.
%   - Rellena areas cerradas con color transparente.
%   - No usa boundary para dibujar.
%   - No usa convhull para dibujar.
%   - No usa lineas gruesas.
%   - No dibuja silueta gris.
%
% Logica:
%   1. Extrae entidades reales del DXF: lineas, arcos, splines, circulos.
%   2. Une segmentos por sus extremos.
%   3. Solo rellena si logra formar un contorno cerrado real.
%   4. Dibuja encima las lineas finas del DXF.

figure('Name','Partes DXF separadas con area transparente','Color','w');
hold on;
grid on;
axis equal;

%% ============================================================
% 1. Configuracion visual
% ============================================================

centroVisual_m = calcular_centro_visual_geom(geom2D, cfgDXF);

% Mantener el giro que ya te quedo bien.
girarPartesDXF180 = true;

% FaceAlpha:
%   0.40 significa 40% opaco y 60% transparente.
alphaRelleno = 0.40;

% Lineas finas
anchoLinea = 1.4;

% Tolerancia para unir extremos de segmentos.
% 1e-3 m = 1 mm.
tolLoop_m = 1e-3;

if ~isfield(resPartesDXF, 'partes') || isempty(resPartesDXF.partes)
    title('No hay partes DXF importadas');
    xlabel('y lateral [mm]');
    ylabel('x longitudinal [mm]');
    hold off;
    return;
end

partes = resPartesDXF.partes;
colores = lines(max(numel(partes), 8));

%% ============================================================
% 2. Dibujar cada pieza
% ============================================================

for i = 1:numel(partes)

    if isfield(partes(i), 'detectada')
        if ~partes(i).detectada
            continue;
        end
    end

    colorParte = colores(i,:);

    if isfield(partes(i), 'geom2D') && ~isempty(partes(i).geom2D)

        dibujar_parte_con_relleno_real( ...
            partes(i).geom2D, ...
            cfgDXF, ...
            colorParte, ...
            alphaRelleno, ...
            anchoLinea, ...
            girarPartesDXF180, ...
            centroVisual_m, ...
            tolLoop_m);

    else
        % Respaldo sin relleno artificial
        dibujar_respaldo_linea_fina( ...
            partes(i), ...
            cfgDXF, ...
            colorParte, ...
            anchoLinea, ...
            girarPartesDXF180, ...
            centroVisual_m);
    end
end

%% ============================================================
% 3. Formato
% ============================================================

if isfield(cfgDXF,'rotarVistaPuntaArriba') && cfgDXF.rotarVistaPuntaArriba
    xlabel('y lateral [mm]');
    ylabel('x longitudinal desde nariz [mm]');
else
    xlabel('x longitudinal desde nariz [mm]');
    ylabel('y lateral [mm]');
end

title('Partes DXF separadas con area transparente');

hold off;

end


%% ============================================================
function dibujar_parte_con_relleno_real(geom, cfgDXF, colorParte, alphaRelleno, anchoLinea, girar180, centroVisual_m, tolLoop_m)
%DIBUJAR_PARTE_CON_RELLENO_REAL
% Dibuja una parte:
%   1. Rellena loops cerrados reales.
%   2. Dibuja encima las entidades reales con linea fina.

segmentos = extraer_segmentos_geom2D(geom);

if isempty(segmentos)
    return;
end

% Reconstruir loops cerrados reales desde segmentos
loops = construir_loops_cerrados(segmentos, tolLoop_m);

% 1. Rellenar areas cerradas reales
for k = 1:numel(loops)

    P = loops{k};

    if isempty(P) || size(P,1) < 3
        continue;
    end

    areaLoop = abs(polyarea(P(:,1), P(:,2)));

    % Evitar rellenos degenerados
    if areaLoop < 1e-10
        continue;
    end

    Pmm = preparar_puntos(P, cfgDXF, girar180, centroVisual_m);

    patch(Pmm(:,1), Pmm(:,2), colorParte, ...
        'FaceAlpha', alphaRelleno, ...
        'EdgeColor', 'none');
end

% 2. Dibujar lineas reales encima, finas
for k = 1:numel(segmentos)

    P = segmentos{k};

    if isempty(P) || size(P,1) < 2
        continue;
    end

    Pmm = preparar_puntos(P, cfgDXF, girar180, centroVisual_m);

    plot(Pmm(:,1), Pmm(:,2), ...
        '-', ...
        'Color', colorParte, ...
        'LineWidth', anchoLinea);
end

end


%% ============================================================
function segmentos = extraer_segmentos_geom2D(geom)
%EXTRAER_SEGMENTOS_GEOM2D Extrae segmentos ordenados de entidades reales.
%
% Cada celda de segmentos contiene un conjunto de puntos ordenados:
%   segmento{k} = [x y; x y; ...]

segmentos = {};

%% Lineas
if isfield(geom, 'lines')
    for k = 1:numel(geom.lines)

        P = [
            geom.lines(k).p1
            geom.lines(k).p2
        ];

        segmentos{end+1} = P; %#ok<AGROW>
    end
end

%% Polilineas
if isfield(geom, 'polylines')
    for k = 1:numel(geom.polylines)

        P = geom.polylines(k).points;

        if isempty(P) || size(P,1) < 2
            continue;
        end

        if isfield(geom.polylines(k), 'closed') && geom.polylines(k).closed
            if norm(P(1,:) - P(end,:)) > 1e-12
                P = [P; P(1,:)];
            end
        end

        segmentos{end+1} = P; %#ok<AGROW>
    end
end

%% Arcos
if isfield(geom, 'arcs')
    for k = 1:numel(geom.arcs)

        P = geom.arcs(k).points;

        if isempty(P) || size(P,1) < 2
            continue;
        end

        segmentos{end+1} = P; %#ok<AGROW>
    end
end

%% Splines
if isfield(geom, 'splines')
    for k = 1:numel(geom.splines)

        P = geom.splines(k).points;

        if isempty(P) || size(P,1) < 2
            continue;
        end

        segmentos{end+1} = P; %#ok<AGROW>
    end
end

%% Circulos
if isfield(geom, 'circles')
    for k = 1:numel(geom.circles)

        c = geom.circles(k).center;
        r = geom.circles(k).radius;

        th = linspace(0, 2*pi, 180)';

        P = [
            c(1) + r*cos(th), ...
            c(2) + r*sin(th)
        ];

        segmentos{end+1} = P; %#ok<AGROW>
    end
end

%% Rectangulos detectados
% Usar rectangulos solo si no hay suficientes entidades reales.
% Esto evita duplicar rectangulos que ya vienen como LINE.
if isempty(segmentos) && isfield(geom, 'rectangulos')
    for k = 1:numel(geom.rectangulos)

        if ~isfield(geom.rectangulos(k), 'vertices')
            continue;
        end

        P = geom.rectangulos(k).vertices;

        if isempty(P) || size(P,1) < 3
            continue;
        end

        if norm(P(1,:) - P(end,:)) > 1e-12
            P = [P; P(1,:)];
        end

        segmentos{end+1} = P; %#ok<AGROW>
    end
end

% Limpiar segmentos no validos
segmentosLimpios = {};

for k = 1:numel(segmentos)

    P = segmentos{k};

    if isempty(P) || size(P,1) < 2
        continue;
    end

    P = P(all(isfinite(P),2),:);

    if size(P,1) < 2
        continue;
    end

    if norm(P(1,:) - P(end,:)) < 1e-12 && size(P,1) == 2
        continue;
    end

    segmentosLimpios{end+1} = P; %#ok<AGROW>
end

segmentos = segmentosLimpios;

end


%% ============================================================
function loops = construir_loops_cerrados(segmentos, tol)
%CONSTRUIR_LOOPS_CERRADOS Une segmentos por extremos.
%
% Importante:
%   Solo crea relleno si el contorno realmente cierra.
%   No inventa contornos con boundary ni convhull.

loops = {};

n = numel(segmentos);

if n == 0
    return;
end

usado = false(n,1);

%% 1. Primero guardar segmentos que ya vienen cerrados
for i = 1:n

    P = segmentos{i};

    if isempty(P) || size(P,1) < 3
        continue;
    end

    if distancia(P(1,:), P(end,:)) <= tol
        loops{end+1} = cerrar_loop(P); %#ok<AGROW>
        usado(i) = true;
    end
end

%% 2. Construir loops conectando segmentos abiertos
for i = 1:n

    if usado(i)
        continue;
    end

    loop = segmentos{i};
    usado(i) = true;

    cambio = true;

    while cambio
        cambio = false;

        inicio = loop(1,:);
        fin = loop(end,:);

        % Intentar conectar al final
        for j = 1:n

            if usado(j)
                continue;
            end

            S = segmentos{j};

            if isempty(S) || size(S,1) < 2
                continue;
            end

            sIni = S(1,:);
            sFin = S(end,:);

            if distancia(fin, sIni) <= tol
                loop = [loop; S(2:end,:)]; %#ok<AGROW>
                usado(j) = true;
                cambio = true;
                break;

            elseif distancia(fin, sFin) <= tol
                S = flipud(S);
                loop = [loop; S(2:end,:)]; %#ok<AGROW>
                usado(j) = true;
                cambio = true;
                break;

            elseif distancia(inicio, sFin) <= tol
                loop = [S(1:end-1,:); loop]; %#ok<AGROW>
                usado(j) = true;
                cambio = true;
                break;

            elseif distancia(inicio, sIni) <= tol
                S = flipud(S);
                loop = [S(1:end-1,:); loop]; %#ok<AGROW>
                usado(j) = true;
                cambio = true;
                break;
            end
        end
    end

    % Revisar si el loop cerro
    if size(loop,1) >= 3 && distancia(loop(1,:), loop(end,:)) <= tol
        loops{end+1} = cerrar_loop(loop); %#ok<AGROW>
    end
end

end


%% ============================================================
function P = cerrar_loop(P)
%CERRAR_LOOP Asegura que el primer y ultimo punto sean iguales.

if isempty(P)
    return;
end

if norm(P(1,:) - P(end,:)) > 1e-12
    P = [P; P(1,:)];
end

end


%% ============================================================
function d = distancia(a, b)
%DISTANCIA Distancia euclidiana entre dos puntos 2D.

d = sqrt(sum((a - b).^2));

end


%% ============================================================
function dibujar_respaldo_linea_fina(parte, cfgDXF, colorParte, anchoLinea, girar180, centroVisual_m)
%DIBUJAR_RESPALDO_LINEA_FINA Respaldo sin relleno artificial.

P = zeros(0,2);

if isfield(parte, 'contorno_m') && ~isempty(parte.contorno_m)
    P = parte.contorno_m;
elseif isfield(parte, 'puntos_m') && ~isempty(parte.puntos_m)
    P = parte.puntos_m;
end

if isempty(P) || size(P,1) < 2
    return;
end

P = P(all(isfinite(P),2),:);

if isempty(P) || size(P,1) < 2
    return;
end

Pmm = preparar_puntos(P, cfgDXF, girar180, centroVisual_m);

plot(Pmm(:,1), Pmm(:,2), ...
    '-', ...
    'Color', colorParte, ...
    'LineWidth', anchoLinea);

end


%% ============================================================
function Pmm = preparar_puntos(P, cfgDXF, girar180, centroVisual_m)
%PREPARAR_PUNTOS Convierte coordenadas internas a vista en mm.

Pvis = transformar_a_vista(P, cfgDXF);

if girar180
    Pvis = rotar_180_respecto_centro(Pvis, centroVisual_m);
end

Pmm = 1000 * Pvis;

end


%% ============================================================
function Pvis = transformar_a_vista(P, cfgDXF)
%TRANSFORMAR_A_VISTA
%
% Sistema interno:
%   x = longitudinal
%   y = lateral
%
% Vista punta arriba:
%   Xvisual = y lateral
%   Yvisual = x longitudinal

if isempty(P)
    Pvis = P;
    return;
end

if ~isfield(cfgDXF, 'rotarVistaPuntaArriba')
    cfgDXF.rotarVistaPuntaArriba = false;
end

if cfgDXF.rotarVistaPuntaArriba
    x = P(:,1);
    y = P(:,2);

    Pvis = [y, x];
else
    Pvis = P;
end

end


%% ============================================================
function Pout = rotar_180_respecto_centro(Pin, centro)
%ROTAR_180_RESPECTO_CENTRO Gira puntos 180 grados alrededor de un centro.

if isempty(Pin)
    Pout = Pin;
    return;
end

Pout = 2*centro - Pin;

end


%% ============================================================
function centroVisual_m = calcular_centro_visual_geom(geom2D, cfgDXF)
%CALCULAR_CENTRO_VISUAL_GEOM Calcula centro visual usando el DXF general.

P = extraer_puntos_geom2D(geom2D);

if isempty(P)
    centroVisual_m = [0 0];
    return;
end

Pvis = transformar_a_vista(P, cfgDXF);

xmin = min(Pvis(:,1));
xmax = max(Pvis(:,1));
ymin = min(Pvis(:,2));
ymax = max(Pvis(:,2));

centroVisual_m = [
    0.5*(xmin + xmax), ...
    0.5*(ymin + ymax)
];

end


%% ============================================================
function P = extraer_puntos_geom2D(geom2D)
%EXTRAER_PUNTOS_GEOM2D Extrae puntos de la geometria general.

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
        Pc = [
            c(1) + r*cos(th), ...
            c(2) + r*sin(th)
        ];

        P = [P; Pc]; %#ok<AGROW>
    end
end

if ~isempty(P)
    P = P(all(isfinite(P),2),:);
end

end