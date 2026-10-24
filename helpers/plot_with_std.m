function [p,errorarea] = plot_with_std(x,y);
%y is a matrix, and mean and s.e.m. are taking across its first dimension.
sem = @(y,dim) std(y,[],dim)./sqrt(size(y,1));
[p,errorarea]=boundedline(x,nanmean(y,1),...
    permute(nanstd(y,[],1),[2,3,1]),'alpha');
