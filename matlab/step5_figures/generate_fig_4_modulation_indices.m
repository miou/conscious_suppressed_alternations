%% Figure 4g -- modulation indices using the held-out half of neurons.
% Four panels: average activity, state 1, state 2, and the gain-equalized average.
% States are inferred from one random half of neurons and the modulation indices are
% measured on the held-out half (n = 2885 cell-stimulus pairs), as in Fig. 3.
paths = set_paths;
rivalry_config = switches_config_release;
mode = 'nature';

%LLR IT (held-out half)
summary_state_1 = load(release_modulation_summary(paths,'Fixed rate LLR IT 10 ms half neurons',1));
summary_state_2 = load(release_modulation_summary(paths,'Fixed rate LLR IT 10 ms half neurons',2));
regions_to_plot = {'ML','AM','all'}; %Only ML and AM for all
outputfolder = fullfile(paths.figures_out,'fig_4_modulation_indices'); if ~exist(outputfolder,'dir'); mkdir(outputfolder); end
context_significance = 'priming';
context_combinations = {{'unambiguous','binocular'}};

marker_size = 3;

across_sessions_many_combinations_slopes
if strcmp(mode,'poster')
    panel_size = 0.6;
    marker_face_alpha=0.25;marker_edge_alpha=0.3; %Thinnest
elseif strcmp(mode,'nature')
    panel_size = 0.68;   %Figure 4
    marker_size = 0.5;
    marker_face_alpha=1;marker_edge_alpha=1;

end

compute_slope = @(x,y)tls_slope(x,y);

b_compute_for_state = 0;
across_sessions_analysis_all_combinations_modulation_aux
[f, ax, S] = make_standard_figure(mode,'FigureNumber',701, 'HeightInHalfColumnWidths', panel_size, 'WidthInHalfColumns', panel_size);
scatter(modulation_indices_context_1_significant_1{regions_to_plot_index},modulation_indices_context_2_significant_1{regions_to_plot_index},marker_size,'filled','MarkerFaceColor','k','MarkerFaceAlpha',marker_face_alpha,'MarkerEdgeAlpha',marker_edge_alpha);
plot([-1 1], [-1 1],'k--','LineWidth',S.reference_line_width);plot([0 0], [-1 1],'k--','LineWidth',S.reference_line_width);plot( [-1 1],[0 0],'k--','LineWidth',S.reference_line_width);axis square;
set(gca,'xlim',[-1 1]);set(gca,'ylim',[-1 1]);xticks(-1:1);yticks(-1:1)
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'modulation_all_states']);figure(f);
[~,p_average_modulation,~,st] = ttest(modulation_indices_context_1_significant_1{regions_to_plot_index},modulation_indices_context_2_significant_1{regions_to_plot_index})  % paired t-test on average modulation
[r_average,p_average] = corrcoef(modulation_indices_context_1_significant_1{regions_to_plot_index},modulation_indices_context_2_significant_1{regions_to_plot_index},'Rows','complete')
x=modulation_indices_context_1_significant_1{regions_to_plot_index}; y=modulation_indices_context_2_significant_1{regions_to_plot_index}; ii=~isnan(x)&~isnan(y)&(x>-1)&(y>-1)&(x<1)&(y<1); b=compute_slope(x(ii),y(ii));
slope_average=b(1)

b_compute_for_state = 1;
across_sessions_analysis_all_combinations_modulation_aux
[f, ax, S] = make_standard_figure(mode,'FigureNumber',702, 'HeightInHalfColumnWidths', panel_size, 'WidthInHalfColumns', panel_size);
scatter(modulation_indices_context_1_significant_1{regions_to_plot_index},modulation_indices_context_2_significant_1{regions_to_plot_index},marker_size,'filled','MarkerFaceColor','k','MarkerFaceAlpha',marker_face_alpha,'MarkerEdgeAlpha',marker_edge_alpha);
plot([-1 1], [-1 1],'k--','LineWidth',S.reference_line_width);plot([0 0], [-1 1],'k--','LineWidth',S.reference_line_width);plot( [-1 1],[0 0],'k--','LineWidth',S.reference_line_width);axis square;
set(gca,'xlim',[-1 1]);set(gca,'ylim',[-1 1]);xticks(-1:1);yticks(-1:1)
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'modulation_state_1']);figure(f);
[r_state_1,p_state_1] = corrcoef(modulation_indices_context_1_significant_1{regions_to_plot_index},modulation_indices_context_2_significant_1{regions_to_plot_index},'Rows','complete')
[pstr, log10p] = pearson_p(r_state_1(2),length(modulation_indices_context_1_significant_1{regions_to_plot_index}))
x=modulation_indices_context_1_significant_1{regions_to_plot_index}; y=modulation_indices_context_2_significant_1{regions_to_plot_index}; ii=~isnan(x)&~isnan(y)&(x>-1)&(y>-1)&(x<1)&(y<1); b=compute_slope(x(ii),y(ii));
slope_state_1=b(1)

