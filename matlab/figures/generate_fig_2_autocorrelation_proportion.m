%% plot autocorrelation and proportion
mode = 'nature';
paths = set_paths;
rivalry_config = switches_config_release;

figure_folder_name = paths.figures_out;

fig_height   = 0.5;                % HeightInHalfColumnWidths 
fig_width    = 0.9;                 % WidthInHalfColumns


proportion_psth = load(fullfile(paths.conor_summaries,'flash_suppression_conor','state_psth_20260812_all.mat'));

autocorr = load(fullfile(paths.conor_summaries,'flash_suppression_conor','acorr_20261014.mat'));

[f, ax, S] = make_standard_figure(mode,'FigureNumber',800,'HeightInHalfColumnWidths',fig_height,'WidthInHalfColumns',fig_width);
[p,errorarea] = plot_with_std(double(proportion_psth.t_flash)/1000,100*proportion_psth.frac_dom);
p.Color=rivalry_config.state_colors{1};errorarea.FaceColor=rivalry_config.state_colors{1};
[p,errorarea] = plot_with_std(double(proportion_psth.t_flash)/1000,100-100*proportion_psth.frac_dom);
p.Color=rivalry_config.state_colors{2};errorarea.FaceColor=rivalry_config.state_colors{2};

S.yline(50)
S.xline(0)
set(gca,'ylim',[0 100])
yticks([0 25 50 75 100])
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[figure_folder_name filesep 'proportion_psth'])


fig_height   = 0.58;                % HeightInHalfColumnWidths 
fig_width    = 0.9;                 % WidthInHalfColumns 


[f, ax, S] = make_standard_figure(mode,'FigureNumber',801,'HeightInHalfColumnWidths',fig_height,'WidthInHalfColumns',fig_width);

[p,errorarea] = plot_with_std(autocorr.lags,autocorr.acorr_binoc_shuffle_norm);
p.Color=[.5 .5 .5];errorarea.FaceColor=[.5 .5 .5];

[p,errorarea] = plot_with_std(autocorr.lags,autocorr.acorr_binoc_norm);
p.Color='k';errorarea.FaceColor='k';


% --- dwell time from the free-amplitude two-state autocorrelation:  R(t) = rho*exp(-2t/D) ---
% fit the slow regime only: 10 ms (bin edge; below it is the within-bin triangle) to 90 ms (before zero-crossing).
% rho (free amplitude) absorbs the per-bin spiking noise; D is the mean dwell time.
acm  = double(mean(autocorr.acorr_binoc_norm,1));                % mean over sessions
sel  = autocorr.lags>=10 & autocorr.lags<=90;
xfit = double(autocorr.lags(sel));  yfit = double(acm(sel));     % force double so exp() is happy
obj  = @(pp) sum((pp(1)*exp(-2*xfit/pp(2)) - yfit).^2); % pp = [rho, D]
pp   = fminsearch(obj,[0.5 60]);
rho  = pp(1);  D = pp(2);                               % D = mean dwell time (ms)
fprintf('log-likelihood autocorrelation: rho = %.2f, dwell time D = %.1f ms (median ~ %.0f ms)\n', rho, D, D*log(2));

% overlay the fit and mark the dwell time
S.xline(D)


set(gca,'xlim',[0 200])
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[figure_folder_name filesep 'loglikelihood_autocorrelation'])







