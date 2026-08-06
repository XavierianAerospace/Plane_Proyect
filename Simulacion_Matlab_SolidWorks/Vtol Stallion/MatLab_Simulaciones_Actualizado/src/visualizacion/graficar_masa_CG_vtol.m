function graficar_masa_CG_vtol(resMasaCG, geom2D, cfgDXF)
%GRAFICAR_MASA_CG_VTOL
% Grafica distribucion de masa y centro de gravedad del VTOL.
%
% Figuras:
%   1. Vista superior:
%      - y lateral en eje horizontal
%      - x longitudinal en eje vertical
%      - contorno del avion en gris
%
%   2. Vista lateral:
%      - x longitudinal en eje horizontal
%      - z vertical en eje vertical
%      - orientacion igual a la version anterior
%
%   3. Masa por categoria
%   4. Masa por tipo
%   5. Tabla externa con referencia de puntos
%
% Nota:
%   El tamano de cada bola es proporcional a masa_g.
%   Como peso = masa*g, tambien representa proporcionalmente el peso.

if nargin < 2
    geom2D = [];
end

if nargin < 3
    cfgDXF = struct();
    cfgDXF.rotarVistaPuntaArriba = true;
end

T = resMasaCG.tablaUsada;

if isempty(T) || height(T) == 0
    warning('No hay datos para graficar masa y CG.');
    return;
end

%% ============================================================
% 1. Preparar tamano de marcadores segun masa
% ============================================================

masa = T.masa_g;

if max(masa) > 0
    tam = 45 + 240 * masa / max(masa);
else
    tam = 80 * ones(height(T),1);
end

%% ============================================================
% 2. Preparar colores por tipo
% ============================================================

tipos = string(T.tipo);
tipos(ismissing(tipos) | strlength(strtrim(tipos)) == 0) = "sin_dato";

tiposUnicos = unique(tipos, 'stable');
nTipos = numel(tiposUnicos);

matColores = lines(max(nTipos, 8));

colorTipo = containers.Map('KeyType','char','ValueType','any');

for i = 1:nTipos
    colorTipo(char(tiposUnicos(i))) = matColores(i,:);
end

%% ============================================================
% 3. FIGURA 1: Vista superior con contorno gris
% ============================================================

figure('Name','Distribucion de masa y CG - vista superior', ...
       'Color','w');

hold on;
grid on;
axis equal;

% Contorno del avion en gris
if ~isempty(geom2D)
    dibujar_contorno_avion_superior(geom2D, cfgDXF);
end

handlesLegend = gobjects(nTipos,1);

for i = 1:nTipos

    tipo_i = tiposUnicos(i);
    idx = tipos == tipo_i;

    c = colorTipo(char(tipo_i));

    % Orientacion superior:
    % horizontal = y lateral
    % vertical   = x longitudinal
    handlesLegend(i) = scatter( ...
        T.y_mm(idx), ...
        T.x_mm(idx), ...
        tam(idx), ...
        'MarkerFaceColor', c, ...
        'MarkerEdgeColor', c, ...
        'MarkerFaceAlpha', 0.90, ...
        'MarkerEdgeAlpha', 0.95);
end

% CG total
hCG1 = plot(resMasaCG.CG.y_mm, resMasaCG.CG.x_mm, ...
    'kp', ...
    'MarkerSize', 16, ...
    'MarkerFaceColor', 'y', ...
    'LineWidth', 1.6);

xlabel('y lateral [mm]');
ylabel('x longitudinal desde nariz [mm]');
title('Distribucion de masa y CG - vista superior');

legend([handlesLegend; hCG1], ...
       [cellstr(tiposUnicos); {'CG total'}], ...
       'Location', 'eastoutside');

hold off;

%% ============================================================
% 4. FIGURA 2: Vista lateral con orientacion anterior
% ============================================================

figure('Name','Distribucion de masa y CG - vista lateral', ...
       'Color','w');

hold on;
grid on;
axis equal;

handlesLegend2 = gobjects(nTipos,1);

