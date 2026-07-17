function graficar_zonas_sobre_silueta_DXF(geom2D, resPartesDXF, cfgDXF)
%GRAFICAR_ZONAS_SOBRE_SILUETA_DXF
% Grafica la silueta general del avion y las partes importadas desde DXF.
%
% Version corregida:
%   - Sin textos dentro de la grafica.
%   - Sin nombres ni areas sobre las piezas.
%   - Las piezas DXF separadas se giran 180 grados visualmente.
%   - La informacion detallada queda en la tabla visual y en el CSV.

figure('Name','Partes DXF sobre silueta general','Color','w');
hold on;
grid on;
axis equal;

%% ============================================================
% 1. Centro visual de referencia para girar partes 180 grados
% ============================================================

centroVisual_m = calcular_centro_visual_geom(geom2D, cfgDXF);

% Esta bandera gira SOLO las areas/partes DXF separadas.
% La silueta general se deja como referencia.
girarPartesDXF180 = true;

%% ============================================================
% 2. Dibujar silueta/base general
% ============================================================

colorBase = [0.75 0.75 0.75];

dibujar_geometria_base(geom2D, cfgDXF, colorBase);

%% ============================================================
% 3. Dibujar partes DXF separadas
% ============================================================

if ~isfield(resPartesDXF, 'partes') || isempty(resPartesDXF.partes)
    title('Silueta DXF sin partes importadas');
    xlabel('y lateral [mm]');
    ylabel('x longitudinal [mm]');
    hold off;
    return;
end

partes = resPartesDXF.partes;
colores = lines(max(numel(partes), 8));

for i = 1:numel(partes)

    if isfield(partes(i), 'detectada')
        if ~partes(i).detectada
            continue;
        end
    end

    P = obtener_contorno_parte(partes(i));

    if isempty(P) || size(P,1) < 3
        continue;
    end

    % Transformar a vista normal
    Pvis = transformar_a_vista(P, cfgDXF);

    % Girar SOLO las partes DXF separadas 180 grados
    if girarPartesDXF180
        Pvis = rotar_180_respecto_centro(Pvis, centroVisual_m);
    end

    Pvis_mm = 1000 * Pvis;

    patch(Pvis_mm(:,1), Pvis_mm(:,2), colores(i,:), ...
        'FaceAlpha', 0.35, ...
        'EdgeColor', colores(i,:), ...
        'LineWidth', 1.6);
end

%% ============================================================
% 4. Formato de grafica
% ============================================================

if isfield(cfgDXF,'rotarVistaPuntaArriba') && cfgDXF.rotarVistaPuntaArriba
    xlabel('y lateral [mm]');
    ylabel('x longitudinal desde nariz [mm]');
else
    xlabel('x longitudinal desde nariz [mm]');
    ylabel('y lateral [mm]');
end

title('Partes DXF sobre silueta general');

% No poner legend ni textos internos, porque la informacion va en la tabla.
hold off;

end


%% ============================================================
function dibujar_geometria_base(geom2D, cfgDXF, colorBase)
%DIBUJAR_GEOMETRIA_BASE Dibuja lineas, arcos, splines y circulos.

% Lineas
if isfield(geom2D, 'lines')
    for i = 1:numel(geom2D.lines)

        p1 = transformar_a_vista(geom2D.lines(i).p1, cfgDXF);
        p2 = transformar_a_vista(geom2D.lines(i).p2, cfgDXF);

        p1 = 1000 * p1;
        p2 = 1000 * p2;

        plot([p1(1) p2(1)], [p1(2) p2(2)], ...
            '-', 'Color', colorBase, 'LineWidth', 0.7);
    end
end

% Polilineas
if isfield(geom2D, 'polylines')
    for i = 1:numel(geom2D.polylines)

        P = geom2D.polylines(i).points;

        if isempty(P)
            continue;
        end

        if isfield(geom2D.polylines(i), 'closed') && geom2D.polylines(i).closed
            P = [P; P(1,:)];
        end

        P = transformar_a_vista(P, cfgDXF);
        P = 1000 * P;

        plot(P(:,1), P(:,2), ...
            '-', 'Color', colorBase, 'LineWidth', 0.7);
    end
