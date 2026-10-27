paths = set_paths;
hmm_loglik_dwell= load(fullfile(paths.python_summaries,'hmm_loglik_dwell_20260811.mat'));
figure_folder_name = fullfile(paths.figures_out,'fig5'); if ~exist(figure_folder_name,'dir'); mkdir(figure_folder_name); end
rivalry_config = switches_config_release;

mode = 'nature';

[f, ax, S] = make_standard_figure( mode, 'FigureNumber',601, 'WidthInHalfColumns',1, 'HeightInHalfColumnWidths',1/2.5);

[p,errorarea]=plot_with_sem(hmm_loglik_dwell.bin_size_vals, hmm_loglik_dwell.loglik_rel);
p.Color = 'k';errorarea.FaceColor='k';p.LineStyle='-';p.LineWidth=S.line_width;p.Marker='o';p.MarkerSize=2;
ax.XScale = 'log';
xticks([2 3 5 10 20 50 100])
ax.XTickLabelRotation = 0;
set(gca,'xlim',[1.9 100])
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[figure_folder_name filesep 'loglikelihood_bin_size'])

[f, ax, S] = make_standard_figure( mode, 'FigureNumber',604, 'WidthInHalfColumns',1, 'HeightInHalfColumnWidths',1/2.5);

[p,errorarea]=plot_with_sem(hmm_loglik_dwell.bin_size_vals, hmm_loglik_dwell.dt_median_1);
p.Color = rivalry_config.state_colors{1};errorarea.FaceColor=rivalry_config.state_colors{1};p.LineStyle='-';p.LineWidth=S.line_width;p.Marker='o';p.MarkerSize=2;
ax.XScale = 'log';
xticks([2 3 5 10 20 50 100])
ax.XTickLabelRotation = 0;
set(gca,'xlim',[1.9 100])
set(gca,'ylim',[0 200])

[p,errorarea]=plot_with_sem(hmm_loglik_dwell.bin_size_vals, hmm_loglik_dwell.dt_median_2);
p.Color = rivalry_config.state_colors{2};errorarea.FaceColor=rivalry_config.state_colors{2};p.LineStyle='-';p.LineWidth=S.line_width;p.Marker='o';p.MarkerSize=2;
ax.XScale = 'log';
xticks([2 3 5 10 20 50 100])
ax.XTickLabelRotation = 0;
set(gca,'xlim',[1.9 100])
set(gca,'ylim',[0 200])
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[figure_folder_name filesep 'median_dwell_state_1_state_2_bin_size'])

%Dwell vs likelihood

hmm_loglik_dwell_2= load(fullfile(paths.python_summaries,'hmm_loglik_dwell_20260826.mat'));
[f, ax, S] = make_standard_figure( mode, 'FigureNumber',702, 'WidthInHalfColumns',1, 'HeightInHalfColumnWidths',1);

x = hmm_loglik_dwell_2.hist_bin_centers;
[p,errorarea]=boundedline(x,hmm_loglik_dwell_2.hist_loglik_mean_1,...
    hmm_loglik_dwell_2.hist_loglik_sem_1,'alpha');
p.Color = rivalry_config.state_colors{1};errorarea.FaceColor=rivalry_config.state_colors{1};p.LineStyle='-';p.LineWidth=S.line_width;p.Marker='o';p.MarkerSize=2;
x = hmm_loglik_dwell_2.hist_bin_centers;
[p,errorarea]=boundedline(x,hmm_loglik_dwell_2.hist_loglik_mean_2,...
    hmm_loglik_dwell_2.hist_loglik_sem_2,'alpha');
p.Color = rivalry_config.state_colors{2};errorarea.FaceColor=rivalry_config.state_colors{2};p.LineStyle='-';p.LineWidth=S.line_width;p.Marker='o';p.MarkerSize=2;
xlim([0 250])
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[figure_folder_name filesep 'loglikelihood_dwell_time'])



