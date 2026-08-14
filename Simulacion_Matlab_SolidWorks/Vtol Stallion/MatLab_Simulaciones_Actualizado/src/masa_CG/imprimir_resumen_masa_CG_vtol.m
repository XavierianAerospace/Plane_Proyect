function imprimir_resumen_masa_CG_vtol(resMasaCG)
%IMPRIMIR_RESUMEN_MASA_CG_VTOL Imprime resumen de masa y CG.

fprintf('\n============================================\n');
fprintf(' RESUMEN MASA Y CENTRO DE GRAVEDAD\n');
fprintf('============================================\n');

fprintf('Fuente de datos:\n%s\n\n', string(resMasaCG.fuente));

fprintf('Filas totales:    %d\n', resMasaCG.validacion.n_filas_total);
fprintf('Filas usadas:     %d\n', resMasaCG.validacion.n_filas_usadas);
fprintf('Filas ignoradas:  %d\n\n', resMasaCG.validacion.n_filas_ignoradas);

fprintf('Masa total:\n');
fprintf('  %.2f g\n', resMasaCG.masa.total_g);
fprintf('  %.3f kg\n', resMasaCG.masa.total_kg);
fprintf('  %.2f N\n\n', resMasaCG.masa.peso_N);

fprintf('Centro de gravedad:\n');
fprintf('  CG_x = %.2f mm   %.4f m\n', resMasaCG.CG.x_mm, resMasaCG.CG.x_m);
fprintf('  CG_y = %.2f mm   %.4f m\n', resMasaCG.CG.y_mm, resMasaCG.CG.y_m);
fprintf('  CG_z = %.2f mm   %.4f m\n\n', resMasaCG.CG.z_mm, resMasaCG.CG.z_m);

fprintf('Masa por categoria:\n');
disp(resMasaCG.resumen.porCategoria);

fprintf('Masa por tipo:\n');
disp(resMasaCG.resumen.porTipo);

if resMasaCG.validacion.n_filas_ignoradas > 0
    fprintf('Partes ignoradas por datos incompletos:\n');

    Tfalt = resMasaCG.validacion.tabla_faltantes;

    cols = ["categoria","tipo","nombre","x_mm","y_mm","z_mm","masa_g"];
    cols = cols(ismember(cols, string(Tfalt.Properties.VariableNames)));

    disp(Tfalt(:, cols));
end

fprintf('============================================\n\n');

end