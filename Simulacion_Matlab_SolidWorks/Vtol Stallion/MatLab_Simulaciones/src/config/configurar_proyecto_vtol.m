function cfgProyecto = configurar_proyecto_vtol(rootProyecto)
%CONFIGURAR_PROYECTO_VTOL Define y crea carpetas del proyecto VTOL.

if nargin < 1 || isempty(rootProyecto)
    rootProyecto = pwd;
end

cfgProyecto.root = rootProyecto;

cfgProyecto.cad = fullfile(rootProyecto, 'cad');

% Nueva organizacion DXF
cfgProyecto.cadGeneralDXF = fullfile(cfgProyecto.cad, 'general_dxf');
cfgProyecto.cadEstructuraDXF = fullfile(cfgProyecto.cad, 'estructura_dxf');
cfgProyecto.cadComponentesDXF = fullfile(cfgProyecto.cad, 'componentes_dxf');
cfgProyecto.cadPiezas3D = fullfile(cfgProyecto.cad, 'Piezas3D');

cfgProyecto.src = fullfile(rootProyecto, 'src');

cfgProyecto.config = fullfile(cfgProyecto.src, 'config');
cfgProyecto.CAD_2D = fullfile(cfgProyecto.src, 'CAD_2D');
cfgProyecto.geometria = fullfile(cfgProyecto.src, 'geometria');
cfgProyecto.masa_CG = fullfile(cfgProyecto.src, 'masa_CG');
cfgProyecto.aero = fullfile(cfgProyecto.src, 'aero');
cfgProyecto.propulsion = fullfile(cfgProyecto.src, 'propulsion');
cfgProyecto.visualizacion = fullfile(cfgProyecto.src, 'visualizacion');
cfgProyecto.simulador = fullfile(cfgProyecto.src, 'simulador');
cfgProyecto.exportacion = fullfile(cfgProyecto.src, 'exportacion');

cfgProyecto.resultados = fullfile(rootProyecto, 'resultados');
cfgProyecto.resultadosDatos = fullfile(cfgProyecto.resultados, 'datos_procesados');
cfgProyecto.resultadosFiguras = fullfile(cfgProyecto.resultados, 'figuras');

cfgProyecto.tests = fullfile(rootProyecto, 'tests');
cfgProyecto.simulink = fullfile(rootProyecto, 'simulink');

carpetas = {
    cfgProyecto.cad
    cfgProyecto.cadGeneralDXF
    cfgProyecto.cadEstructuraDXF
    cfgProyecto.cadComponentesDXF
    cfgProyecto.cadPiezas3D
    cfgProyecto.src
    cfgProyecto.config
    cfgProyecto.CAD_2D
    cfgProyecto.geometria
    cfgProyecto.masa_CG
    cfgProyecto.aero
    cfgProyecto.propulsion
    cfgProyecto.visualizacion
    cfgProyecto.simulador
    cfgProyecto.exportacion
    cfgProyecto.resultados
    cfgProyecto.resultadosDatos
    cfgProyecto.resultadosFiguras
    cfgProyecto.tests
    cfgProyecto.simulink
    };

for i = 1:numel(carpetas)
    if ~isfolder(carpetas{i})
        mkdir(carpetas{i});
    end
end

end