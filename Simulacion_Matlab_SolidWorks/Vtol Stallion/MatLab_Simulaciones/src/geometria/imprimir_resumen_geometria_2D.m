function imprimir_resumen_geometria_2D(resGeom2D)
%IMPRIMIR_RESUMEN_GEOMETRIA_2D Muestra resumen de geometria en consola.

fprintf('\n============================================\n');
fprintf(' RESUMEN GEOMETRIA 2D\n');
fprintf('============================================\n');

fprintf('Longitud total aproximada: %.2f mm\n', resGeom2D.longitud_total_mm);
fprintf('Ancho/envergadura aprox.:  %.2f mm\n', resGeom2D.envergadura_aprox_mm);

fprintf('\nBounding box interno:\n');
fprintf('  x min = %.2f mm\n', resGeom2D.x_min_mm);
fprintf('  x max = %.2f mm\n', resGeom2D.x_max_mm);
fprintf('  y min = %.2f mm\n', resGeom2D.y_min_mm);
fprintf('  y max = %.2f mm\n', resGeom2D.y_max_mm);

fprintf('\nComponentes detectados:\n');
fprintf('  Motores:    %d\n', size(resGeom2D.componentes.motores_m,1));
fprintf('  Servos:     %d\n', size(resGeom2D.componentes.servos_m,1));

if all(isfinite(resGeom2D.componentes.bateria_m))
    fprintf('  Bateria:    x = %.2f mm, y = %.2f mm\n', ...
        resGeom2D.componentes.bateria_mm(1), ...
        resGeom2D.componentes.bateria_mm(2));
else
    fprintf('  Bateria:    no detectada\n');
end

if all(isfinite(resGeom2D.componentes.electronica_m))
    fprintf('  Electronica: x = %.2f mm, y = %.2f mm\n', ...
        resGeom2D.componentes.electronica_mm(1), ...
        resGeom2D.componentes.electronica_mm(2));
else
    fprintf('  Electronica: no detectada\n');
end

fprintf('\nTabla de componentes:\n');
disp(resGeom2D.tablaComponentes);

fprintf('\nChequeo de simetria:\n');

if resGeom2D.simetria.motores.disponible
    fprintf('  Motores: %s\n', resGeom2D.simetria.motores.mensaje);
    fprintf('    error x = %.2f mm\n', resGeom2D.simetria.motores.error_x_mm);
    fprintf('    error y = %.2f mm\n', resGeom2D.simetria.motores.error_y_mm);
else
    fprintf('  Motores: %s\n', resGeom2D.simetria.motores.mensaje);
end

if resGeom2D.simetria.servos.disponible
    fprintf('  Servos: %s\n', resGeom2D.simetria.servos.mensaje);
    fprintf('    error x = %.2f mm\n', resGeom2D.simetria.servos.error_x_mm);
    fprintf('    error y = %.2f mm\n', resGeom2D.simetria.servos.error_y_mm);
else
    fprintf('  Servos: %s\n', resGeom2D.simetria.servos.mensaje);
end

fprintf('============================================\n\n');

end