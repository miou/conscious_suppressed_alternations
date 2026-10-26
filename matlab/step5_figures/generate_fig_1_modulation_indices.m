%% Modulation index panel


paths = set_paths;
rivalry_config = switches_config_release;
mode = 'nature';
%LLR IT
summary_state_1 = load(release_modulation_summary(paths,'Fixed rate LLR IT 10 ms half neurons',1));
summary_state_2 = load(release_modulation_summary(paths,'Fixed rate LLR IT 10 ms half neurons',2));
regions_to_plot = {'ML','AM','all'}; %Only ML and AM for all
outputfolder = fullfile(paths.figures_out,'fig_1_modulation_indices');
if ~exist(outputfolder,'dir'); mkdir(outputfolder); end

context_significance = 'priming';
context_combinations = {{'unambiguous','binocular'}};

ReferenceLineWidth = 0.5;

% Modulation indices slope fso, currently HMM
% (only needed for the slope-equalized variant -- Fig 4 -- not the Fig 1 index panel)
% across_sessions_many_combinations_slopes
if strcmp(mode,'poster')
    panel_size = 0.6;
    marker_size = 3;
    marker_face_alpha=0.25;marker_edge_alpha=0.3; %Thinnest
elseif strcmp(mode,'nature')
    panel_size = 1;   %Figure 1
    marker_size = 0.75;
    marker_face_alpha=1;marker_edge_alpha=1; %Thinnest
end
b_compute_for_state = 0;
b_use_full_population = 1;  % Fig 1h is a condition comparison (not state-conditioned) -> full population (paper: n=5550 cell-stimulus pairs), skip the held-out-half filter
across_sessions_analysis_all_combinations_modulation_aux
[f, ax, S] = make_standard_figure(mode,'FigureNumber',701, 'HeightInHalfColumnWidths', panel_size, 'WidthInHalfColumns', panel_size);
scatter(modulation_indices_context_1_significant_1{regions_to_plot_index},modulation_indices_context_2_significant_1{regions_to_plot_index},marker_size,'filled','MarkerFaceColor','k','MarkerFaceAlpha',marker_face_alpha,'MarkerEdgeAlpha',marker_edge_alpha);
plot([-1 1], [-1 1],'k--','LineWidth',ReferenceLineWidth);plot([0 0], [-1 1],'k--','LineWidth',ReferenceLineWidth);plot( [-1 1],[0 0],'k--','LineWidth',ReferenceLineWidth);axis square;%set(gca,'XLim',[-1 1]);set(gca,'YLim',[-1 1]);xticks(-1:.5:1);yticks(-1:.5:1);set(gca,'xticklabels','');set(gca,'yticklabels','')
set(gca,'xlim',[-1 1]);set(gca,'ylim',[-1 1]);xticks(-1:1);yticks(-1:1)
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'modulation_all_states']);figure(f);
[~,p_average_modulation,~,st_average_modulation] = ttest(modulation_indices_context_1_significant_1{regions_to_plot_index},modulation_indices_context_2_significant_1{regions_to_plot_index})
[r_average,p_average] = corrcoef(modulation_indices_context_1_significant_1{regions_to_plot_index},modulation_indices_context_2_significant_1{regions_to_plot_index},'Rows','complete')
fprintf('Fig 1h paired modulation (unambiguous vs binocular), full population: t(%d)=%.2f, p=%.3e, n=%d cell-stimulus pairs\n', st_average_modulation.df, st_average_modulation.tstat, p_average_modulation, st_average_modulation.df+1);
