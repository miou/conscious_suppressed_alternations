function plot_paired_bar(responses_sober, responses_psychedelic,limits,xlabelstring,ylabelstring,title_string)

    % === Appearance Settings ===
    bar_colors = [0 0 0; 1 0 1];       % [black; magenta]
    bar_colors = [252, 174, 52;84, 51, 121]/255;
    marker_size = 30;
    bar_alpha = 0.5;
    point_alpha = 0.5;
    line_alpha = 0.2;
    jitter_strength = 0.1;
    title_fontsize       = 18;  % (optional if title is used)
    tick_fontsize        = 18;
    axis_label_fontsize = 18;


    % === Clean Data ===
    x = responses_sober(:);
    y = responses_psychedelic(:);
    valid = ~isnan(x) & ~isnan(y);
    x = x(valid);
    y = y(valid);
    n = numel(x);

    % === Summary Statistics ===
    means = [mean(x), mean(y)];
    sems = [std(x)/sqrt(n), std(y)/sqrt(n)];


    % === Bar Plot with SEM ===
    b = bar([1 2], means, 0.6, 'FaceColor', 'flat');
    b.CData = bar_colors;
    b.FaceAlpha = bar_alpha;
    errorbar([1 2], means, sems, 'k', 'LineStyle', 'none', 'LineWidth', 1.2);

    % === Jitter for Points ===
    jittered_x1 = 1 + (randn(n,1) * jitter_strength);
    jittered_x2 = 2 + (randn(n,1) * jitter_strength);

    % === Connecting Lines ===
    for i = 1:n
        plot([jittered_x1(i), jittered_x2(i)], [x(i), y(i)], '-', ...
            'Color', [0.5 0.5 0.5 line_alpha]);  % light gray transparent
    end

    % === Scatter Points ===
    scatter(jittered_x1, x, marker_size, ...
        bar_colors(1,:), 'filled', 'MarkerFaceAlpha', point_alpha, 'MarkerEdgeAlpha', point_alpha);
    scatter(jittered_x2, y, marker_size, ...
        bar_colors(2,:), 'filled', 'MarkerFaceAlpha', point_alpha, 'MarkerEdgeAlpha', point_alpha);

    % === Axes and Labels ===
    xlim([0.5 2.5]);
    xticks([1 2]);
    if ~isempty(limits)
        set(gca,'ylim',limits)
    end
    if nargin>3
        xticklabels({xlabelstring,ylabelstring});

    end
    if nargin>5
        title(title_string, 'FontSize', title_fontsize);
    end

    set(gca, 'FontSize', tick_fontsize, 'TickDir', 'out', 'Box', 'off');
end