end

% Arcos
if isfield(geom2D, 'arcs')
    for i = 1:numel(geom2D.arcs)

        P = geom2D.arcs(i).points;

        if isempty(P)
            continue;
        end

        P = transformar_a_vista(P, cfgDXF);
        P = 1000 * P;

        plot(P(:,1), P(:,2), ...
            '-', 'Color', colorBase, 'LineWidth', 0.7);
    end
end

% Splines
if isfield(geom2D, 'splines')
    for i = 1:numel(geom2D.splines)

        P = geom2D.splines(i).points;

        if isempty(P)
            continue;
        end

        P = transformar_a_vista(P, cfgDXF);
        P = 1000 * P;

        plot(P(:,1), P(:,2), ...
            '-', 'Color', colorBase, 'LineWidth', 0.9);
    end
end

% Circulos
if isfield(geom2D, 'circles')
    for i = 1:numel(geom2D.circles)

        c = geom2D.circles(i).center;
        r = geom2D.circles(i).radius;

        th = linspace(0, 2*pi, 120)';
        P = [c(1) + r*cos(th), c(2) + r*sin(th)];

        P = transformar_a_vista(P, cfgDXF);
        P = 1000 * P;

        plot(P(:,1), P(:,2), ...
            '-', 'Color', colorBase, 'LineWidth', 0.7);
    end
end

end


%% ============================================================
function P = obtener_contorno_parte(parte)
%OBTENER_CONTORNO_PARTE Devuelve contorno de la parte en metros.

P = zeros(0,2);

% Caso 1: contorno ya calculado
if isfield(parte, 'contorno_m')
    if ~isempty(parte.contorno_m) && size(parte.contorno_m,1) >= 3
        P = parte.contorno_m;
        return;
    end
end

% Caso 2: calcular contorno desde puntos
if isfield(parte, 'puntos_m')
    puntos = parte.puntos_m;

    if ~isempty(puntos) && size(puntos,1) >= 3

        puntos = puntos(all(isfinite(puntos),2),:);
        puntos = unique(round(puntos/1e-6)*1e-6, 'rows');

        if size(puntos,1) >= 3
            x = puntos(:,1);
            y = puntos(:,2);

            try
                k = boundary(x, y, 0.85);
            catch
                k = convhull(x, y);
            end

            P = [x(k), y(k)];
            return;
        end
    end
end

% Caso 3: usar bounding box
if isfield(parte,'x_min_mm') && isfield(parte,'x_max_mm') && ...
   isfield(parte,'y_min_mm') && isfield(parte,'y_max_mm')

    vals = [parte.x_min_mm, parte.x_max_mm, parte.y_min_mm, parte.y_max_mm];

    if all(isfinite(vals))
        x1 = parte.x_min_mm / 1000;
        x2 = parte.x_max_mm / 1000;
        y1 = parte.y_min_mm / 1000;
        y2 = parte.y_max_mm / 1000;

        P = [
            x1 y1
            x2 y1
            x2 y2
            x1 y2
            x1 y1
        ];
    end
end

end


%% ============================================================
function Pvis = transformar_a_vista(P, cfgDXF)
%TRANSFORMAR_A_VISTA Convierte coordenadas internas a coordenadas visuales.
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
%
% Formula:
%   Pout = 2*centro - Pin

if isempty(Pin)
    Pout = Pin;
    return;
end

Pout = 2*centro - Pin;

end


%% ============================================================
function centroVisual_m = calcular_centro_visual_geom(geom2D, cfgDXF)
%CALCULAR_CENTRO_VISUAL_GEOM Calcula centro visual de la silueta general.

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

        th = linspace(0, 2*pi, 80)';
        Pc = [c(1) + r*cos(th), c(2) + r*sin(th)];

        P = [P; Pc]; %#ok<AGROW>
    end
end

if ~isempty(P)
    P = P(all(isfinite(P),2),:);
end

end