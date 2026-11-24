function [eta0,Y0,info] = quantum_budget(P,L,Cn2)
%QUANTUM_BUDGET  Mean transmittance of the quantum channel and background yield per pulse.
%   Cn2 (optional) adds turbulence-induced long-term beam broadening (Andrews & Phillips);
%   the zero-mean-loss scintillation is modelled separately by the Gamma-Gamma fading.
if nargin < 3, Cn2 = 0; end
q = P.q;
w0      = max(L*q.theta/2,1e-3);                 % diffraction/pointing-limited beam radius at Rx
w       = w0*sqrt(1 + beam_spread(Cn2,q.lambda,L,w0));
eta_geo = 1 - exp(-2*q.a_rx^2/w^2);
eta_atm = exp(-atm_atten(P.V,q.lambda)*L);
eta_opt = 10^(-q.loss_opt_dB/10);
eta0    = eta_geo*eta_atm*eta_opt*q.eta_det;
h = 6.626e-34; c = 3e8;
Omega   = pi*(q.fov/2)^2;  A = pi*q.a_rx^2;
ph_rate = q.Nb*Omega*A*q.dlam_nm*q.lambda/(h*c); % background photons/s reaching the detector
p_bg    = ph_rate*q.t_gate*q.eta_det;
p_dk    = q.dark_cps*q.t_gate;
Y0      = p_bg + p_dk - p_bg*p_dk;
info.eta_geo = eta_geo; info.eta_atm = eta_atm; info.p_bg = p_bg; info.p_dk = p_dk;
info.loss_dB = -10*log10(eta0);
end
