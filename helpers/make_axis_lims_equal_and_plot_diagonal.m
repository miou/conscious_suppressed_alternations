function make_axis_lims_equal_and_plot_diagonal
    xlims = xlim;
    ylims = ylim;
    limmin = min([xlims ylims]);
    limmax = max([xlims ylims]);
    plot([limmin limmax],[limmin limmax],'--','Color',[.5 .5 .5]);
    set(gca,'xlim',[limmin limmax]);set(gca,'ylim',[limmin limmax])
    axis equal
