function p = bar_with_std(x,y);
mean_x = mean(y);
p = bar(x,mean(y),'facecolor',[.5 .5 .5]);
sem = std(y);
errorbar(x,mean_x,sem,sem,'k')