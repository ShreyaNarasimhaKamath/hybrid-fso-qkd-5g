function p = pct(x,q)
%PCT  Percentile without the Statistics Toolbox.
x = sort(x(:)); n = numel(x);
if n==0, p = NaN; return; end
p = x(max(1,min(n,ceil(q/100*n))));
end
