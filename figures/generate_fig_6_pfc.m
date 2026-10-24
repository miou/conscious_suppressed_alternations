data = switches_config_release;
paths = set_paths;
%Make figures
mode='nature';
if strcmp(mode,'poster')
    figure2_panel_height = 1;
    reconstructions_width = 2;
elseif strcmp(mode,'nature')
    figure2_panel_height = 1.15;
    reconstructions_width = 1.7;
end


%Priming
load(release_axes_summary(paths,'priming',''))
define_summary_config_PFC_fig_5;

across_sessions_analysis_axes_aux
summaries.priming.explained_variance_features_cv_high_repeat = explained_variance_features_cv_high_repeat;
summaries.priming.explained_variance_features_cv_high_repeat_other = explained_variance_features_cv_high_repeat_other;
summaries.priming.percentage_correct_cv = percentage_correct_cv;
summaries.priming.percentage_correct_cv_other = percentage_correct_cv_other;
summaries.priming.correct_cv_per_stim = correct_cv_per_stim;
summaries.priming.correct_cvo_per_stim = correct_cvo_per_stim;
summaries.priming.count_per_stim = count_per_stim;
summaries.priming.predicted_features_cv = predicted_features_cv;

%Use LLR
%State 1
load(release_axes_summary(paths,'dominant_binocular','states_Fixed rate LLR PFC 10 ms_1_1'))
define_summary_config_PFC_fig_5;

across_sessions_analysis_axes_aux
summaries.state_1.explained_variance_features_cv_high_repeat = explained_variance_features_cv_high_repeat;
summaries.state_1.explained_variance_features_cv_high_repeat_other = explained_variance_features_cv_high_repeat_other;
summaries.state_1.percentage_correct_cv = percentage_correct_cv;
summaries.state_1.percentage_correct_cv_other = percentage_correct_cv_other;
summaries.state_1.correct_cv_per_stim = correct_cv_per_stim;
summaries.state_1.correct_cvo_per_stim = correct_cvo_per_stim;
summaries.state_1.count_per_stim = count_per_stim;
summaries.state_1.predicted_features_cv = predicted_features_cv;

%State 2
load(release_axes_summary(paths,'dominant_binocular','states_Fixed rate LLR PFC 10 ms_2_1'))
define_summary_config_PFC_fig_5;
across_sessions_analysis_axes_aux
summaries.state_2.explained_variance_features_cv_high_repeat = explained_variance_features_cv_high_repeat;
summaries.state_2.explained_variance_features_cv_high_repeat_other = explained_variance_features_cv_high_repeat_other;
summaries.state_2.percentage_correct_cv = percentage_correct_cv;
summaries.state_2.percentage_correct_cv_other = percentage_correct_cv_other;
summaries.state_2.correct_cv_per_stim = correct_cv_per_stim;
summaries.state_2.correct_cvo_per_stim = correct_cvo_per_stim;
summaries.state_2.count_per_stim = count_per_stim;
summaries.state_2.predicted_features_cv = predicted_features_cv;




figure_folder_name = fullfile(paths.figures_out,'fig_6_pfc');   % release output (define_summary_config_PFC_fig_5 above resets this; set after the last config call)
if ~exist(figure_folder_name,'dir'); mkdir(figure_folder_name); end

%% EV panel
[f, ax, S] = make_standard_figure(mode,'FigureNumber',100, 'HeightInHalfColumnWidths', figure2_panel_height);
plot(100*mean(summaries.priming.explained_variance_features_cv_high_repeat(:,:,end),2),'-','Color',data.state_colors{3})
plot(100*mean(summaries.state_1.explained_variance_features_cv_high_repeat(:,:,end),2),'-','Color',data.state_colors{1})
plot(100*mean(summaries.state_1.explained_variance_features_cv_high_repeat_other(:,:,end),2),'--','Color',data.state_colors{1})
plot(100*mean(summaries.state_2.explained_variance_features_cv_high_repeat(:,:,end),2),'-','Color',data.state_colors{2})
plot(100*mean(summaries.state_2.explained_variance_features_cv_high_repeat_other(:,:,end),2),'--','Color',data.state_colors{2})
set(gca,'ylim',[-100,100])
set(gca,'XLim',[1 50])
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[figure_folder_name filesep 'explained_variance'])
figure(f);

%% Statistical test: is the reconstruction closer to the conscious or the suppressed face?
nf = 50; F = features(:,1:nf); oth = unique_stimulus_index_other_list(:);
HR = find(unique_stimuli_is_high_repeat(:) & isfinite(oth)); pm = zeros(max(HR),1); pm(HR) = 1:numel(HR);
d = @(A,B) sqrt(sum((A-B).^2,2));                                        % Euclidean distance per stimulus (across features)
lean = @(P) d(P(HR,:),F(oth(HR),:)) - d(P(HR,:),F(HR,:));               % + : reconstruction closer to conscious than suppressed
q = lean(summaries.state_1.predicted_features_cv(:,1:nf)) - lean(summaries.state_2.predicted_features_cv(:,1:nf));
pk = red_cyan_pair_indices(all(ismember(red_cyan_pair_indices,HR),2),:); % high-repeat stimulus pairs
qpair = 0.5*(q(pm(pk(:,1))) + q(pm(pk(:,2))));                          % one score per pair (n=30, independent)
[~,p,~,st] = ttest(qpair);   % paired t-test against zero over the n=30 pairs = the statistic reported in the paper
fprintf('Reconstruction dissociation: t(%d)=%.1f, p=%.2e (n=%d pairs)\n', st.df, st.tstat, p, numel(qpair));

