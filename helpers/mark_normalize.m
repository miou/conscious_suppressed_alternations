function [ marks ] = mark_normalize( marks )
%MARK_NORMALIZE 
% center landmarks and normalize the width

xc = mean(marks(:,1));
yc = mean(marks(:,2));
w = (max(marks(:,1)) - min(marks(:,1)));

marks(:,1) = (marks(:,1) - xc)/w;
marks(:,2) = (marks(:,2) - yc)/w;

end

