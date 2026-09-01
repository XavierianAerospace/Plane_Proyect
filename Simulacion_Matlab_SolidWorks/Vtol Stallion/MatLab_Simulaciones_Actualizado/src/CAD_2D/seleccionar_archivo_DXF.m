function archivoDXF = seleccionar_archivo_DXF(cfgProyecto)
%SELECCIONAR_ARCHIVO_DXF Busca el DXF general del avion.

carpetaGeneral = cfgProyecto.cadGeneralDXF;

% Preferir VTOL_GENERAL.dxf
candidato1 = fullfile(carpetaGeneral, 'VTOL_GENERAL.dxf');
candidato2 = fullfile(carpetaGeneral, 'VTOL_GENERAL.DXF');

if isfile(candidato1)
    archivoDXF = candidato1;
    return;
elseif isfile(candidato2)
    archivoDXF = candidato2;
    return;
end

% Si no existe con ese nombre, buscar cualquier DXF en general_dxf
archivos = dir(fullfile(carpetaGeneral, '*.dxf'));

if isempty(archivos)
    archivos = dir(fullfile(carpetaGeneral, '*.DXF'));
end

if numel(archivos) == 1
    archivoDXF = fullfile(archivos(1).folder, archivos(1).name);
    return;
end

if numel(archivos) > 1
    fprintf('Se encontraron varios DXF en general_dxf:\n');

    for i = 1:numel(archivos)
        fprintf('  %d) %s\n', i, archivos(i).name);
    end

    idx = input('Selecciona el numero del DXF general: ');

    if isempty(idx) || idx < 1 || idx > numel(archivos)
        error('Seleccion DXF invalida.');
    end

    archivoDXF = fullfile(archivos(idx).folder, archivos(idx).name);
    return;
end

error('No se encontro ningun DXF general en: %s', carpetaGeneral);

end