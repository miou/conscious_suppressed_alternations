function slope = tls_slope(x, y)
%TLS_SLOPE  Total-least-squares (major-axis / orthogonal) regression slope of y on x.
%   Minimises perpendicular distances; = first principal eigenvector of cov([x y]).
    x = x(:); y = y(:);
    ok = isfinite(x) & isfinite(y);
    x = x(ok); y = y(ok);
    if numel(x) < 3
        slope = NaN; return;
    end
    C   = cov(x, y);                   % [sxx sxy; sxy syy]
    sxx = C(1,1); syy = C(2,2); sxy = C(1,2);
    if sxy == 0
        slope = NaN; return;
    end
    slope = (syy - sxx + sqrt((syy - sxx)^2 + 4*sxy^2)) / (2*sxy);
end