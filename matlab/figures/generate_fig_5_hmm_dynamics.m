paths = set_paths;
hmm_loglik_dwell= load(fullfile(paths.conor_summaries,'flash_suppression_conor','hmm_loglik_dwell_20260811.mat'));
figure_folder_name = paths.figures_out;
data = switches_config_release;

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
p.Color = data.state_colors{1};errorarea.FaceColor=data.state_colors{1};p.LineStyle='-';p.LineWidth=S.line_width;p.Marker='o';p.MarkerSize=2;
ax.XScale = 'log';
xticks([2 3 5 10 20 50 100])
ax.XTickLabelRotation = 0;
set(gca,'xlim',[1.9 100])
set(gca,'ylim',[0 200])

[p,errorarea]=plot_with_sem(hmm_loglik_dwell.bin_size_vals, hmm_loglik_dwell.dt_median_2);
p.Color = data.state_colors{2};errorarea.FaceColor=data.state_colors{2};p.LineStyle='-';p.LineWidth=S.line_width;p.Marker='o';p.MarkerSize=2;
ax.XScale = 'log';
xticks([2 3 5 10 20 50 100])
ax.XTickLabelRotation = 0;
set(gca,'xlim',[1.9 100])
set(gca,'ylim',[0 200])
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[figure_folder_name filesep 'median_dwell_state_1_state_2_bin_size'])

%Dwell vs likelihood

hmm_loglik_dwell_2= load(fullfile(paths.conor_summaries,'flash_suppression_conor','hmm_loglik_dwell_20260826.mat'));
[f, ax, S] = make_standard_figure( mode, 'FigureNumber',702, 'WidthInHalfColumns',1, 'HeightInHalfColumnWidths',1);

x = hmm_loglik_dwell_2.hist_bin_centers;
[p,errorarea]=boundedline(x,hmm_loglik_dwell_2.hist_loglik_mean_1,...
    hmm_loglik_dwell_2.hist_loglik_sem_1,'alpha');
p.Color = data.state_colors{1};errorarea.FaceColor=data.state_colors{1};p.LineStyle='-';p.LineWidth=S.line_width;p.Marker='o';p.MarkerSize=2;
x = hmm_loglik_dwell_2.hist_bin_centers;
[p,errorarea]=boundedline(x,hmm_loglik_dwell_2.hist_loglik_mean_2,...
    hmm_loglik_dwell_2.hist_loglik_sem_2,'alpha');
p.Color = data.state_colors{2};errorarea.FaceColor=data.state_colors{2};p.LineStyle='-';p.LineWidth=S.line_width;p.Marker='o';p.MarkerSize=2;
xlim([0 250])
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[figure_folder_name filesep 'loglikelihood_dwell_time'])



autocorr = load(fullfile(paths.misc,'acorr_projection.mat'));   % projection onto (conscious - suppressed) priming axis


[f, ax, S] = make_standard_figure(mode,'FigureNumber',802,'HeightInHalfColumnWidths',1,'WidthInHalfColumns',1);

lags             = double(autocorr.lags(:)');
acorr_binoc_norm = autocorr.acorr_binoc_norm;

[p,errorarea] = plot_with_std(lags, autocorr.acorr_binoc_shuffle_norm);
p.Color=[.5 .5 .5]; errorarea.FaceColor=[.5 .5 .5];

[p,errorarea] = plot_with_std(lags, acorr_binoc_norm);
p.Color='k'; errorarea.FaceColor='k';

% --- dwell time: R(t) = rho*exp(-2t/D), fit 10-90 ms (bin edge to zero-crossing), amplitude free ---
acm  = double(mean(acorr_binoc_norm,1));
sel  = lags>=10 & lags<=90;
xfit = double(lags(sel));  yfit = double(acm(sel));
obj  = @(pp) sum((pp(1)*exp(-2*xfit/pp(2)) - yfit).^2);   % pp = [rho, D]
pp   = fminsearch(obj,[0.4 50]);
rho  = pp(1);  D = pp(2);
fprintf('projection autocorrelation: rho = %.2f, dwell time D = %.1f ms (median ~ %.0f ms)\n', rho, D, D*log(2));

hold(ax,'on');
S.xline(D)
text(ax, D, 0.9, sprintf('  D = %.0f ms', D), 'Color','r', 'FontName',S.font_name, 'FontSize',S.font_size);

set(gca,'xlim',[0 200])
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[figure_folder_name filesep 'projection_autocorrelation'])