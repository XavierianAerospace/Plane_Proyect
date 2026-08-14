%% Main_Vtol.m
% MAIN PRINCIPAL DEL PROYECTO VTOL
%
% Flujo actual:
%   1. Configurar carpetas del proyecto
%   2. Importar DXF general del avion
%   3. Procesar geometria general 2D
%   4. Importar partes separadas desde DXF
%      - estructura_dxf
%      - componentes_dxf
%   5. Crear tabla maestra base para CSV
%   6. Recuperar datos manuales si ya existe CSV anterior
%   7. Graficar partes sobre silueta general
%   8. Mostrar tabla resumen de partes
%   9. Guardar resultados, CSV y figuras
%
% Flujo futuro:
%   10. Completar masa_g, z_mm y material en el CSV
%   11. Leer CSV completado
%   12. Calcular masa total y centro de gravedad
%   13. Calcular area alar, MAC y rango de CG
%   14. Preparar parametros para Simulink

clear;
clc;
close all;

fprintf('\n============================================\n');
fprintf(' PROYECTO VTOL - MAIN GENERAL\n');
fprintf('============================================\n\n');

%% ============================================================
% 1. CONFIGURAR PROYECTO
% ============================================================

rootProyecto = fileparts(mfilename('fullpath'));

if isempty(rootProyecto)
    rootProyecto = pwd;
end

srcPath = fullfile(rootProyecto, 'src');

if isfolder(srcPath)
    addpath(genpath(srcPath));
end

cfgProyecto = configurar_proyecto_vtol(rootProyecto);

% Volver a agregar src por si se creo o actualizo en configurar_proyecto_vtol
addpath(genpath(cfgProyecto.src));

fprintf('Carpeta raiz del proyecto:\n%s\n\n', cfgProyecto.root);

fprintf('Carpetas CAD usadas:\n');
fprintf('  General:     %s\n', cfgProyecto.cadGeneralDXF);
fprintf('  Estructura:  %s\n', cfgProyecto.cadEstructuraDXF);
fprintf('  Componentes: %s\n\n', cfgProyecto.cadComponentesDXF);

%% ============================================================
% 2. CONFIGURAR LECTOR DXF
% ============================================================

cfgDXF = configurar_DXF_vtol();

% Proyecto actual:
% 6 servos:
%   SERVO_ALA_DER
%   SERVO_ALA_IZQ
%   SERVO_COLA_DER
%   SERVO_COLA_IZQ
%   SERVO_MOTOR_DER
%   SERVO_MOTOR_IZQ
cfgDXF.numServos = 6;

% Seguridad: si no existe la unidad de DXF separados, crearla.
% En tu ultimo ajuste, los DXF separados estaban funcionando con "m".
if ~isfield(cfgDXF, 'unidadesDXFPartes') || isempty(cfgDXF.unidadesDXFPartes)
    cfgDXF.unidadesDXFPartes = "m";
end

fprintf('Configuracion DXF cargada.\n');
fprintf('  Unidades DXF general:   %s\n', string(cfgDXF.unidadesDXF));
fprintf('  Unidades DXF partes:    %s\n', string(cfgDXF.unidadesDXFPartes));
fprintf('  Orientacion:            %s\n', string(cfgDXF.orientacion));
fprintf('  Numero de servos:       %d\n\n', cfgDXF.numServos);

%% ============================================================
% 3. SELECCIONAR DXF GENERAL
% ============================================================

archivoDXFGeneral = seleccionar_archivo_DXF(cfgProyecto);

fprintf('Archivo DXF general seleccionado:\n%s\n\n', archivoDXFGeneral);

%% ============================================================
% 4. IMPORTAR DXF GENERAL
% ============================================================

fprintf('Importando geometria general 2D desde DXF...\n');

geom2D = importar_DXF_avion_2D(archivoDXFGeneral, cfgDXF);

fprintf('Importacion del DXF general finalizada.\n\n');

if ~isfield(geom2D, 'bbox') || isempty(geom2D.bbox)
    error(['geom2D no contiene bbox. ', ...
           'Revisa analizar_DXF_avion_2D.m porque el bbox es necesario ', ...
           'para importar correctamente los DXF separados.']);
end

