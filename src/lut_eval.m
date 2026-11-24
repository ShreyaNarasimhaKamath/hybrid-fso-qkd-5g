function [R,E] = lut_eval(lut,eta,adaptive)
%LUT_EVAL  Look up key bits per pulse and QBER for transmittance eta.
x = log10(max(eta,1e-6));
if adaptive, Rv = lut.Ra; Ev = lut.Ea; else, Rv = lut.Rs; Ev = lut.Es; end
R = interp1(lut.logeta,Rv,x,'linear',0);
E = interp1(lut.logeta,Ev,x,'linear',0.5);
R(eta < 1e-6) = 0;
end
