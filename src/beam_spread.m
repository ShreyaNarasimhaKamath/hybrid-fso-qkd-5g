function s = beam_spread(Cn2,lambda,L,w)
%BEAM_SPREAD  Relative long-term turbulence broadening of the beam: w_LT^2 = w^2 (1 + s).
%   s = 1.63 * sigma_R^(12/5) * Lambda1,  Lambda1 = 2L/(k w^2)   (Andrews & Phillips, collimated beam).
if Cn2 <= 0, s = 0; return; end
k = 2*pi/lambda;
sigR2 = 1.23*Cn2*k^(7/6)*L^(11/6);
s = 1.63*sigR2^(6/5)*(2*L/(k*w^2));
end
