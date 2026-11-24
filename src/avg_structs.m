function out = avg_structs(c)
%AVG_STRUCTS  Average all numeric fields (except 'ts') over a cell array of structs; also return std as out.std.
out = c{1}; out.std = struct();
f = fieldnames(c{1});
for i = 1:numel(f)
    if strcmp(f{i},'ts') || strcmp(f{i},'std') || ~isnumeric(c{1}.(f{i})), continue; end
    v = cell2mat(cellfun(@(s) s.(f{i})(:)', c(:), 'UniformOutput', false));   % nseeds x nvals
    out.(f{i}) = reshape(mean(v,1), size(c{1}.(f{i})));
    out.std.(f{i}) = reshape(std(v,0,1), size(c{1}.(f{i})));
end
out = rmfield(out,'ts');
end
