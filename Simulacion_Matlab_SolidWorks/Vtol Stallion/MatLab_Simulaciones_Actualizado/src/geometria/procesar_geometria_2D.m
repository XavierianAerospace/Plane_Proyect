function resGeom2D = procesar_geometria_2D(geom2D)
%PROCESAR_GEOMETRIA_2D Extrae informacion util de la geometria 2D importada.
%
% Sistema interno:
%   x = longitudinal desde nariz hacia cola [m]
%   y = lateral [m]
%
% Salidas principales:
%   longitud total
%   envergadura/ancho maximo
%   posiciones de motores
%   posiciones de servos
%   posicion de bateria
%   posicion de electronica
%   tabla de componentes
%   chequeos basicos de simetria

P = extraer_puntos_geom2D(geom2D);

if isempty(P)
    error('No hay puntos disponibles en geom2D para procesar.');
end

x = P(:,1);
y = P(:,2);

resGeom2D.unidadesInternas = "m";
resGeom2D.unidadesReporte = "mm";

resGeom2D.x_min_m = min(x);
resGeom2D.x_max_m = max(x);
resGeom2D.y_min_m = min(y);
resGeom2D.y_max_m = max(y);

resGeom2D.longitud_total_m = resGeom2D.x_max_m - resGeom2D.x_min_m;
resGeom2D.ancho_total_m = resGeom2D.y_max_m - resGeom2D.y_min_m;
resGeom2D.envergadura_aprox_m = resGeom2D.ancho_total_m;

resGeom2D.x_min_mm = 1000 * resGeom2D.x_min_m;
resGeom2D.x_max_mm = 1000 * resGeom2D.x_max_m;
resGeom2D.y_min_mm = 1000 * resGeom2D.y_min_m;
resGeom2D.y_max_mm = 1000 * resGeom2D.y_max_m;

resGeom2D.longitud_total_mm = 1000 * resGeom2D.longitud_total_m;
resGeom2D.ancho_total_mm = 1000 * resGeom2D.ancho_total_m;
resGeom2D.envergadura_aprox_mm = 1000 * resGeom2D.envergadura_aprox_m;

% Componentes detectados
resGeom2D.componentes.motores_m = obtener_centros(geom2D.componentes.motores);
resGeom2D.componentes.servos_m = obtener_centros(geom2D.componentes.servos);
resGeom2D.componentes.bateria_m = obtener_centro_unico(geom2D.componentes.bateria);
resGeom2D.componentes.electronica_m = obtener_centro_unico(geom2D.componentes.electronica);

resGeom2D.componentes.motores_mm = 1000 * resGeom2D.componentes.motores_m;
resGeom2D.componentes.servos_mm = 1000 * resGeom2D.componentes.servos_m;
resGeom2D.componentes.bateria_mm = 1000 * resGeom2D.componentes.bateria_m;
resGeom2D.componentes.electronica_mm = 1000 * resGeom2D.componentes.electronica_m;

% Tabla resumen
resGeom2D.tablaComponentes = crear_tabla_componentes(resGeom2D);

% Simetria
resGeom2D.simetria.motores = evaluar_simetria_pares(resGeom2D.componentes.motores_m, "motores");
resGeom2D.simetria.servos = evaluar_simetria_pares(resGeom2D.componentes.servos_m, "servos");

end


%% ============================================================
function P = extraer_puntos_geom2D(geom2D)
%EXTRAER_PUNTOS_GEOM2D Junta todos los puntos geometricos disponibles.

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

        P = [P; ...
            c + [ r  0]; ...
            c + [-r  0]; ...
            c + [ 0  r]; ...
            c + [ 0 -r]]; %#ok<AGROW>
    end
end

if isfield(geom2D, 'rectangulos')
    for i = 1:numel(geom2D.rectangulos)
        P = [P; geom2D.rectangulos(i).vertices]; %#ok<AGROW>
    end
end

end


%% ============================================================
function C = obtener_centros(elementos)
%OBTENER_CENTROS Extrae centros de un arreglo de structs.

if isempty(elementos)
    C = zeros(0,2);
    return;
end

C = vertcat(elementos.center);

end


%% ============================================================
function c = obtener_centro_unico(elemento)
%OBTENER_CENTRO_UNICO Extrae centro de un componente unico.

if isempty(elemento)
    c = [NaN NaN];