%% ============================================================
% 5. PROCESAR GEOMETRIA GENERAL 2D
% ============================================================

fprintf('Procesando geometria general 2D...\n');

resGeom2D = procesar_geometria_2D(geom2D);

fprintf('Procesamiento de geometria general finalizado.\n\n');

%% ============================================================
% 6. IMPORTAR PARTES SEPARADAS DESDE DXF
% ============================================================

fprintf('Importando partes separadas desde carpetas DXF...\n');

resPartesDXF = importar_partes_separadas_DXF( ...
    cfgProyecto, ...
    cfgDXF, ...
    geom2D.bbox);

fprintf('Partes separadas importadas.\n\n');

%% ============================================================
% 7. CREAR TABLA MAESTRA PARA CSV
% ============================================================

fprintf('Creando tabla maestra VTOL desde DXF separados...\n');

tablaMaestraVTOL = resPartesDXF.tablaCSV;

% Archivo CSV principal
archivoCSV = fullfile( ...
    cfgProyecto.resultadosDatos, ...
    'componentes_vtol_base.csv');

% Si ya existe un CSV anterior con masa/z/material llenados manualmente,
% recuperarlos para no perder esa informacion.
tablaMaestraVTOL = actualizar_tabla_maestra_desde_csv( ...
    tablaMaestraVTOL, ...
    archivoCSV);

fprintf('Tabla maestra creada.\n\n');

%% ============================================================
% 8. MOSTRAR RESUMEN DE GEOMETRIA GENERAL
% ============================================================

imprimir_resumen_geometria_2D(resGeom2D);

%% ============================================================
% 9. MOSTRAR RESUMEN DE PARTES DXF SEPARADAS
% ============================================================

fprintf('\n============================================\n');
fprintf(' RESUMEN PARTES DXF SEPARADAS\n');
fprintf('============================================\n');

fprintf('Partes importadas: %d\n', height(tablaMaestraVTOL));

if height(tablaMaestraVTOL) > 0

    columnasVista = {'id_global','categoria','tipo','nombre', ...
                     'x_mm','y_mm','z_mm','area_mm2','masa_g','material'};

    columnasDisponibles = columnasVista(ismember( ...
        columnasVista, ...
        tablaMaestraVTOL.Properties.VariableNames));

    fprintf('\nVista previa de tabla maestra:\n');
    disp(tablaMaestraVTOL(:, columnasDisponibles));
end

fprintf('============================================\n\n');

%% ============================================================
% 10. GRAFICA: PARTES SOBRE SILUETA DXF
% ============================================================

fprintf('Generando grafica de partes sobre silueta DXF...\n');

graficar_zonas_sobre_silueta_DXF( ...
    geom2D, ...
    resPartesDXF, ...
    cfgDXF);

fprintf('Grafica de partes generada.\n\n');

%% ============================================================
% 11. TABLA VISUAL DE PARTES
% ============================================================

fprintf('Generando tabla visual de partes VTOL...\n');

mostrar_tabla_partes_vtol(tablaMaestraVTOL);

fprintf('Tabla visual generada.\n\n');

%% ============================================================
% 12. CALCULAR MASA Y CENTRO DE GRAVEDAD
% ============================================================

fprintf('Calculando masa total y centro de gravedad...\n');

resMasaCG = calcular_masa_CG_vtol(tablaMaestraVTOL);

imprimir_resumen_masa_CG_vtol(resMasaCG);

graficar_masa_CG_vtol(resMasaCG, geom2D, cfgDXF);

fprintf('Calculo de masa y CG finalizado.\n\n');

%% ============================================================
% 12.5 SIMULACION DE VUELO Y POTENCIA REQUERIDA
% ============================================================

fprintf('Simulando despegue/transicion VTOL y potencia requerida...\n');

cfgSim = struct();
cfgSim.m = resMasaCG.masa.total_kg;   % usa la masa REAL calculada desde el CSV
% Los demas parametros (S, T_max_total, diametroHelice_m, numMotores, etc.)
% usan los valores por defecto de simular_transicion_vtol.m.
% Edita ahi el diametro real de tus helices para que la potencia sea exacta.

resSim = simular_transicion_vtol(cfgSim);

graficar_simulacion_vtol(resSim);