b_compute_for_state = 2;
across_sessions_analysis_all_combinations_modulation_aux
[f, ax, S] = make_standard_figure(mode,'FigureNumber',703, 'HeightInHalfColumnWidths', panel_size, 'WidthInHalfColumns', panel_size);
scatter(modulation_indices_context_1_significant_1{regions_to_plot_index},modulation_indices_context_2_significant_1{regions_to_plot_index},marker_size,'filled','MarkerFaceColor','k','MarkerFaceAlpha',marker_face_alpha,'MarkerEdgeAlpha',marker_edge_alpha);
plot([-1 1], [1 -1],'k--','LineWidth',S.reference_line_width);plot([0 0], [-1 1],'k--','LineWidth',S.reference_line_width);plot( [-1 1],[0 0],'k--','LineWidth',S.reference_line_width);axis square;
set(gca,'xlim',[-1 1]);set(gca,'ylim',[-1 1]);xticks(-1:1);yticks(-1:1)
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'modulation_state_2']);figure(f);
[r_state_2,p_state_2] = corrcoef(modulation_indices_context_1_significant_1{regions_to_plot_index},modulation_indices_context_2_significant_1{regions_to_plot_index},'Rows','complete')
[pstr, log10p] = pearson_p(r_state_2(2),length(modulation_indices_context_1_significant_1{regions_to_plot_index}))
x=modulation_indices_context_1_significant_1{regions_to_plot_index}; y=modulation_indices_context_2_significant_1{regions_to_plot_index}; ii=~isnan(x)&~isnan(y)&(x>-1)&(y>-1)&(x<1)&(y<1); b=compute_slope(x(ii),y(ii));
slope_state_2=b(1)

b_compute_for_state = 5;
across_sessions_analysis_all_combinations_modulation_aux
[f, ax, S] = make_standard_figure(mode,'FigureNumber',704, 'HeightInHalfColumnWidths', panel_size, 'WidthInHalfColumns', panel_size);
scatter(modulation_indices_context_1_significant_1{regions_to_plot_index},modulation_indices_context_2_significant_1{regions_to_plot_index},marker_size,'filled','MarkerFaceColor','k','MarkerFaceAlpha',marker_face_alpha,'MarkerEdgeAlpha',marker_edge_alpha);
plot([-1 1], [-1 1],'k--','LineWidth',S.reference_line_width);plot([0 0], [-1 1],'k--','LineWidth',S.reference_line_width);plot( [-1 1],[0 0],'k--','LineWidth',S.reference_line_width);axis square;
set(gca,'xlim',[-1 1]);set(gca,'ylim',[-1 1]);xticks(-1:1);yticks(-1:1)
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'modulation_slope_equalized']);figure(f);
[r_slope_equalized,p_slope_equalized] = corrcoef(modulation_indices_context_1_significant_1{regions_to_plot_index},modulation_indices_context_2_significant_1{regions_to_plot_index},'Rows','complete')
x=modulation_indices_context_1_significant_1{regions_to_plot_index}; y=modulation_indices_context_2_significant_1{regions_to_plot_index}; ii=~isnan(x)&~isnan(y)&(x>-1)&(y>-1)&(x<1)&(y<1); b=compute_slope(x(ii),y(ii));
slope_slope_equalized=b(1)

slope_average
slope_state_1
slope_state_2
slope_slope_equalized
