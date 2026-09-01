function cfgDXF = configurar_DXF_vtol()
%CONFIGURAR_DXF_VTOL Configuracion del importador DXF 2D.
%
% Nota:
%   El DXF viene en mm desde SolidWorks.
%   Internamente MATLAB convierte a metros para calculos.
%   En los resumenes tambien se muestran valores en mm.

cfgDXF.unidadesDXF = "mm";
cfgDXF.unidadesInternas = "m";
cfgDXF.unidadesReporte = "mm";
cfgDXF.unidadesDXFPartes = "m";   % Cambiar a "mm" si tus DXF separados salen en mm

% Ahora el avion tiene 6 servos detectables
cfgDXF.numServos = 6;

% Para tu croquis actual:
% nariz arriba en SolidWorks.
cfgDXF.orientacion = "nariz_maxY";

% Visualizacion
cfgDXF.dibujar = true;
cfgDXF.mostrarIndices = true;
cfgDXF.rotarVistaPuntaArriba = true;

% Tolerancias
cfgDXF.tol = 1e-4;

% Elementos esperados
cfgDXF.numMotores = 3;
cfgDXF.numServos = 6;

% Filtro de motores circulares
cfgDXF.radioMotorMin = 0.004;     % [m]
cfgDXF.radioMotorMax = 0.080;     % [m]

% Filtro general de rectangulos
cfgDXF.areaRectMin = 1e-5;        % [m^2]
cfgDXF.areaRectMax = 0.040;       % [m^2]

% Servos: rectangulos pequenos
cfgDXF.areaServoMax = 0.004;      % [m^2]

% Bateria/electronica: rectangulos cerca del eje central
cfgDXF.maxAbsYCentral = 0.20;     % [m]

% Discretizacion de curvas
cfgDXF.numPuntosArco = 40;
cfgDXF.numPuntosSpline = 120;

% Clasificacion manual opcional
% Dejalo vacio para usar deteccion automatica.
% Si algun servo aparece numerado pero no pintado, pon aqui sus IDs.
cfgDXF.idsServosManual = [1 2 4 5 6 7 ];
cfgDXF.idBateriaManual = [];
cfgDXF.idElectronicaManual = [];

end