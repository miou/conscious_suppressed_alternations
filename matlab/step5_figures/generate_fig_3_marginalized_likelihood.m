%% generate_fig_3_marginalized_likelihood.m
% Box-and-whisker (Nature style) of Conor's per-record MARGINALIZED log-likelihood gain of the
% 2-state model over the 1-state model. Real only (no shuffle control). One value per record
% (n = 19) = mll_2s - mll_1s, the model log-likelihood marginalized over the latent state sequence.
% Statistical unit = record (session/probe). Signrank and t-test vs 0.
% Input: data/python_summaries/marg_loglik.mat (shipped; produced by the Python pipeline).
% Style matches generate_fig_3_likelihood.m.

paths = set_paths;
mode = 'nature';
figure_folder_name = fullfile(paths.figures_out,'fig_3_half_neurons'); if ~exist(figure_folder_name,'dir'); mkdir(figure_folder_name); end
loglik_file        = fullfile(paths.python_summaries,'marg_loglik.mat');

%% Load Conor's per-record marginalized log-likelihoods
R    = load(loglik_file);
vals = R.diff_real(:);                 % mll_2s - mll_1s per record (marginalized model log-likelihood gain)
n    = numel(vals);

%% Statistics (record is the unit)
[~,p_t,~,st] = ttest(vals);            % two-sided t-test vs 0 = the statistic reported in the paper (Fig 3a)
fprintf('Marginalized LL 2-state - 1-state (n=%d records): mean=%.4f, median=%.4f, %d/%d > 0\n', ...
    n, mean(vals), median(vals), sum(vals>0), n);
fprintf('t(%d)=%.2f, p=%.2e\n', st.df, st.tstat, p_t);

%% Box-and-whisker panel (single box, dark, beeswarm)
col = [0.15 0.15 0.15];
[f,ax,S] = make_standard_figure(mode,'FigureNumber',443,'HeightInHalfColumnWidths',0.58,'WidthInHalfColumns',0.5);
hold(ax,'on'); rng(1);
plot(ax,[0.4 1.6],[0 0],'--','Color',[0.5 0.5 0.5],'LineWidth',S.reference_line_width);

XJ = beeswarm_x(vals,1,0.06,0.02) + (rand(n,1)-0.5)*0.03;
bc = boxchart(ax,ones(n,1),vals,'BoxWidth',0.5,'MarkerStyle','none', ...
    'BoxFaceColor',col,'WhiskerLineColor',col,'LineWidth',S.line_width);
bc.BoxFaceAlpha = 0.30;
scatter(ax,XJ,vals,5,'filled','MarkerFaceColor',col,'MarkerFaceAlpha',0.85,'MarkerEdgeColor','none');

set(ax,'xlim',[0.4 1.6],'ylim',[-0.05 0.8]); xticks(ax,[]);
yticks(ax,0:0.2:0.8); ax.YAxis.Exponent = 0;
ylabel(ax,'Model log likelihood (2-state - 1-state)');
finish_standard_figure(f,ax,S,'ExportEMF',true,'ExportPNG',true, ...
    'OutputBase',[figure_folder_name filesep 'marginalized_loglikelihood']);
disp('generate_fig_3_marginalized_likelihood done');

%% ---- local functions ----
function xj = beeswarm_x(y,center,dx,ybin)
% deterministic beeswarm: points sharing a y-band are fanned symmetrically around `center`
    y = y(:); n = numel(y); xj = center*ones(n,1);
    [~,ord] = sort(y); edges = min(y)-1e-9:ybin:max(y)+ybin;
    if numel(edges) < 2, edges = [min(y)-1e-9 max(y)+ybin]; end
    b = discretize(y,edges);
    for k = 1:max(b)
        idx = ord(b(ord)==k); m = numel(idx);
        xj(idx) = center + ((1:m)'-(m+1)/2)*dx;
    end
end