fprintf('Simulacion de vuelo finalizada.\n\n');

%% ============================================================
% 12. GUARDAR RESULTADOS MATLAB
% ============================================================

archivoSalidaMAT = fullfile( ...
    cfgProyecto.resultadosDatos, ...
    'geom2D_procesada.mat');

save(archivoSalidaMAT, ...
    'geom2D', ...
    'resGeom2D', ...
    'resPartesDXF', ...
    'tablaMaestraVTOL', ...
    'resMasaCG', ...
    'resSim', ...
    'cfgDXF', ...
    'cfgProyecto');

fprintf('Datos MATLAB guardados en:\n%s\n\n', archivoSalidaMAT);




%% ============================================================
% 13. GUARDAR CSV MAESTRO
% ============================================================

writetable(tablaMaestraVTOL, archivoCSV);

fprintf('CSV maestro guardado en:\n%s\n\n', archivoCSV);

fprintf('Columnas que debes completar manualmente en el CSV:\n');
fprintf('  masa_g\n');
fprintf('  z_mm\n');
fprintf('  material\n\n');

%% ============================================================
% 14. GUARDAR FIGURAS
% ============================================================

fprintf('Guardando figuras abiertas...\n');

guardar_figuras_abiertas_vtol( ...
    cfgProyecto.resultadosFiguras, ...
    "VTOL_DXF");

fprintf('\nFiguras guardadas en:\n%s\n', cfgProyecto.resultadosFiguras);



%% ============================================================
% 15 VERIFICACION DE MOTORES PARA EL DESPEGUE
% ============================================================

fprintf('\n============================================\n');
fprintf(' VERIFICACION DE MOTORES VTOL\n');
fprintf('============================================\n');

%% --- 1. Datos del avion ---
if exist('resMasaCG', 'var') && isfield(resMasaCG, 'masa')
    masa_kg = resMasaCG.masa.total_kg;
else
    masa_kg = 2.5;   % <-- EDITA si no tienes resMasaCG en el workspace
end

g_local = 9.81;
numMotores = 3;                 % tricoptero VTOL
W_N = masa_kg * g_local;

fprintf('Masa total: %.3f kg  ->  Peso total: %.2f N\n', masa_kg, W_N);

%% --- 2. Margen de control (TWR) ---
TWR_objetivo = 2.0;   % <-- ajustable

T_total_objetivo_N = TWR_objetivo * W_N;
T_por_motor_objetivo_N = T_total_objetivo_N / numMotores;
T_por_motor_objetivo_g = T_por_motor_objetivo_N / g_local * 1000;

fprintf('Empuje objetivo por motor (TWR=%.1f): %.2f N (%.0f g)\n', ...
    TWR_objetivo, T_por_motor_objetivo_N, T_por_motor_objetivo_g);

%% --- 3. Potencia ideal requerida (disco actuador) ---
rho = 1.225;
D_helice_m = 7 * 0.0254;   % helice de 7"
A_helice = pi * (D_helice_m/2)^2;

P_ideal_por_motor = (T_por_motor_objetivo_N^1.5) / sqrt(2*rho*A_helice);

eta_helice = 0.75;
eta_motor  = 0.85;
P_real_por_motor = P_ideal_por_motor / (eta_helice * eta_motor);

fprintf('Potencia electrica estimada por motor: %.1f W\n', P_real_por_motor);

%% --- 4. Especificaciones de motores candidatos ---
motores = struct( ...
    'nombre',        {'Emax ECO II 2807 1300KV', 'T-Motor F90 2806.5 1300KV'}, ...
    'voltaje_min_S',  {3,                          5}, ...
    'voltaje_max_S',  {6,                          6}, ...
    'P_max_W',        {870,                        1059}, ...
    'T_max_g',        {NaN,                        2360} ...
    );

bateria_S = 4;   % <-- tu bateria: 4S

%% --- 4.b Estimacion del F90 a 4S (fuera de su rango oficial 5-6S) ---
% Leyes de afinidad de helice (a helice fija): RPM ~ V, T ~ RPM^2, P ~ RPM^3
V_ref_S = 6;
factor_rpm = bateria_S / V_ref_S;

