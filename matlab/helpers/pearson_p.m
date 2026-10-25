function [pstr, log10p] = pearson_p(r,n)
% Two-sided Pearson correlation p-value, robust to numerical underflow.

df = n - 2;
t  = abs(r) * sqrt(df/(1-r^2));
x  = df/(df+t^2);
a  = df/2; b = 0.5;

% Regularized incomplete beta in log space
cf = betacf(a,b,x);
logp = a*log(x) + b*log1p(-x) - betaln(a,b) + log(cf/a);

log10p = logp/log(10);
e = floor(log10p);
m = 10^(log10p-e);

pstr = sprintf('%.3g x 10^{%d}',m,e);


function h = betacf(a,b,x)
MAXIT=10000; EPS=3e-14; FPMIN=1e-300;
qab=a+b; qap=a+1; qam=a-1;
c=1; d=1-qab*x/qap;
if abs(d)<FPMIN, d=FPMIN; end
d=1/d; h=d;

for k=1:MAXIT
    k2=2*k;
    aa=k*(b-k)*x/((qam+k2)*(a+k2));
    d=1+aa*d; if abs(d)<FPMIN, d=FPMIN; end
    c=1+aa/c; if abs(c)<FPMIN, c=FPMIN; end
    d=1/d; h=h*d*c;

    aa=-(a+k)*(qab+k)*x/((a+k2)*(qap+k2));
    d=1+aa*d; if abs(d)<FPMIN, d=FPMIN; end
    c=1+aa/c; if abs(c)<FPMIN, c=FPMIN; end
    d=1/d; del=d*c; h=h*del;

    if abs(del-1)<EPS, break; end
end
end
end