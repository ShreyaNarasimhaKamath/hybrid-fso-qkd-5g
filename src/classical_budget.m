function [Qbar,info] = classical_budget(P,L,Cn2)
%CLASSICAL_BUDGET  Fading-free Q-factor of the 10 Gb/s OOK link, Q = R*Prx/sigma.
if nargin < 3, Cn2 = 0; end
c = P.c;
w0      = max(L*c.theta/2,1e-3);
w       = w0*sqrt(1 + beam_spread(Cn2,c.lambda,L,w0));
eta_geo = 1 - exp(-2*c.a_rx^2/w^2);
eta_atm = exp(-atm_atten(P.V,c.lambda)*L);
eta_opt = 10^(-c.loss_opt_dB/10);
Prx     = 1e-3*10^(c.Ptx_dBm/10)*eta_geo*eta_atm*eta_opt;     % [W]
Qbar    = c.resp*Prx/c.sigma0;
info.Prx_dBm = 10*log10(Prx/1e-3);
info.eta_geo = eta_geo; info.eta_atm = eta_atm;
end
