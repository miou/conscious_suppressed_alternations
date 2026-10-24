function h = plotTimes(Times,StartTime,EndTime,varargin)
%Varargin is plotspec
    TimesInRange = Times(and(Times>=StartTime,Times<=EndTime));
    hold on
    for TimeIndex = 1:length(TimesInRange)
        if isempty(varargin)
            h(TimeIndex) = plot([TimesInRange(TimeIndex) TimesInRange(TimeIndex)], get(gca,'YLim'));
        elseif length(varargin) == 1
            h(TimeIndex) = plot([TimesInRange(TimeIndex) TimesInRange(TimeIndex)], get(gca,'YLim'),varargin{1});
        else
            h(TimeIndex) = plot([TimesInRange(TimeIndex) TimesInRange(TimeIndex)], get(gca,'YLim'),varargin{1},varargin{2});
        end
    end
    if isempty(TimesInRange)
        h = [];
    end
end