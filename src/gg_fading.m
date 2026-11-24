function I = gg_fading(alpha,beta,z1,z2)
%GG_FADING  Gamma-Gamma irradiance (unit mean) from two correlated Gaussian drivers (Gaussian copula).
u1 = min(max(0.5*erfc(-z1/sqrt(2)),1e-10),1-1e-10);
u2 = min(max(0.5*erfc(-z2/sqrt(2)),1e-10),1-1e-10);
X  = gammaincinv(u1,alpha)/alpha;       % large-scale, Gamma(alpha,1/alpha)
Y  = gammaincinv(u2,beta)/beta;         % small-scale, Gamma(beta,1/beta)
I  = X.*Y;
end
