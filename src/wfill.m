function a = wfill(g,d,w)
%WFILL  Weighted max-min (water-filling) split of g among demands d with weights w.
a = zeros(size(d)); act = (d > 1e-12) & (w > 0);
it = 0;
while g > 1e-12 && any(act) && it < 10
    share = g*(w.*act)/sum(w(act));
    give  = min(share, d - a);
    a = a + give; g = g - sum(give);
    act = act & (d - a > 1e-12);
    it = it + 1;
end
end
