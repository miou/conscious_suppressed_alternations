paths = set_paths;
rivalry_config = switches_config_release;
data = rivalry_config;   % the plotting code below uses data.state_colors
%Make figures
mode='nature';
if strcmp(mode,'poster')
    figure2_panel_height = 1;
    % reconstructions_height = 1;
    reconstructions_width = 2;
elseif strcmp(mode,'nature')
    figure2_panel_height = 1.15;
    % reconstructions_height = 1;
    reconstructions_width = 1.7;
end


%Priming
load(release_axes_summary(paths,'priming',''))
define_summary_config_ML_AM_fig_2
regions_to_include = {'AM'};
% load("Z:\session_summaries\flash_suppression_axes\trained_priming_tested_priming\_avgdim_0\summary_trained_priming_tested_priming__avgdim_0.mat")
% define_summary_config_PFC_fig_5;
% summary_config.cell_proportion = 0.5; %To match half neurons
across_sessions_analysis_axes_aux
summaries.priming.explained_variance_features_cv_high_repeat = explained_variance_features_cv_high_repeat;
summaries.priming.explained_variance_features_cv_high_repeat_other = explained_variance_features_cv_high_repeat_other;
summaries.priming.percentage_correct_cv = percentage_correct_cv;
summaries.priming.percentage_correct_cv_other = percentage_correct_cv_other;
summaries.priming.predicted_features_cv = predicted_features_cv;
% summary_config = rmfield(summary_config,'cell_proportion');

%Use LLR
%State 1
load(release_axes_summary(paths,'dominant_binocular','states_Fixed rate HMM ML_1_1'))
define_summary_config_ML_AM_fig_2
regions_to_include = {'AM'};
% load('Z:\session_summaries\flash_suppression_axes\trained_priming_tested_dominant_binocular\states_Fixed rate LLR PFC 10 ms_1_1_avgdim_0\summary_trained_priming_tested_dominant_binocular_states_Fixed rate LLR PFC 10 ms_1_1_avgdim_0.mat')
% define_summary_config_PFC_fig_5;

across_sessions_analysis_axes_aux
summaries.state_1.explained_variance_features_cv_high_repeat = explained_variance_features_cv_high_repeat;
summaries.state_1.explained_variance_features_cv_high_repeat_other = explained_variance_features_cv_high_repeat_other;
summaries.state_1.percentage_correct_cv = percentage_correct_cv;
summaries.state_1.percentage_correct_cv_other = percentage_correct_cv_other;
summaries.state_1.predicted_features_cv = predicted_features_cv;

%State 2
load(release_axes_summary(paths,'dominant_binocular','states_Fixed rate HMM ML_2_1'))
define_summary_config_ML_AM_fig_2
regions_to_include = {'AM'};
% load('Z:\session_summaries\flash_suppression_axes\trained_priming_tested_dominant_binocular\states_Fixed rate LLR PFC 10 ms_2_1_avgdim_0\summary_trained_priming_tested_dominant_binocular_states_Fixed rate LLR PFC 10 ms_2_1_avgdim_0.mat')
% define_summary_config_PFC_fig_5;
across_sessions_analysis_axes_aux
summaries.state_2.explained_variance_features_cv_high_repeat = explained_variance_features_cv_high_repeat;
summaries.state_2.explained_variance_features_cv_high_repeat_other = explained_variance_features_cv_high_repeat_other;
summaries.state_2.percentage_correct_cv = percentage_correct_cv;
summaries.state_2.percentage_correct_cv_other = percentage_correct_cv_other;
summaries.state_2.predicted_features_cv = predicted_features_cv;

figure_folder_name = fullfile(paths.figures_out,'fig5','ML_to_AM'); if ~exist(figure_folder_name,'dir'); mkdir(figure_folder_name); end


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
[~,p,~,st] = ttest(qpair);
fprintf('Euclidean dissociation: t(%d)=%.1f, p=%.2e (n=%d pairs)\n', st.df, st.tstat, p, numel(qpair));

%% Decoding bars
figure(1);clf;
bar_with_std(1:4,[summaries.state_1.percentage_correct_cv(10,:)',summaries.state_2.percentage_correct_cv(10,:)',summaries.state_1.percentage_correct_cv_other(10,:)',summaries.state_2.percentage_correct_cv_other(10,:)']) ;set(gca,'ylim',[0 1]);box off;set(gca,'xlim',[0 5]);h = gca;h.XAxis.Visible = 'off';


