function [alpha,beta,sigR2,SI] = gg_params(Cn2,lambda,L,D)
%GG_PARAMS  Gamma-Gamma turbulence parameters with aperture averaging (Andrews & Phillips, plane wave).
%   Cn2 [m^-2/3], lambda [m], L [m], D receiver aperture diameter [m] (D=0 -> point receiver).
%   Returns alpha (large-scale), beta (small-scale), Rytov variance and scintillation index SI = 1/alpha+1/beta+1/(alpha*beta).
if nargin < 4, D = 0; end
k      = 2*pi/lambda;
sigR2  = 1.23*Cn2*k^(7/6)*L^(11/6);
s125   = sigR2^(6/5);                       % sigma_R^(12/5)
d2     = k*D^2/(4*L);
varX   = 0.49*sigR2/(1+0.18*d2+0.56*s125)^(7/6);
varY   = 0.51*sigR2/(1+0.69*s125)^(5/6)/(1+0.90*d2+0.62*d2*s125)^(5/6);
alpha  = 1/(exp(varX) - 1);
beta   = 1/(exp(varY) - 1);
SI     = 1/alpha + 1/beta + 1/(alpha*beta);
end