for i = 1:nTipos

    tipo_i = tiposUnicos(i);
    idx = tipos == tipo_i;

    c = colorTipo(char(tipo_i));

    % Orientacion anterior:
    % horizontal = x longitudinal
    % vertical   = z vertical
    handlesLegend2(i) = scatter( ...
        T.x_mm(idx), ...
        T.z_mm(idx), ...
        tam(idx), ...
        'MarkerFaceColor', c, ...
        'MarkerEdgeColor', c, ...
        'MarkerFaceAlpha', 0.90, ...
        'MarkerEdgeAlpha', 0.95);
end

% CG total
hCG2 = plot(resMasaCG.CG.x_mm, resMasaCG.CG.z_mm, ...
    'kp', ...
    'MarkerSize', 16, ...
    'MarkerFaceColor', 'y', ...
    'LineWidth', 1.6);

xlabel('x longitudinal desde nariz [mm]');
ylabel('z vertical [mm]');
title('Distribucion de masa y CG - vista lateral');

legend([handlesLegend2; hCG2], ...
       [cellstr(tiposUnicos); {'CG total'}], ...
       'Location', 'eastoutside');

hold off;

%% ============================================================
% 5. FIGURA 3: Masa por categoria
% ============================================================

Tcat = resMasaCG.resumen.porCategoria;

if ~isempty(Tcat) && height(Tcat) > 0

    figure('Name','Masa por categoria','Color','w');

    bar(Tcat.masa_g);
    grid on;

    xticks(1:height(Tcat));
    xticklabels(cellstr(string(Tcat.categoria)));
    xtickangle(25);

    ylabel('Masa [g]');
    title('Masa por categoria');
end

%% ============================================================
% 6. FIGURA 4: Masa por tipo
% ============================================================

Ttipo = resMasaCG.resumen.porTipo;

if ~isempty(Ttipo) && height(Ttipo) > 0

    figure('Name','Masa por tipo','Color','w');

    bar(Ttipo.masa_g);
    grid on;

    xticks(1:height(Ttipo));
    xticklabels(cellstr(string(Ttipo.tipo)));
    xtickangle(25);

    ylabel('Masa [g]');
    title('Masa por tipo');
end

%% ============================================================
% 7. FIGURA 5: Tabla externa de referencia
% ============================================================

Tinfo = table;

Tinfo.id = (1:height(T))';
Tinfo.categoria = string(T.categoria);
Tinfo.tipo = string(T.tipo);
Tinfo.nombre = string(T.nombre);
Tinfo.x_mm = T.x_mm;
Tinfo.y_mm = T.y_mm;
Tinfo.z_mm = T.z_mm;
Tinfo.masa_g = T.masa_g;
Tinfo.tamano_bola = tam;
Tinfo.color_rgb = strings(height(T),1);

for i = 1:height(T)
    c = colorTipo(char(tipos(i)));
    Tinfo.color_rgb(i) = sprintf('[%.2f %.2f %.2f]', c(1), c(2), c(3));
end

fprintf('\n============================================\n');
fprintf(' TABLA DE REFERENCIA PARA GRAFICAS MASA-CG\n');
fprintf('============================================\n');
disp(Tinfo);

figTabla = figure('Name','Tabla referencia masa-CG', ...
                  'Color','w', ...
                  'Units','normalized', ...
                  'Position',[0.06 0.08 0.88 0.78]);

dataCell = convertir_tabla_a_cell_uitable(Tinfo);

uitable(figTabla, ...
    'Data', dataCell, ...
    'ColumnName', cellstr(string(Tinfo.Properties.VariableNames)), ...
    'Units', 'normalized', ...
    'Position', [0.01 0.01 0.98 0.98], ...
    'ColumnWidth', 'auto', ...
    'RowName', []);

end


%% ============================================================
function dibujar_contorno_avion_superior(geom2D, cfgDXF)
%DIBUJAR_CONTORNO_AVION_SUPERIOR
% Dibuja el contorno/geometria general del avion en gris para la vista superior.

colorGris = [0.65 0.65 0.65];
anchoLinea = 0.9;

