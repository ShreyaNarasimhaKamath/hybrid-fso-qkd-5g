function [R,Eq,Y1,e1] = qkd_decoy_rate(eta,mu,nu,Y0,ed,f,q)
%QKD_DECOY_RATE  Asymptotic secret-key fraction per pulse, decoy-state BB84 (signal mu, weak decoy nu, vacuum).
%   Lower bound on single-photon yield Y1 and upper bound on single-photon error e1 follow Ma et al. (PRA 72, 012326).
%   eta : total channel+detector transmittance (vector)    Y0 : background/dark yield per pulse
%   ed  : optical error      f : EC inefficiency      q : sifting factor
%   R   : key bits per transmitted pulse,  Eq : overall QBER of the signal state.
e0 = 0.5;
Qm = 1 - (1-Y0).*exp(-eta*mu);
Qn = 1 - (1-Y0).*exp(-eta*nu);
Eq = (e0*Y0 + ed*(1-exp(-eta*mu)))./Qm;
En = (e0*Y0 + ed*(1-exp(-eta*nu)))./Qn;
Y1 = mu/(mu*nu-nu^2) * (Qn.*exp(nu) - Qm.*exp(mu)*nu^2/mu^2 - (mu^2-nu^2)/mu^2*Y0);
Y1 = max(Y1,0);
e1 = (En.*Qn.*exp(nu) - e0*Y0)./max(Y1*nu,1e-30);
e1 = min(max(e1,0),0.5);
Q1 = Y1*mu.*exp(-mu);
R  = q*(Q1.*(1-h2(e1)) - f*Qm.*h2(Eq));
R(Y1<=0) = 0;
R  = max(R,0);
end
