function z = ar1(N,tau,dt)
%AR1  Unit-variance Gaussian AR(1) process with correlation time tau.
rho = exp(-dt/tau);
nb  = ceil(8*tau/dt);
w   = randn(N+nb,1);
x   = filter(sqrt(1-rho^2),[1 -rho],w);
z   = x(nb+1:end);
end
