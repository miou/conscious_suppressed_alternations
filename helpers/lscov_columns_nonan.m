function b = lscov_columns_nonan(X,Y)
%LSCOV_COLUMNS_NONAN Column-wise linear regression ignoring NaNs.
%
% Fits independently for each column:
%
%   Y(:,j) = b(1,j) + b(2,j) * X(:,j)
%
% Output:
%   b : 2 x variables
%       b(1,:) = intercepts
%       b(2,:) = slopes
%
% Works for:
%   X = n x 1,       Y = n x m   % shared predictor, like old lscov use
%   X = n x m,       Y = n x m   % column-specific predictor
%
% Equivalent to:
%   for j = 1:size(Y,2)
%       if size(X,2)==1
%           xj = X;
%       else
%           xj = X(:,j);
%       end
%       valid = ~isnan(xj) & ~isnan(Y(:,j));
%       b(:,j) = lscov([ones(sum(valid),1), xj(valid)], Y(valid,j));
%   end

assert(size(X,1) == size(Y,1), 'X and Y must have the same number of rows.');

nObs = size(Y,1);
nCols = size(Y,2);

if size(X,2) == 1
    X = repmat(X,1,nCols);
elseif size(X,2) ~= nCols
    error('X must be either n x 1 or the same size as Y.');
end

valid = ~isnan(X) & ~isnan(Y);
n = sum(valid,1);

X0 = X;
Y0 = Y;
X0(~valid) = 0;
Y0(~valid) = 0;

meanX = sum(X0,1) ./ n;
meanY = sum(Y0,1) ./ n;

Xc = X - meanX;
Yc = Y - meanY;

Xc(~valid) = 0;
Yc(~valid) = 0;

denom = sum(Xc.^2,1);

slope = sum(Xc .* Yc,1) ./ denom;
intercept = meanY - slope .* meanX;

b = [intercept; slope];

bad = n < 2 | denom == 0;
b(:,bad) = nan;
end