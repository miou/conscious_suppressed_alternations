function slope = rma_slope(x, y)
%RMA_SLOPE  Reduced-major-axis (geometric-mean) regression slope of y on x.
%   slope = sign(corr) * std(y)/std(x). Symmetric: rma(x,y) = 1/rma(y,x).
    x = x(:); y = y(:);
    ok = isfinite(x) & isfinite(y);
    x = x(ok); y = y(ok);
    if numel(x) < 3 || std(x) == 0
        slope = NaN; return;
    end
    r = corr(x, y);                    % sign of the relationship
    slope = sign(r) * std(y) / std(x);
end