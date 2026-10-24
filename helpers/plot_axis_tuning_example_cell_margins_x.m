    bins_x = bins_x_range(1):bin_size:bins_x_range(2);
    response_mean_bin_x = nan(1,length(bins_x));
    response_std_bin_x = nan(1,length(bins_x));
    for bin_index = 1:length(bins_x)
        bin_start = bins_x(bin_index) - bin_size/2;
        bin_end = bins_x(bin_index) + bin_size/2;
        b_points_in_bin = preferred_axis_responses>=bin_start & preferred_axis_responses<bin_end;
        response_mean_bin_x(bin_index) = mean(responses(b_points_in_bin));
        response_std_bin_x(bin_index) = std(responses(b_points_in_bin))/sqrt(sum(b_points_in_bin));
    end
    hh=errorbar(bins_x,response_mean_bin_x,response_std_bin_x,'k.','LineStyle','none','LineWidth',0.5); hold on; p=plot(bins_x,response_mean_bin_x,'k.-','LineWidth',1.0);
    set(gca,"XLim",scatter_xlim);set(gca,'YLim',margin_range);
    if x_lim_total_range;set(gca,'Xlim',x_lim_total_range);end;if y_lim_total_range;set(gca,'Ylim',y_lim_total_range);end
