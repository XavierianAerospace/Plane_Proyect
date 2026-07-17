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
% 15. FINALIZAR
% ============================================================

fprintf('\n============================================\n');
fprintf(' MAIN FINALIZADO CORRECTAMENTE\n');
fprintf('============================================\n\n');