% Lineas
if isfield(geom2D, 'lines')
    for k = 1:numel(geom2D.lines)

        P = [
            geom2D.lines(k).p1
            geom2D.lines(k).p2
        ];

        Pmm = transformar_superior_mm(P, cfgDXF);

        plot(Pmm(:,1), Pmm(:,2), ...
            '-', ...
            'Color', colorGris, ...
            'LineWidth', anchoLinea);
    end
end

% Polilineas
if isfield(geom2D, 'polylines')
    for k = 1:numel(geom2D.polylines)

        P = geom2D.polylines(k).points;

        if isempty(P)
            continue;
        end

        if isfield(geom2D.polylines(k), 'closed') && geom2D.polylines(k).closed
            P = [P; P(1,:)];
        end

        Pmm = transformar_superior_mm(P, cfgDXF);

        plot(Pmm(:,1), Pmm(:,2), ...
            '-', ...
            'Color', colorGris, ...
            'LineWidth', anchoLinea);
    end
end

% Arcos
if isfield(geom2D, 'arcs')
    for k = 1:numel(geom2D.arcs)

        P = geom2D.arcs(k).points;

        if isempty(P)
            continue;
        end

        Pmm = transformar_superior_mm(P, cfgDXF);

        plot(Pmm(:,1), Pmm(:,2), ...
            '-', ...
            'Color', colorGris, ...
            'LineWidth', anchoLinea);
    end
end

% Splines
if isfield(geom2D, 'splines')
    for k = 1:numel(geom2D.splines)

        P = geom2D.splines(k).points;

        if isempty(P)
            continue;
        end

        Pmm = transformar_superior_mm(P, cfgDXF);

        plot(Pmm(:,1), Pmm(:,2), ...
            '-', ...
            'Color', colorGris, ...
            'LineWidth', anchoLinea);
    end
end

% Circulos
if isfield(geom2D, 'circles')
    for k = 1:numel(geom2D.circles)

        c = geom2D.circles(k).center;
        r = geom2D.circles(k).radius;

        th = linspace(0, 2*pi, 120)';

        P = [
            c(1) + r*cos(th), ...
            c(2) + r*sin(th)
        ];

        Pmm = transformar_superior_mm(P, cfgDXF);

        plot(Pmm(:,1), Pmm(:,2), ...
            '-', ...
            'Color', colorGris, ...
            'LineWidth', anchoLinea);
    end
end

end


%% ============================================================
function Pmm = transformar_superior_mm(P, cfgDXF)
%TRANSFORMAR_SUPERIOR_MM
% Convierte puntos internos [x y] a vista superior [y x] en mm.

if isempty(P)
    Pmm = P;
    return;
end

if ~isfield(cfgDXF, 'rotarVistaPuntaArriba')
    cfgDXF.rotarVistaPuntaArriba = true;
end

if cfgDXF.rotarVistaPuntaArriba
    x = P(:,1);
    y = P(:,2);

    Pvis = [y, x];
else
    Pvis = P;
end

Pmm = 1000 * Pvis;

end


%% ============================================================
function C = convertir_tabla_a_cell_uitable(T)
%CONVERTIR_TABLA_A_CELL_UITABLE
% Convierte una tabla MATLAB a una celda compatible con uitable.

raw = table2cell(T);
C = cell(size(raw));

for i = 1:size(raw,1)
    for j = 1:size(raw,2)

        val = raw{i,j};

        if isnumeric(val)
            if isempty(val)
                C{i,j} = '';
            elseif isscalar(val)
                C{i,j} = val;
            else
                C{i,j} = mat2str(val);
            end

        elseif islogical(val)
            C{i,j} = val;

        elseif isstring(val)
            if isscalar(val)
                if ismissing(val)
                    C{i,j} = '';
                else
                    C{i,j} = char(val);
                end
            else
                C{i,j} = char(strjoin(val, ", "));
            end

        elseif ischar(val)
            C{i,j} = val;

        elseif iscategorical(val)
            C{i,j} = char(string(val));

        else
            try
                s = string(val);
                if isscalar(s)
                    if ismissing(s)
                        C{i,j} = '';
                    else
                        C{i,j} = char(s);
                    end
                else
                    C{i,j} = char(strjoin(s, ", "));
                end
            catch
                C{i,j} = '';
            end
        end
    end
end

end