idx_F90 = find(strcmp({motores.nombre}, 'T-Motor F90 2806.5 1300KV'));

T_max_g_4S_est = motores(idx_F90).T_max_g * factor_rpm^2;
P_max_W_4S_est = motores(idx_F90).P_max_W * factor_rpm^3;

fprintf('\nEstimacion F90 a %dS (fuera de su rango oficial %d-%dS):\n', ...
    bateria_S, motores(idx_F90).voltaje_min_S, motores(idx_F90).voltaje_max_S);
fprintf('  Empuje maximo estimado:   %.0f g  (dato oficial a %dS: %.0f g)\n', ...
    T_max_g_4S_est, V_ref_S, motores(idx_F90).T_max_g);
fprintf('  Potencia maxima estimada: %.0f W  (dato oficial a %dS: %.0f W)\n', ...
    P_max_W_4S_est, V_ref_S, motores(idx_F90).P_max_W);

if T_max_g_4S_est >= T_por_motor_objetivo_g
    fprintf('  -> Aun asi ALCANZARIA el empuje objetivo (%.0f g).\n', T_por_motor_objetivo_g);
else
    fprintf('  -> NO alcanzaria el empuje objetivo (%.0f g) a %dS.\n', ...
        T_por_motor_objetivo_g, bateria_S);
end

%% --- 5. Evaluacion general de ambos motores ---
for k = 1:numel(motores)
    mtr = motores(k);
    fprintf('\n--- %s ---\n', mtr.nombre);

    if bateria_S < mtr.voltaje_min_S || bateria_S > mtr.voltaje_max_S
        fprintf('  [!] Fabricante recomienda %d-%dS; tu bateria es %dS (rendira menos que el dato de placa).\n', ...
            mtr.voltaje_min_S, mtr.voltaje_max_S, bateria_S);
    else
        fprintf('  Voltaje %dS dentro del rango recomendado.\n', bateria_S);
    end

    if mtr.P_max_W >= P_real_por_motor
        fprintf('  Potencia: OK -> max %.0f W vs %.0f W requeridos\n', mtr.P_max_W, P_real_por_motor);
    else
        fprintf('  Potencia: INSUFICIENTE -> max %.0f W < %.0f W requeridos\n', mtr.P_max_W, P_real_por_motor);
    end
end


%% ============================================================
% 12.10 RESUMEN COMPARATIVO FINAL: EMAX vs F90 (ambos evaluados a 4S)
% ============================================================
% Bloque AUTOCONTENIDO: no depende de secciones anteriores, se puede
% pegar solo. Reemplaza las secciones 12.6-12.9 anteriores si quieres
% dejar Main_Vtol.m mas limpio (esta las resume todas).

fprintf('\n============================================\n');
fprintf(' RESUMEN COMPARATIVO FINAL: EMAX vs T-MOTOR F90 (a 4S)\n');
fprintf('============================================\n');

%% --- 1. Datos del avion ---
if exist('resMasaCG', 'var') && isfield(resMasaCG, 'masa')
    masa_kg = resMasaCG.masa.total_kg;
else
    masa_kg = 2.5;   % <-- EDITA si no tienes resMasaCG en el workspace
end

g_local = 9.81;
numMotores = 3;
bateria_S = 4;
W_N = masa_kg * g_local;

fprintf('Masa total: %.3f kg -> Peso total: %.2f N\n', masa_kg, W_N);

%% --- 2. Dos niveles de exigencia: minimo (TWR=1) y con margen (TWR=2) ---
rho = 1.225;
D_helice_m = 7 * 0.0254;
A_helice = pi * (D_helice_m/2)^2;
eta_helice = 0.75; eta_motor = 0.85;
eta_total = eta_helice * eta_motor;

TWR_casos = [1.0, 2.0];
T_obj_g   = zeros(size(TWR_casos));
P_req_W   = zeros(size(TWR_casos));

for i = 1:numel(TWR_casos)
    T_obj_N = TWR_casos(i) * W_N / numMotores;
    T_obj_g(i) = T_obj_N / g_local * 1000;
    P_ideal = (T_obj_N^1.5) / sqrt(2*rho*A_helice);
    P_req_W(i) = P_ideal / eta_total;
end

