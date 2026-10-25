function [p,errorarea] = plot_with_sem(x,y);
%y is a matrix, and mean and s.e.m. are taking across its rows.
sem = @(y,dim) nanstd(y,[],dim)./sqrt(size(y,1));
[p,errorarea]=boundedline(x,nanmean(y,1),...
    permute(sem(y,1),[2,3,1]),'alpha');
