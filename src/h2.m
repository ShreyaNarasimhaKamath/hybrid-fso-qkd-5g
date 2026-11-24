function h = h2(x)
x = min(max(x,1e-12),1-1e-12);
h = -x.*log2(x) - (1-x).*log2(1-x);
end
