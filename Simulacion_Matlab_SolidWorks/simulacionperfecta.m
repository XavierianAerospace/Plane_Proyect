% =========================================================================
% SIMULACIÓN ROBUSTA Y ESTABLE - STALLION VTOL
% =========================================================================
clearvars; clc; close all;

%% 1. PARÁMETROS DEL TIEMPO
dt = 0.01; 
t_max = 20; 
t = 0:dt:t_max; 
N = length(t);

%% 2. PARÁMETROS FÍSICOS DEL DRON
m = 2.5;              % Masa (kg)
g = 9.81;             % Gravedad (m/s^2)
W = m * g;            % Peso (N) = ~24.525 N
S = 0.28;             % Superficie alar (m^2)
rho = 1.225;          % Densidad del aire (kg/m^3)
Cd0 = 0.04;           % Coeficiente de arrastre

% Propulsión
T_max_total = 42;     % Empuje máximo total de los 3 motores (N)

%% 3. VECTORS DE ESTADO
z = zeros(1, N);          
vz = zeros(1, N);         
x = zeros(1, N);          
vx = zeros(1, N);         

T_vert = zeros(1, N);     
T_horiz = zeros(1, N);    
tilt_angle = zeros(1, N); 

%% 4. BUCLE DE INTEGRACIÓN ESTABLE
z_target = 15;        % Altitud objetivo (m)
v_stall = 12;         % Velocidad de pérdida del ala (m/s)

angle = 0;

for i = 1:(N - 1)
    
    % --- LÓGICA DE CONTROL DE FASES ---
    if z(i) < z_target && angle == 0
        % FASE 1: DESPEGUE VERTICAL
        angle = 0;
        % Empuje para subir suavemente hasta z_target
        T_apply = W + 10 * exp(-z(i)/5); 
        T_apply = min(T_apply, T_max_total);
    else
        % FASE 2: TRANSICIÓN (Tilt de motores 0° a 90°)
        if angle < 90
            angle = angle + 15 * dt; % Inclinación a 15 deg/s
        else
            angle = 90;
        end
        T_apply = 27; % Empuje constante de crucero
    end
    
    tilt_angle(i) = angle;
    rad_ang = deg2rad(angle);
    
    % Descomposición de Empuje
    Tv = T_apply * cos(rad_ang);
    Th = T_apply * sin(rad_ang);
    
    T_vert(i) = Tv;
    T_horiz(i) = Th;
    
    % --- DINÁMICA HORIZONTAL (EJE X) ---
    % Arrastre aerodinámico
    D = 0.5 * rho * (vx(i)^2) * S * Cd0;
    ax = (Th - D) / m;
    
    vx(i+1) = max(vx(i) + ax * dt, 0);
    x(i+1) = x(i) + vx(i) * dt;
    
    % --- DINÁMICA VERTICAL (EJE Z) ---
    % La sustentación alar crece con la velocidad horizontal hasta compensar el peso
    L = min(0.5 * rho * (vx(i)^2) * S * 0.6, W);
    
    if angle < 90
        % Control de altitud en hover/transición
        az = (Tv + L - W) / m - 2.0 * vz(i); % Término de amortiguamiento (-2*vz)
    else
        % En vuelo horizontal puro, la sustentación mantiene la altitud
        az = (L - W) / m - 1.0 * vz(i);
    end
    
    vz(i+1) = vz(i) + az * dt;
    z(i+1) = max(z(i) + vz(i) * dt, 0);
end

% Último punto para graficar bien
tilt_angle(N) = angle;
T_vert(N) = T_vert(N-1);
T_horiz(N) = T_horiz(N-1);

%% 5. GRAFICACIÓN
figure('Name','Simulacion Correcta VTOL','Color',[1 1 1]);

subplot(2,2,1);
plot(t, z, 'b', 'LineWidth', 2);
grid on; xlabel('Tiempo (s)'); ylabel('Altitud (m)');
title('Trayectoria Vertical (Altitud)');

subplot(2,2,2);
plot(t, vx * 3.6, 'r', 'LineWidth', 2); hold on;
plot(t, vz * 3.6, 'g--', 'LineWidth', 1.5);
grid on; xlabel('Tiempo (s)'); ylabel('Velocidad (km/h)');
legend('V. Horizontal', 'V. Ascenso');
title('Velocidades de Vuelo');

subplot(2,2,3);
plot(t, T_vert + T_horiz, 'k', 'LineWidth', 2); hold on;
plot(t, T_vert, 'b--', 'LineWidth', 1.5);
plot(t, T_horiz, 'r--', 'LineWidth', 1.5);
grid on; xlabel('Tiempo (s)'); ylabel('Empuje (N)');
legend('Empuje Total', 'Eje Vertical', 'Eje Horizontal');
title('Empuje Requerido');

subplot(2,2,4);
plot(t, tilt_angle, 'm', 'LineWidth', 2);
grid on; xlabel('Tiempo (s)'); ylabel('Ángulo Tilt (°)');
title('Transición de Motores');