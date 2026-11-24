function a = atm_atten(V,lambda)
%ATM_ATTEN  Kim visibility model, returns extinction coefficient in 1/m.
Vkm = V/1e3; lam_nm = lambda*1e9;
if     Vkm > 50,  q = 1.6;
elseif Vkm > 6,   q = 1.3;
elseif Vkm > 1,   q = 0.16*Vkm + 0.34;
elseif Vkm > 0.5, q = Vkm - 0.5;
else              q = 0;
end
a = 3.912/Vkm*(lam_nm/550)^(-q)/1e3;
end