%% Decoding curve panel
[f, ax, S] = make_standard_figure(mode,'FigureNumber',201, 'HeightInHalfColumnWidths', figure2_panel_height);
[p,errorarea]=plot_with_std(number_of_stimuli_for_decoding_list,100*summaries.priming.percentage_correct_cv(:,:,end)');p.LineStyle='-';p.Color = data.state_colors{3};errorarea.FaceColor=data.state_colors{3};
[p,errorarea]=plot_with_std(number_of_stimuli_for_decoding_list,100*summaries.state_1.percentage_correct_cv(:,:,end)');p.LineStyle='-';p.Color = data.state_colors{1};errorarea.FaceColor=data.state_colors{1};
[p,errorarea]=plot_with_std(number_of_stimuli_for_decoding_list,100*summaries.state_1.percentage_correct_cv_other(:,:,end)');p.LineStyle='--';p.Color = data.state_colors{1};errorarea.FaceColor=data.state_colors{1};
[p,errorarea]=plot_with_std(number_of_stimuli_for_decoding_list,100*summaries.state_2.percentage_correct_cv(:,:,end)');p.LineStyle='-';p.Color = data.state_colors{2};errorarea.FaceColor=data.state_colors{2};
[p,errorarea]=plot_with_std(number_of_stimuli_for_decoding_list,100*summaries.state_2.percentage_correct_cv_other(:,:,end)');p.LineStyle='--';p.Color = data.state_colors{2};errorarea.FaceColor=data.state_colors{2};
% xlabel('Number of distractors')
% ylabel('Decoding accuracy')
ylim([0 100])
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[figure_folder_name filesep 'euclidean_decoding'])


%% Statistical test: 
number_of_identities = 10;
[~,p,~,st] = ttest(summaries.state_1.percentage_correct_cv(number_of_identities,:),summaries.state_1.percentage_correct_cv_other(number_of_identities,:));
fprintf('Euclidean decoding test state 1: t(%d)=%.1f, p=%.2e (n=%d pairs)\n', st.df, st.tstat, p, numel(qpair));
[~,p,~,st] = ttest(summaries.state_2.percentage_correct_cv(number_of_identities,:),summaries.state_2.percentage_correct_cv_other(number_of_identities,:));
fprintf('Euclidean decoding test: t(%d)=%.1f, p=%.2e (n=%d pairs)\n', st.df, st.tstat, p, numel(qpair));


%% Reconstructions
[f, ax, S] = make_standard_figure(mode,'FigureNumber',300,  'WidthInHalfColumns', reconstructions_width,'GridSize', [5 4]);
ax = plot_reconstruction_examples_grid( f, S,...
    config, xml_folder, xml_filename, stimulus_list, priming_stimuli, folder_name, features, summaries.state_1.predicted_features_cv, summaries.state_2.predicted_features_cv, ...
    unique_stimuli, unique_stimulus_index_other_list, unique_stimuli_is_high_repeat, red_cyan_pair_indices);
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[figure_folder_name filesep 'reconstructions'])


%% AM->ML

%Priming
load(release_axes_summary(paths,'priming',''))
define_summary_config_ML_AM_fig_2
regions_to_include = {'ML'};
% load("Z:\session_summaries\flash_suppression_axes\trained_priming_tested_priming\_avgdim_0\summary_trained_priming_tested_priming__avgdim_0.mat")
% define_summary_config_PFC_fig_5;
% summary_config.cell_proportion = 0.5; %To match half neurons
across_sessions_analysis_axes_aux
summaries.priming.explained_variance_features_cv_high_repeat = explained_variance_features_cv_high_repeat;
summaries.priming.explained_variance_features_cv_high_repeat_other = explained_variance_features_cv_high_repeat_other;
summaries.priming.percentage_correct_cv = percentage_correct_cv;
summaries.priming.percentage_correct_cv_other = percentage_correct_cv_other;
summaries.priming.predicted_features_cv = predicted_features_cv;
% summary_config = rmfield(summary_config,'cell_proportion');

%Use LLR
%State 1
load(release_axes_summary(paths,'dominant_binocular','states_Fixed rate HMM AM_1_1'))
define_summary_config_ML_AM_fig_2
regions_to_include = {'ML'};
% load('Z:\session_summaries\flash_suppression_axes\trained_priming_tested_dominant_binocular\states_Fixed rate LLR PFC 10 ms_1_1_avgdim_0\summary_trained_priming_tested_dominant_binocular_states_Fixed rate LLR PFC 10 ms_1_1_avgdim_0.mat')
% define_summary_config_PFC_fig_5;

across_sessions_analysis_axes_aux
summaries.state_1.explained_variance_features_cv_high_repeat = explained_variance_features_cv_high_repeat;
summaries.state_1.explained_variance_features_cv_high_repeat_other = explained_variance_features_cv_high_repeat_other;
summaries.state_1.percentage_correct_cv = percentage_correct_cv;
summaries.state_1.percentage_correct_cv_other = percentage_correct_cv_other;
summaries.state_1.predicted_features_cv = predicted_features_cv;

%State 2
load(release_axes_summary(paths,'dominant_binocular','states_Fixed rate HMM AM_2_1'))
define_summary_config_ML_AM_fig_2
regions_to_include = {'ML'};
% load('Z:\session_summaries\flash_suppression_axes\trained_priming_tested_dominant_binocular\states_Fixed rate LLR PFC 10 ms_2_1_avgdim_0\summary_trained_priming_tested_dominant_binocular_states_Fixed rate LLR PFC 10 ms_2_1_avgdim_0.mat')
% define_summary_config_PFC_fig_5;
across_sessions_analysis_axes_aux
summaries.state_2.explained_variance_features_cv_high_repeat = explained_variance_features_cv_high_repeat;
summaries.state_2.explained_variance_features_cv_high_repeat_other = explained_variance_features_cv_high_repeat_other;
summaries.state_2.percentage_correct_cv = percentage_correct_cv;
summaries.state_2.percentage_correct_cv_other = percentage_correct_cv_other;
summaries.state_2.predicted_features_cv = predicted_features_cv;

figure_folder_name = fullfile(paths.figures_out,'fig5','AM_to_ML'); if ~exist(figure_folder_name,'dir'); mkdir(figure_folder_name); end


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
[~,p,~,st] = ttest(qpair);
fprintf('Euclidean dissociation: t(%d)=%.1f, p=%.2e (n=%d pairs)\n', st.df, st.tstat, p, numel(qpair));

%% Decoding bars
figure(1);clf;
bar_with_std(1:4,[summaries.state_1.percentage_correct_cv(10,:)',summaries.state_2.percentage_correct_cv(10,:)',summaries.state_1.percentage_correct_cv_other(10,:)',summaries.state_2.percentage_correct_cv_other(10,:)']) ;set(gca,'ylim',[0 1]);box off;set(gca,'xlim',[0 5]);h = gca;h.XAxis.Visible = 'off';


%% Decoding curve panel
[f, ax, S] = make_standard_figure(mode,'FigureNumber',201, 'HeightInHalfColumnWidths', figure2_panel_height);
[p,errorarea]=plot_with_std(number_of_stimuli_for_decoding_list,100*summaries.priming.percentage_correct_cv(:,:,end)');p.LineStyle='-';p.Color = data.state_colors{3};errorarea.FaceColor=data.state_colors{3};
[p,errorarea]=plot_with_std(number_of_stimuli_for_decoding_list,100*summaries.state_1.percentage_correct_cv(:,:,end)');p.LineStyle='-';p.Color = data.state_colors{1};errorarea.FaceColor=data.state_colors{1};
[p,errorarea]=plot_with_std(number_of_stimuli_for_decoding_list,100*summaries.state_1.percentage_correct_cv_other(:,:,end)');p.LineStyle='--';p.Color = data.state_colors{1};errorarea.FaceColor=data.state_colors{1};
[p,errorarea]=plot_with_std(number_of_stimuli_for_decoding_list,100*summaries.state_2.percentage_correct_cv(:,:,end)');p.LineStyle='-';p.Color = data.state_colors{2};errorarea.FaceColor=data.state_colors{2};
[p,errorarea]=plot_with_std(number_of_stimuli_for_decoding_list,100*summaries.state_2.percentage_correct_cv_other(:,:,end)');p.LineStyle='--';p.Color = data.state_colors{2};errorarea.FaceColor=data.state_colors{2};
% xlabel('Number of distractors')
% ylabel('Decoding accuracy')
ylim([0 100])
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[figure_folder_name filesep 'euclidean_decoding'])


%% Statistical test: 
number_of_identities = 10;
[~,p,~,st] = ttest(summaries.state_1.percentage_correct_cv(number_of_identities,:),summaries.state_1.percentage_correct_cv_other(number_of_identities,:));
fprintf('Euclidean decoding test state 1: t(%d)=%.1f, p=%.2e (n=%d pairs)\n', st.df, st.tstat, p, numel(qpair));
[~,p,~,st] = ttest(summaries.state_2.percentage_correct_cv(number_of_identities,:),summaries.state_2.percentage_correct_cv_other(number_of_identities,:));
fprintf('Euclidean decoding test: t(%d)=%.1f, p=%.2e (n=%d pairs)\n', st.df, st.tstat, p, numel(qpair));


%% Reconstructions
[f, ax, S] = make_standard_figure(mode,'FigureNumber',300,  'WidthInHalfColumns', reconstructions_width,'GridSize', [5 4]);
ax = plot_reconstruction_examples_grid( f, S,...
    config, xml_folder, xml_filename, stimulus_list, priming_stimuli, folder_name, features, summaries.state_1.predicted_features_cv, summaries.state_2.predicted_features_cv, ...
    unique_stimuli, unique_stimulus_index_other_list, unique_stimuli_is_high_repeat, red_cyan_pair_indices);
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[figure_folder_name filesep 'reconstructions'])