function set_seed(s)
try
    rng(s);
catch
    rand('state',s); randn('state',s);
end
end
