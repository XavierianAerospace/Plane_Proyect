function resSim = simular_transicion_vtol(cfgSim)
%SIMULAR_TRANSICION_VTOL Simula despegue vertical + transicion a vuelo
% horizontal de un VTOL tipo tricoptero, y calcula la potencia IDEAL
% requerida en los motores (teoria de disco actuador / momentum theory)
% para generar el empuje necesario en cada instante.
%
% Esta funcion es la version "modular" del script original del usuario:
% misma fisica y mismo bucle de integracion, pero como funcion, para
% poder llamarla desde Main_Vtol.m y reutilizar la masa real calculada
% por calcular_masa_CG_vtol.m en vez de un valor fijo.
%
% Uso:
%   resSim = simular_transicion_vtol();            % todo por defecto
%   resSim = simular_transicion_vtol(cfgSim);       % parametros propios
%
% Campos opcionales de cfgSim (si no se dan, se usa el valor por defecto):
%   .m                  Masa total del avion [kg]           (def 2.5)
%   .g                  Gravedad [m/s^2]                    (def 9.81)
%   .S                  Superficie alar [m^2]                (def 0.28)
%   .rho                Densidad del aire [kg/m^3]           (def 1.225)
%   .Cd0                Coeficiente de arrastre               (def 0.04)
%   .T_max_total        Empuje maximo total de los motores [N] (def 42)
%   .numMotores         Numero de motores de empuje            (def 3)
%   .diametroHelice_m   Diametro de cada helice [m]     ASUMIDO, def 0.3556 (14")
%                        -> CAMBIA ESTE VALOR por el diametro real de tus
%                           helices/motores para que la potencia sea correcta.
%   .z_target           Altitud objetivo fase 1 [m]           (def 15)
%   .dt                 Paso de integracion [s]               (def 0.01)
%   .t_max              Tiempo total de simulacion [s]        (def 20)
%
% Salida resSim:
%   .t, .z, .vz, .x, .vx, .T_vert, .T_horiz, .tilt_angle   (igual que antes)
%   .P_ideal_W          Potencia ideal total de los motores en cada instante [W]
%   .P_max_ideal_W      Maxima potencia ideal durante toda la simulacion [W]
%   .P_hover_ideal_W    Potencia ideal SOLO para sostener el peso en hover
%                        puro (T total = peso, tilt = 0) [W]
%   .W_N                Peso total del avion [N]
%   .cfg                Configuracion realmente usada (con defaults aplicados)

%% ============================================================
% 0. Completar configuracion con valores por defecto
% ============================================================

if nargin < 1 || isempty(cfgSim)
    cfgSim = struct();
end

def = struct( ...
    'm', 2.5, ...
    'g', 9.81, ...
    'S', 0.28, ...
    'rho', 1.225, ...
    'Cd0', 0.04, ...
    'T_max_total', 42, ...
    'numMotores', 3, ...
    'diametroHelice_m', 0.3556, ...
    'z_target', 15, ...
    'dt', 0.01, ...
    't_max', 20);

campos = fieldnames(def);
for i = 1:numel(campos)
    c = campos{i};
    if ~isfield(cfgSim, c) || isempty(cfgSim.(c))
        cfgSim.(c) = def.(c);
    end
end

m = cfgSim.m;
g = cfgSim.g;
S = cfgSim.S;
rho = cfgSim.rho;
Cd0 = cfgSim.Cd0;
T_max_total = cfgSim.T_max_total;
numMotores = cfgSim.numMotores;
D_helice = cfgSim.diametroHelice_m;
z_target = cfgSim.z_target;
dt = cfgSim.dt;
t_max = cfgSim.t_max;

W = m * g;

fprintf('\nSimulacion VTOL: masa = %.3f kg, peso = %.2f N, %d motores, ', ...
    m, W, numMotores);
fprintf('helice = %.3f m (ASUMIDO si no lo cambiaste).\n', D_helice);

%% ============================================================
% 1. Vectores de tiempo y estado
% ============================================================

t = 0:dt:t_max;
N = length(t);

z = zeros(1, N);
vz = zeros(1, N);
x = zeros(1, N);
vx = zeros(1, N);
T_vert = zeros(1, N);
T_horiz = zeros(1, N);
tilt_angle = zeros(1, N);
P_ideal = zeros(1, N);   % potencia ideal total de los motores [W]

% Area de disco de cada helice (teoria de disco actuador)
A_helice = pi * (D_helice / 2)^2;

%% ============================================================
% 2. Bucle de integracion (misma logica del script original)
% ============================================================

angle = 0;

for i = 1:(N - 1)

    % --- LOGICA DE CONTROL DE FASES ---
    if z(i) < z_target && angle == 0
        % FASE 1: DESPEGUE VERTICAL
        angle = 0;
        T_apply = W + 10 * exp(-z(i) / 5);
        T_apply = min(T_apply, T_max_total);
    else
        % FASE 2: TRANSICION (tilt de motores 0 a 90 grados)
        if angle < 90
            angle = angle + 15 * dt;
        else
            angle = 90;
        end
        T_apply = 27; % Empuje constante de crucero
    end

    tilt_angle(i) = angle;
    rad_ang = deg2rad(angle);

    % Descomposicion de empuje
    Tv = T_apply * cos(rad_ang);
    Th = T_apply * sin(rad_ang);
    T_vert(i) = Tv;
    T_horiz(i) = Th;

    % --- POTENCIA IDEAL REQUERIDA (teoria de disco actuador) ---
    % Empuje por motor (se asume repartido por igual entre los numMotores)
    T_motor = T_apply / numMotores;
    % Velocidad inducida: vi = sqrt(T_motor / (2*rho*A_helice))
    % Potencia ideal por motor: P = T_motor * vi = T_motor^1.5 / sqrt(2*rho*A_helice)
    P_ideal(i) = numMotores * (T_motor^1.5) / sqrt(2 * rho * A_helice);

    % --- DINAMICA HORIZONTAL (EJE X) ---
    D = 0.5 * rho * (vx(i)^2) * S * Cd0;
    ax = (Th - D) / m;
    vx(i+1) = max(vx(i) + ax * dt, 0);
    x(i+1) = x(i) + vx(i) * dt;

    % --- DINAMICA VERTICAL (EJE Z) ---
    L = min(0.5 * rho * (vx(i)^2) * S * 0.6, W);
    if angle < 90
        az = (Tv + L - W) / m - 2.0 * vz(i);
    else
        az = (L - W) / m - 1.0 * vz(i);
    end
    vz(i+1) = vz(i) + az * dt;
    z(i+1) = max(z(i) + vz(i) * dt, 0);
end

% Ultimo punto para graficar bien
tilt_angle(N) = angle;
T_vert(N) = T_vert(N-1);
T_horiz(N) = T_horiz(N-1);
P_ideal(N) = P_ideal(N-1);

%% ============================================================
% 3. Potencia ideal SOLO para vencer la gravedad (hover puro)
% ============================================================
% Caso de referencia: tilt = 0, empuje total = peso exacto (T = W).
% Es la potencia minima ideal para que el avion se sostenga en el aire.

T_motor_hover = W / numMotores;
P_hover_ideal_W = numMotores * (T_motor_hover^1.5) / sqrt(2 * rho * A_helice);

fprintf('Potencia ideal para vencer la gravedad en hover: %.1f W (%.2f kW)\n', ...
    P_hover_ideal_W, P_hover_ideal_W / 1000);
fprintf('Potencia ideal maxima durante la simulacion:      %.1f W (%.2f kW)\n\n', ...
    max(P_ideal), max(P_ideal) / 1000);

%% ============================================================
% 4. Empaquetar resultados
% ============================================================

resSim.t = t;
resSim.z = z;
resSim.vz = vz;
resSim.x = x;
resSim.vx = vx;
resSim.T_vert = T_vert;
resSim.T_horiz = T_horiz;
resSim.tilt_angle = tilt_angle;

resSim.P_ideal_W = P_ideal;
resSim.P_max_ideal_W = max(P_ideal);
resSim.P_hover_ideal_W = P_hover_ideal_W;

resSim.W_N = W;
resSim.A_helice_m2 = A_helice;
resSim.cfg = cfgSim;

end
