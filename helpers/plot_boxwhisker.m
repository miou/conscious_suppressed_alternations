function plot_boxwhisker_v2(data1,ylimits,xlabels,varargin)
% PLOT_BOXWHISKER_V2
%
% Single:
% plot_boxwhisker_v2(data,ylimits,'Label',...)
%
% Paired:
% plot_boxwhisker_v2(data1,ylimits,{'A','B'},'PairedData',data2,...)

p = inputParser;

addParameter(p,'PairedData',[]);
addParameter(p,'YLabel','');
addParameter(p,'ReferenceY',[]);
addParameter(p,'MarkerSize',6);
addParameter(p,'MarkerAlpha',0.6);
addParameter(p,'BoxWidth',0.125);
addParameter(p,'JitterWidth',0.25);
addParameter(p,'LineWidth',0.5);
addParameter(p,'LineAlpha',0.18);

parse(p,varargin{:});

hold on

marker_size  = p.Results.MarkerSize;
marker_alpha = p.Results.MarkerAlpha;
box_width    = p.Results.BoxWidth;
jitter_width = p.Results.JitterWidth;

if isempty(p.Results.PairedData)

    %% ---------------- Single ----------------
    y = data1(:);
    y = y(isfinite(y));

    boxchart(ones(size(y)),y,...
        'BoxWidth',box_width,...
        'BoxFaceColor','k',...
        'BoxFaceAlpha',0.12,...
        'BoxEdgeColor','k',...
        'WhiskerLineColor','k',...
        'MarkerStyle','none');

    rng(1)
    x = 1 + jitter_width*(rand(size(y))-0.5);

    scatter(x,y,marker_size,...
        'filled',...
        'MarkerFaceColor','k',...
        'MarkerFaceAlpha',marker_alpha,...
        'MarkerEdgeColor','none');

    xlim([0.6 1.4]);

    if iscell(xlabels)
        xticks(1)
        xticklabels(xlabels)
    else
        xticks(1)
        xticklabels({xlabels})
    end

else

    %% ---------------- Paired ----------------
    y1 = data1(:);
    y2 = p.Results.PairedData(:);

    valid = isfinite(y1) & isfinite(y2);
    y1 = y1(valid);
    y2 = y2(valid);

    n = numel(y1);

    boxchart(ones(size(y1)),y1,...
        'BoxWidth',box_width,...
        'BoxFaceColor','k',...
        'BoxFaceAlpha',0.12,...
        'BoxEdgeColor','k',...
        'WhiskerLineColor','k',...
        'MarkerStyle','none');

    boxchart(2*ones(size(y2)),y2,...
        'BoxWidth',box_width,...
        'BoxFaceColor','k',...
        'BoxFaceAlpha',0.12,...
        'BoxEdgeColor','k',...
        'WhiskerLineColor','k',...
        'MarkerStyle','none');

    rng(1)

    x1 = 1 + jitter_width*(rand(n,1)-0.5);
    x2 = 2 + jitter_width*(rand(n,1)-0.5);

    for i = 1:n
        plot([x1(i) x2(i)],[y1(i) y2(i)],...
            'Color',[0 0 0 p.Results.LineAlpha],...
            'LineWidth',p.Results.LineWidth);
    end

    scatter(x1,y1,marker_size,...
        'filled',...
        'MarkerFaceColor','k',...
        'MarkerFaceAlpha',marker_alpha,...
        'MarkerEdgeColor','none');

    scatter(x2,y2,marker_size,...
        'filled',...
        'MarkerFaceColor','k',...
        'MarkerFaceAlpha',marker_alpha,...
        'MarkerEdgeColor','none');

    xlim([0.5 2.5]);
    xticks([1 2]);
    xticklabels(xlabels);

end

ylim(ylimits);

if ~isempty(p.Results.ReferenceY)
    yline(p.Results.ReferenceY,'k--','LineWidth',0.5);
end

ylabel(p.Results.YLabel);

box off
set(gca,'TickDir','out');

end