%% Decoding bars (debug figure, not a saved panel)
% figure(1);clf;
% bar_with_std(1:4,[summaries.state_1.percentage_correct_cv(10,:)',summaries.state_2.percentage_correct_cv(10,:)',summaries.state_1.percentage_correct_cv_other(10,:)',summaries.state_2.percentage_correct_cv_other(10,:)']) ;set(gca,'ylim',[0 1]);box off;set(gca,'xlim',[0 5]);h = gca;h.XAxis.Visible = 'off';


%% Decoding curve panel
[f, ax, S] = make_standard_figure(mode,'FigureNumber',201, 'HeightInHalfColumnWidths', figure2_panel_height);
[p,errorarea]=plot_with_std(number_of_stimuli_for_decoding_list,100*summaries.priming.percentage_correct_cv(:,:,end)');p.LineStyle='-';p.Color = data.state_colors{3};errorarea.FaceColor=data.state_colors{3};
[p,errorarea]=plot_with_std(number_of_stimuli_for_decoding_list,100*summaries.state_1.percentage_correct_cv(:,:,end)');p.LineStyle='-';p.Color = data.state_colors{1};errorarea.FaceColor=data.state_colors{1};
[p,errorarea]=plot_with_std(number_of_stimuli_for_decoding_list,100*summaries.state_1.percentage_correct_cv_other(:,:,end)');p.LineStyle='--';p.Color = data.state_colors{1};errorarea.FaceColor=data.state_colors{1};
[p,errorarea]=plot_with_std(number_of_stimuli_for_decoding_list,100*summaries.state_2.percentage_correct_cv(:,:,end)');p.LineStyle='-';p.Color = data.state_colors{2};errorarea.FaceColor=data.state_colors{2};
[p,errorarea]=plot_with_std(number_of_stimuli_for_decoding_list,100*summaries.state_2.percentage_correct_cv_other(:,:,end)');p.LineStyle='--';p.Color = data.state_colors{2};errorarea.FaceColor=data.state_colors{2};
ylim([0 100])
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[figure_folder_name filesep 'euclidean_decoding'])


%% Statistical test for decoding: 
% Stimulus-level tests (each high-repeat identity is the unit). Primary = double dissociation (interaction),
% paired by stimulus across states; one-sided since the direction is predicted a priori.
min_samples_per_stim = 20;
s1 = summaries.state_1; s2 = summaries.state_2;
a1 = s1.correct_cv_per_stim ./ s1.count_per_stim;  b1 = s1.correct_cvo_per_stim ./ s1.count_per_stim;
a2 = s2.correct_cv_per_stim ./ s2.count_per_stim;  b2 = s2.correct_cvo_per_stim ./ s2.count_per_stim;
sel = s1.count_per_stim >= min_samples_per_stim & s2.count_per_stim >= min_samples_per_stim;
% Decoding double dissociation = two-sided sign-flip permutation over the n=30 stimulus
% pairs (the single test reported in the paper).
delta_all = (a1(:)-b1(:)) - (a2(:)-b2(:));
pk_dec = red_cyan_pair_indices(all(ismember(red_cyan_pair_indices, find(sel(:))),2),:);
d1 = delta_all(pk_dec(:,1)); d2 = delta_all(pk_dec(:,2));
vv = isfinite(d1) & isfinite(d2); d1 = d1(vv); d2 = d2(vv); npd = numel(d1); B = 1e5;
xp = 0.5*(d1(:)+d2(:));
p30 = (1 + sum(abs(mean(xp .* (2*(rand(npd,B)>0.5)-1),1)) >= abs(mean(xp)))) / (B+1);
fprintf('Double dissociation (decoding): sign-flip p=%.2g (n=%d pairs)\n', p30, npd);


%% Reconstructions
[f, ax, S] = make_standard_figure(mode,'FigureNumber',300,  'WidthInHalfColumns', reconstructions_width,'GridSize', [5 4]);
ax = plot_reconstruction_examples_grid( f, S,...
    config, xml_folder, xml_filename, stimulus_list, priming_stimuli, folder_name, features, summaries.state_1.predicted_features_cv, summaries.state_2.predicted_features_cv, ...
    unique_stimuli, unique_stimulus_index_other_list, unique_stimuli_is_high_repeat, red_cyan_pair_indices);
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[figure_folder_name filesep 'reconstructions'])



