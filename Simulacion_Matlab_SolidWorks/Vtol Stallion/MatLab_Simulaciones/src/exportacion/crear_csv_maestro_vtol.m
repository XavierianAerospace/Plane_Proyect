function tablaMaestra = crear_csv_maestro_vtol(resGeom2D, resEstructura2D)
%CREAR_CSV_MAESTRO_VTOL Une componentes detectados y partes estructurales.
%
% Este CSV sera editable manualmente para agregar:
%   masa_g
%   z_mm
%   material
%
% Luego MATLAB lo podra leer para calcular masa total y CG.

categoria = strings(0,1);
tipo = strings(0,1);
id_local = [];
nombre = strings(0,1);

x_mm = [];
y_mm = [];
z_mm = [];

area_mm2 = [];
largo_x_mm = [];
ancho_y_mm = [];

masa_g = [];
material = strings(0,1);
fuente_posicion = strings(0,1);
fuente_masa = strings(0,1);
notas = strings(0,1);

% ============================================================
% 1. COMPONENTES DETECTADOS
% ============================================================

Tcomp = resGeom2D.tablaComponentes;

for i = 1:height(Tcomp)

    categoria(end+1,1) = "componente"; %#ok<AGROW>
    tipo(end+1,1) = string(Tcomp.tipo(i)); %#ok<AGROW>
    id_local(end+1,1) = Tcomp.id(i); %#ok<AGROW>

    nombre(end+1,1) = string(Tcomp.tipo(i)) + " " + string(Tcomp.id(i)); %#ok<AGROW>

    x_mm(end+1,1) = Tcomp.x_mm(i); %#ok<AGROW>
    y_mm(end+1,1) = Tcomp.y_mm(i); %#ok<AGROW>
    z_mm(end+1,1) = 0; %#ok<AGROW>

    area_mm2(end+1,1) = NaN; %#ok<AGROW>
    largo_x_mm(end+1,1) = NaN; %#ok<AGROW>
    ancho_y_mm(end+1,1) = NaN; %#ok<AGROW>

    masa_g(end+1,1) = NaN; %#ok<AGROW>
    material(end+1,1) = ""; %#ok<AGROW>
    fuente_posicion(end+1,1) = "DXF_componente_detectado"; %#ok<AGROW>
    fuente_masa(end+1,1) = "manual"; %#ok<AGROW>
    notas(end+1,1) = "Completar masa_g y z_mm manualmente"; %#ok<AGROW>
end

% ============================================================
% 2. PARTES ESTRUCTURALES
% ============================================================

Tpartes = resEstructura2D.tablaPartes;

for i = 1:height(Tpartes)

    categoria(end+1,1) = "estructura"; %#ok<AGROW>
    tipo(end+1,1) = string(Tpartes.tipo(i)); %#ok<AGROW>
    id_local(end+1,1) = i; %#ok<AGROW>

    nombre(end+1,1) = string(Tpartes.nombre(i)); %#ok<AGROW>

    x_mm(end+1,1) = Tpartes.x_mm(i); %#ok<AGROW>
    y_mm(end+1,1) = Tpartes.y_mm(i); %#ok<AGROW>
    z_mm(end+1,1) = Tpartes.z_mm(i); %#ok<AGROW>

    area_mm2(end+1,1) = Tpartes.area_mm2(i); %#ok<AGROW>
    largo_x_mm(end+1,1) = Tpartes.largo_x_mm(i); %#ok<AGROW>
    ancho_y_mm(end+1,1) = Tpartes.ancho_y_mm(i); %#ok<AGROW>

    masa_g(end+1,1) = Tpartes.masa_g(i); %#ok<AGROW>
    material(end+1,1) = string(Tpartes.material(i)); %#ok<AGROW>
    fuente_posicion(end+1,1) = "DXF_region_2D"; %#ok<AGROW>
    fuente_masa(end+1,1) = "manual"; %#ok<AGROW>
    notas(end+1,1) = string(Tpartes.notas(i)); %#ok<AGROW>
end

id_global = (1:numel(nombre))';

tablaMaestra = table(id_global, categoria, tipo, id_local, nombre, ...
    x_mm, y_mm, z_mm, ...
    area_mm2, largo_x_mm, ancho_y_mm, ...
    masa_g, material, fuente_posicion, fuente_masa, notas);

end