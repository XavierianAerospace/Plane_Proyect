function graficar_simulacion_vtol(resSim)
%GRAFICAR_SIMULACION_VTOL Grafica los resultados de simular_transicion_vtol.
%
% Reproduce las 4 graficas del script original del usuario
% (altitud, velocidades, empuje, angulo de tilt) y agrega un quinto
% panel con la potencia ideal requerida en los motores.

t = resSim.t;

figure('Name', 'Simulacion Vuelo VTOL', 'Color', [1 1 1]);

subplot(3, 2, 1);
plot(t, resSim.z, 'b', 'LineWidth', 2);
grid on; xlabel('Tiempo (s)'); ylabel('Altitud (m)');
title('Trayectoria Vertical (Altitud)');

subplot(3, 2, 2);
plot(t, resSim.vx * 3.6, 'r', 'LineWidth', 2); hold on;
plot(t, resSim.vz * 3.6, 'g--', 'LineWidth', 1.5);
grid on; xlabel('Tiempo (s)'); ylabel('Velocidad (km/h)');
legend('V. Horizontal', 'V. Ascenso');
title('Velocidades de Vuelo');

subplot(3, 2, 3);
plot(t, resSim.T_vert + resSim.T_horiz, 'k', 'LineWidth', 2); hold on;
plot(t, resSim.T_vert, 'b--', 'LineWidth', 1.5);
plot(t, resSim.T_horiz, 'r--', 'LineWidth', 1.5);
grid on; xlabel('Tiempo (s)'); ylabel('Empuje (N)');
legend('Empuje Total', 'Eje Vertical', 'Eje Horizontal');
title('Empuje Requerido');

subplot(3, 2, 4);
plot(t, resSim.tilt_angle, 'm', 'LineWidth', 2);
grid on; xlabel('Tiempo (s)'); ylabel('Angulo Tilt (grados)');
title('Transicion de Motores');

subplot(3, 2, [5 6]);
plot(t, resSim.P_ideal_W / 1000, 'Color', [0.85 0.33 0.10], 'LineWidth', 2);
hold on;
yline(resSim.P_hover_ideal_W / 1000, 'k--', 'LineWidth', 1.5);
grid on; xlabel('Tiempo (s)'); ylabel('Potencia ideal (kW)');
legend('Potencia ideal motores', 'Potencia ideal en hover puro', ...
    'Location', 'best');
title('Potencia Ideal Requerida (teoria de disco actuador)');

end
