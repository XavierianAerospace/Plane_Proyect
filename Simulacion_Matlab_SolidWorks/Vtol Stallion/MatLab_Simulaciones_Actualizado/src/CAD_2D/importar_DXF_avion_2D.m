function geom2D = importar_DXF_avion_2D(archivoDXF, cfgDXF)
%IMPORTAR_DXF_AVION_2D Importa el DXF 2D usando el lector base.
%
% Esta funcion es una capa de arquitectura.
% Por ahora llama a analizar_DXF_avion_2D, que ya funciona.
% Mas adelante podemos dividir internamente ese lector sin cambiar el main.

if ~isfile(archivoDXF)
    error('No se encontro el archivo DXF: %s', archivoDXF);
end

if exist('analizar_DXF_avion_2D', 'file') ~= 2
    error(['No se encontro analizar_DXF_avion_2D.m. ', ...
        'Debe estar en src/CAD_2D o en el path de MATLAB.']);
end

geom2D = analizar_DXF_avion_2D(archivoDXF, cfgDXF);

geom2D.archivoDXF = archivoDXF;
geom2D.unidadesInternas = "m";
geom2D.unidadesOriginalesDXF = cfgDXF.unidadesDXF;
geom2D.fechaImportacion = datetime('now');

end