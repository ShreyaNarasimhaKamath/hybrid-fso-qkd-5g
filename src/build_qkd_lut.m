function lut = build_qkd_lut(P)
%BUILD_QKD_LUT  Pre-compute key-per-pulse vs. transmittance for (a) fixed intensity and
%   (b) fading-adaptive intensity (best mu from a grid for the instantaneous eta).
[~,Y0] = quantum_budget(P,P.L);
q = P.q;
eg = logspace(-6,0,400);
[Rs,Es] = qkd_decoy_rate(eg,q.mu_static,q.nu_ratio*q.mu_static,Y0,q.ed,q.f_ec,q.sift);
Ra = zeros(size(eg)); Ea = Es; mu_opt = q.mu_static*ones(size(eg));
for m = q.mu_grid
    [Rm,Em] = qkd_decoy_rate(eg,m,q.nu_ratio*m,Y0,q.ed,q.f_ec,q.sift);
    better = Rm > Ra;
    Ra(better) = Rm(better); Ea(better) = Em(better); mu_opt(better) = m;
end
lut.logeta = log10(eg); lut.Y0 = Y0;
lut.Rs = Rs; lut.Es = Es; lut.Ra = Ra; lut.Ea = Ea; lut.mu_opt = mu_opt;
end
