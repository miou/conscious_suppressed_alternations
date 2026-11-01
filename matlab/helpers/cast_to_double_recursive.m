function x = cast_to_double_recursive(x)
%CAST_TO_DOUBLE_RECURSIVE  Convert every single array inside a struct/cell tree to double.
% Applied to the pooled summaries on load so that all across-session computations (PCA,
% regression, explained variance, decoding) run in double precision.
if isa(x,'single')
    x = double(x);
elseif iscell(x)
    for k = 1:numel(x); x{k} = cast_to_double_recursive(x{k}); end
elseif isstruct(x)
    fn = fieldnames(x);
    for k = 1:numel(x)
        for f = 1:numel(fn); x(k).(fn{f}) = cast_to_double_recursive(x(k).(fn{f})); end
    end
end
end