fprintf('\nRequerido por motor:\n');
fprintf('  TWR=1.0 (minimo para sostenerse): %.0f g  /  %.0f W\n', T_obj_g(1), P_req_W(1));
fprintf('  TWR=2.0 (con margen de control):  %.0f g  /  %.0f W\n', T_obj_g(2), P_req_W(2));

%% --- 3. Datos de los motores ---
% F90: dato REAL a 6S, escalado a 4S por leyes de afinidad (T~V^2, P~V^3)
T_F90_6S_g = 2360; P_F90_6S_W = 1059;
factor = bateria_S / 6;
T_F90_4S_g = T_F90_6S_g * factor^2;
P_F90_4S_W = P_F90_6S_W * factor^3;

% Emax: dato REAL de potencia a 4S; empuje ESTIMADO por comparacion
% de eficiencia (g/W) con el F90 (motor de clase similar)
P_Emax_4S_W = 870;
eficiencia_F90_gW = T_F90_6S_g / P_F90_6S_W;   % 2.23 g/W, dato real
T_Emax_4S_g = eficiencia_F90_gW * P_Emax_4S_W; % estimado

motores = struct( ...
    'nombre',      {'Emax ECO II 2807 1300KV', 'T-Motor F90 2806.5 1300KV'}, ...
    'T_4S_g',      {T_Emax_4S_g,               T_F90_4S_g}, ...
    'P_4S_W',      {P_Emax_4S_W,               P_F90_4S_W}, ...
    'T_es_estimado', {true,                    true}, ...   % ninguno tiene dato REAL de empuje a 4S
    'rango_S',     {'3-6S (dentro de rango)',  '5-6S (FUERA de rango en 4S)'} ...
    );

%% --- 4. Tabla comparativa ---
fprintf('\n%-28s %10s %10s %14s %14s\n', 'Motor', 'T@4S(g)', 'P@4S(W)', 'TWR real(min)', 'TWR real(obj)');
fprintf('%s\n', repmat('-', 1, 80));
for k = 1:numel(motores)
    m_ = motores(k);
    TWR_min = m_.T_4S_g / T_obj_g(1);   % vs el minimo (TWR objetivo 1.0)
    TWR_obj = m_.T_4S_g / T_obj_g(1);   % (T_obj_g(1) es la base real de "peso/3")
    fprintf('%-28s %10.0f %10.0f %14.2f %14.2f\n', ...
        m_.nombre, m_.T_4S_g, m_.P_4S_W, TWR_min, TWR_obj);
    fprintf('   %s | Empuje: %s\n', m_.rango_S, ...
        ternary(m_.T_es_estimado, 'ESTIMADO (no medido)', 'dato real de banco'));
end

fprintf('\n%s\n', repmat('-', 1, 80));

%% --- 5. Corriente aproximada por ESC ---
V_nominal = bateria_S * 3.7;
fprintf('\nCorriente aproximada por motor a plena potencia (4S, %.1fV nominal):\n', V_nominal);
for k = 1:numel(motores)
    I_A = motores(k).P_4S_W / V_nominal;
    fprintf('  %-28s %.1f A  (tus ESC: 45A / 51A -> %s)\n', ...
        motores(k).nombre, I_A, ternary(I_A < 45, 'con margen', 'AL LIMITE, revisar'));
end

%% --- Funcion auxiliar (definir al final del script o en otro .m) ---
function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end




%% ============================================================
% 12.11 PERFIL DE DESCARGA TEORICO - EMAX (autonomia y punto de aterrizaje)
% ============================================================
% Bloque AUTOCONTENIDO. Calcula cuanto dura la bateria en vuelo sostenido
% (hover/crucero, no a maximo throttle) y en que minuto conviene bajar.


fprintf('\n============================================\n');
fprintf(' PERFIL DE DESCARGA TEORICO - EMAX ECO II 2807 1300KV\n');
fprintf('============================================\n');

%% --- 1. Datos del avion y del punto de operacion ---
if exist('resMasaCG', 'var') && isfield(resMasaCG, 'masa')
   % masa_kg = resMasaCG.masa.total_kg;
else
    masa_kg = 4;   % <-- respaldo con tu ultimo valor real
end

g_local = 9.81;
numMotores = 3;
bateria_S = 4;
W_N = masa_kg * g_local;

