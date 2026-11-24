function x = poiss(lam)
%POISS  Poisson random numbers (vector of means) by CDF inversion, no toolbox needed.
lam = lam(:); N = numel(lam); K = 0:100;
Lm  = repmat(lam,1,numel(K)); Km = repmat(K,N,1);
cdf = gammainc(Lm,Km+1,'upper');
u   = rand(N,1);
x   = sum(repmat(u,1,numel(K)) > cdf,2);
end