else
    c = elemento.center;
end

end


%% ============================================================
function T = crear_tabla_componentes(resGeom2D)
%CREAR_TABLA_COMPONENTES Crea una tabla con los componentes detectados.

tipo = strings(0,1);
id = [];
x_m = [];
y_m = [];
x_mm = [];
y_mm = [];

motores = resGeom2D.componentes.motores_m;

for i = 1:size(motores,1)
    tipo(end+1,1) = "Motor"; %#ok<AGROW>
    id(end+1,1) = i; %#ok<AGROW>
    x_m(end+1,1) = motores(i,1); %#ok<AGROW>
    y_m(end+1,1) = motores(i,2); %#ok<AGROW>
    x_mm(end+1,1) = 1000*motores(i,1); %#ok<AGROW>
    y_mm(end+1,1) = 1000*motores(i,2); %#ok<AGROW>
end

servos = resGeom2D.componentes.servos_m;

for i = 1:size(servos,1)
    tipo(end+1,1) = "Servo"; %#ok<AGROW>
    id(end+1,1) = i; %#ok<AGROW>
    x_m(end+1,1) = servos(i,1); %#ok<AGROW>
    y_m(end+1,1) = servos(i,2); %#ok<AGROW>
    x_mm(end+1,1) = 1000*servos(i,1); %#ok<AGROW>
    y_mm(end+1,1) = 1000*servos(i,2); %#ok<AGROW>
end

bat = resGeom2D.componentes.bateria_m;

if all(isfinite(bat))
    tipo(end+1,1) = "Bateria"; %#ok<AGROW>
    id(end+1,1) = 1; %#ok<AGROW>
    x_m(end+1,1) = bat(1); %#ok<AGROW>
    y_m(end+1,1) = bat(2); %#ok<AGROW>
    x_mm(end+1,1) = 1000*bat(1); %#ok<AGROW>
    y_mm(end+1,1) = 1000*bat(2); %#ok<AGROW>
end

elec = resGeom2D.componentes.electronica_m;

if all(isfinite(elec))
    tipo(end+1,1) = "Electronica"; %#ok<AGROW>
    id(end+1,1) = 1; %#ok<AGROW>
    x_m(end+1,1) = elec(1); %#ok<AGROW>
    y_m(end+1,1) = elec(2); %#ok<AGROW>
    x_mm(end+1,1) = 1000*elec(1); %#ok<AGROW>
    y_mm(end+1,1) = 1000*elec(2); %#ok<AGROW>
end

T = table(tipo, id, x_m, y_m, x_mm, y_mm);

end


%% ============================================================
function sim = evaluar_simetria_pares(P, nombre)
%EVALUAR_SIMETRIA_PARES Evalua simetria lateral simple.

sim.nombre = nombre;
sim.disponible = false;
sim.error_x_m = NaN;
sim.error_y_m = NaN;
sim.error_x_mm = NaN;
sim.error_y_mm = NaN;
sim.mensaje = "No hay suficientes puntos para evaluar simetria.";

if size(P,1) < 2
    return;
end

% Buscar el punto positivo y negativo mas alejados lateralmente
idxPos = find(P(:,2) > 0);
idxNeg = find(P(:,2) < 0);

if isempty(idxPos) || isempty(idxNeg)
    sim.mensaje = "No se encontraron puntos a ambos lados del eje central.";
    return;
end

[~, iPosLocal] = max(abs(P(idxPos,2)));
[~, iNegLocal] = max(abs(P(idxNeg,2)));

iPos = idxPos(iPosLocal);
iNeg = idxNeg(iNegLocal);

pPos = P(iPos,:);
pNeg = P(iNeg,:);

sim.disponible = true;
sim.punto_positivo_m = pPos;
sim.punto_negativo_m = pNeg;

sim.error_x_m = abs(pPos(1) - pNeg(1));
sim.error_y_m = abs(pPos(2) + pNeg(2));

sim.error_x_mm = 1000 * sim.error_x_m;
sim.error_y_mm = 1000 * sim.error_y_m;

if sim.error_x_mm < 1 && sim.error_y_mm < 1
    sim.mensaje = "Simetria lateral buena.";
elseif sim.error_x_mm < 5 && sim.error_y_mm < 5
    sim.mensaje = "Simetria lateral aceptable.";
else
    sim.mensaje = "Revisar simetria lateral.";
end

end