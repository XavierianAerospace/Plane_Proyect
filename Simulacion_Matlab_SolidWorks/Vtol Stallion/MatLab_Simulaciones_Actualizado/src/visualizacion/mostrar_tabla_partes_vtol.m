function mostrar_tabla_partes_vtol(tablaMaestraVTOL)
%MOSTRAR_TABLA_PARTES_VTOL
% Muestra una tabla en consola y en figura con:
%   categoria, tipo, nombre, posicion, area, masa y material.
%
% Corrige el problema de uitable con strings y <missing> convirtiendo
% todo a celdas numericas o char.

if nargin < 1 || isempty(tablaMaestraVTOL) || height(tablaMaestraVTOL) == 0
    warning('No hay tabla maestra para mostrar.');
    return;
end

T = tablaMaestraVTOL;

% Filtrar solo partes detectadas si existe esa columna
if ismember("detectada", string(T.Properties.VariableNames))
    try
        T = T(logical(T.detectada), :);
    catch
        % Si no se puede filtrar, se deja completa.
    end
end

colsDeseadas = ["categoria","tipo","nombre","x_mm","y_mm","z_mm", ...
                "area_mm2","masa_g","material"];

colsFinales = colsDeseadas(ismember(colsDeseadas, string(T.Properties.VariableNames)));

Tview = T(:, colsFinales);

% Ordenar para que quede más limpio
varsSort = intersect(["categoria","tipo","nombre"], string(Tview.Properties.VariableNames), 'stable');

if ~isempty(varsSort)
    Tview = sortrows(Tview, varsSort);
end

fprintf('\n============================================\n');
fprintf(' TABLA RESUMEN DE PARTES VTOL\n');
fprintf('============================================\n');
disp(Tview);

% Convertir tabla a formato compatible con uitable
dataCell = tabla_a_cell_para_uitable(Tview);

fig = figure('Name','Tabla resumen partes VTOL', ...
             'Color','w', ...
             'Units','normalized', ...
             'Position',[0.08 0.08 0.84 0.78]);

uitable(fig, ...
    'Data', dataCell, ...
    'ColumnName', cellstr(Tview.Properties.VariableNames), ...
    'Units', 'normalized', ...
    'Position', [0.01 0.01 0.98 0.98], ...
    'ColumnWidth', 'auto', ...
    'RowName', []);

end


%% ============================================================
function C = tabla_a_cell_para_uitable(T)
%TABLA_A_CELL_PARA_UITABLE Convierte una tabla a celdas compatibles
% con uitable: numeric, logical o char.

Craw = table2cell(T);
C = cell(size(Craw));

for i = 1:size(Craw,1)
    for j = 1:size(Craw,2)

        val = Craw{i,j};

        if ismissing_val(val)
            C{i,j} = '';

        elseif isstring(val)
            if isscalar(val)
                C{i,j} = char(val);
            else
                C{i,j} = char(strjoin(val, ", "));
            end

        elseif ischar(val)
            C{i,j} = val;

        elseif isnumeric(val)
            if isempty(val)
                C{i,j} = '';
            elseif isscalar(val)
                C{i,j} = val;
            else
                C{i,j} = mat2str(val);
            end

        elseif islogical(val)
            C{i,j} = val;

        elseif iscell(val)
            try
                C{i,j} = char(string(val));
            catch
                C{i,j} = '';
            end

        elseif iscategorical(val)
            C{i,j} = char(string(val));

        elseif isdatetime(val) || isduration(val)
            C{i,j} = char(string(val));

        else
            try
                C{i,j} = char(string(val));
            catch
                C{i,j} = '';
            end
        end
    end
end

end


%% ============================================================
function tf = ismissing_val(val)
%ISMISSING_VAL Detecta missing en string/categorical/etc.

tf = false;

try
    tf = any(ismissing(val));
catch
    tf = false;
end

if numel(tf) > 1
    tf = any(tf);
end

end