% Punto de operacion sostenida: hover puro, TWR=1.0 (no el margen de
% maniobra de TWR=2.0, que solo se usa en rafagas cortas)
rho = 1.225;
D_helice_m = 7 * 0.0254;
A_helice = pi * (D_helice_m/2)^2;
eta_helice = 0.75; eta_motor = 0.85;
eta_total = eta_helice * eta_motor;

T_hover_N = W_N / numMotores;
P_ideal_hover = (T_hover_N^1.5) / sqrt(2*rho*A_helice);
P_real_hover_por_motor = P_ideal_hover / eta_total;
P_real_hover_total = numMotores * P_real_hover_por_motor;

fprintf('Masa: %.3f kg -> Peso: %.2f N\n', masa_kg, W_N);
fprintf('Potencia electrica en hover sostenido (3 motores): %.1f W\n', P_real_hover_total);

%% --- 2. Curva de descarga de una celda Li-ion (forma tipica) ---
SOC_pct = [100 95 90 80 70 60 50 40 30 20 10 5 0];
V_celda = [4.20 4.03 3.93 3.82 3.75 3.71 3.68 3.65 3.62 3.58 3.45 3.20 3.00];

P_pack = 3;                 % 4S3P
Q_total_Ah = 10.5;          % capacidad total del pack (dato de tu lista)
V_pack_curva = V_celda * bateria_S;

%% --- 3. Corriente de hover y autonomia ---
V_nominal_pack = bateria_S * 3.7;
I_hover_A = P_real_hover_total / V_nominal_pack;

% Umbral de aterrizaje seguro: 20% SOC (evita zona de caida abrupta de
% voltaje y proteje la vida util de las celdas Li-ion)
SOC_aterrizaje = 20;
Q_util_Ah = (100 - SOC_aterrizaje)/100 * Q_total_Ah;
t_vuelo_h = Q_util_Ah / I_hover_A;
t_vuelo_min = t_vuelo_h * 60;

% Umbral de ALERTA (avisar al piloto antes del aterrizaje obligatorio)
SOC_alerta = 30;
t_alerta_min = ((100 - SOC_alerta)/100 * Q_total_Ah / I_hover_A) * 60;

fprintf('Corriente estimada en hover: %.1f A\n', I_hover_A);
fprintf('\n>>> ALERTA de bateria baja (30%% SOC):  a los %.1f min de vuelo\n', t_alerta_min);
fprintf('>>> ATERRIZAR (20%% SOC):               a los %.1f min de vuelo\n', t_vuelo_min);
fprintf('    (nunca bajar de 3.0 V/celda = %.1f V del pack en descarga sostenida)\n', ...
    3.0 * bateria_S);

%% --- 4. Grafica del perfil de descarga ---
figure('Name', 'Perfil de Descarga - Emax Hover', 'Color', [1 1 1]);

tiempo_min = (100 - SOC_pct)/100 * (Q_total_Ah / I_hover_A) * 60;

plot(tiempo_min, V_pack_curva, 'b', 'LineWidth', 2.2); hold on;

xline(t_alerta_min, 'y--', 'LineWidth', 1.5);
xline(t_vuelo_min, 'r--', 'LineWidth', 1.8);
yline(3.5*bateria_S, 'y:', 'LineWidth', 1);
yline(3.0*bateria_S, 'r:', 'LineWidth', 1);

grid on;
xlabel('Tiempo de vuelo en hover (min)');
ylabel('Voltaje del pack 4S (V)');
title(sprintf('Descarga teorica @ %.1f A (hover sostenido, %.3f kg)', I_hover_A, masa_kg));
legend('Voltaje del pack', ...
    sprintf('Alerta bateria baja (%.1f min)', t_alerta_min), ...
    sprintf('Aterrizar (%.1f min)', t_vuelo_min), ...
    '3.5 V/celda', '3.0 V/celda', ...
    'Location', 'southwest');

xlim([0, t_vuelo_min * 1.15]);


%% ============================================================
% 15. FINALIZAR
% ============================================================

fprintf('\n============================================\n');
fprintf(' MAIN FINALIZADO CORRECTAMENTE\n');
fprintf('============================================\n\n');