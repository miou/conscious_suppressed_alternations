paths = set_paths;
data = switches_config_release;
release_fig_dir = fullfile(paths.figures_out,'fig_2_ev');   % release output (was a hardcoded internal path)
if ~exist(release_fig_dir,'dir'); mkdir(release_fig_dir); end
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
define_summary_config_ML_AM_fig_2

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
load(release_axes_summary(paths,'dominant_binocular','states_Fixed rate LLR IT 10 ms_1_1'))
define_summary_config_ML_AM_fig_2

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
load(release_axes_summary(paths,'dominant_binocular','states_Fixed rate LLR IT 10 ms_2_1'))
define_summary_config_ML_AM_fig_2
across_sessions_analysis_axes_aux
summaries.state_2.explained_variance_features_cv_high_repeat = explained_variance_features_cv_high_repeat;
summaries.state_2.explained_variance_features_cv_high_repeat_other = explained_variance_features_cv_high_repeat_other;
summaries.state_2.percentage_correct_cv = percentage_correct_cv;
summaries.state_2.percentage_correct_cv_other = percentage_correct_cv_other;
summaries.state_2.correct_cv_per_stim = correct_cv_per_stim;
summaries.state_2.correct_cvo_per_stim = correct_cvo_per_stim;
summaries.state_2.count_per_stim = count_per_stim;
summaries.state_2.predicted_features_cv = predicted_features_cv;




% define_summary_config_ML_AM_fig_2 (called above) resets figure_folder_name to an
% internal hardcoded path; restore the release output folder for the saved panels.
figure_folder_name = release_fig_dir;

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

%% Decoding bars
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


%% Single-trial decoding (Fig 2l) -- full-population IT. trial_decoding is computed by
% run_and_save_trial_decoding_full -> combine_trial_decoding_full (summary_IT_full_s{1,2}).
region = 'IT';
state_1 = load(fullfile(paths.results,'trial_decoding_full','summary_IT_full_s1.mat'));
state_2 = load(fullfile(paths.results,'trial_decoding_full','summary_IT_full_s2.mat'));
figure_folder_name = release_fig_dir;
example_session_index = 7; %250518_Mowgli (paper example, originally 146)

decoding_unambiguous_dominant_all_states = [];
decoding_unambiguous_suppressed_all_states = [];
decoding_binocular_dominant_all_states = [];
decoding_binocular_suppressed_all_states = [];
decoding_binocular_dominant_state_1 = [];
decoding_binocular_suppressed_state_1 = [];
decoding_binocular_dominant_state_2 = [];
decoding_binocular_suppressed_state_2 = [];
for session_index_across_sessions = 1:length(state_1.flash_suppression_results_all_sessions)
    if ~isempty(state_1.flash_suppression_results_all_sessions{session_index_across_sessions})
        fs = state_1.flash_suppression_results_all_sessions{session_index_across_sessions};
        if isfield(state_1.flash_suppression_results_all_sessions{session_index_across_sessions}.trial_decoding,region)
            decoding_unambiguous_dominant_all_states = [decoding_unambiguous_dominant_all_states state_1.flash_suppression_results_all_sessions{session_index_across_sessions}.trial_decoding.(region).decoding_accuracy_testing_dominant_full_trial.unambiguous];
            decoding_unambiguous_suppressed_all_states = [decoding_unambiguous_suppressed_all_states state_1.flash_suppression_results_all_sessions{session_index_across_sessions}.trial_decoding.(region).decoding_accuracy_testing_suppressed_full_trial.unambiguous];
            decoding_binocular_dominant_all_states = [decoding_binocular_dominant_all_states state_1.flash_suppression_results_all_sessions{session_index_across_sessions}.trial_decoding.(region).decoding_accuracy_testing_dominant_full_trial.binocular];
            decoding_binocular_suppressed_all_states = [decoding_binocular_suppressed_all_states state_1.flash_suppression_results_all_sessions{session_index_across_sessions}.trial_decoding.(region).decoding_accuracy_testing_suppressed_full_trial.binocular];
            decoding_binocular_dominant_state_1 = [decoding_binocular_dominant_state_1 state_1.flash_suppression_results_all_sessions{session_index_across_sessions}.trial_decoding.(region).decoding_accuracy_testing_dominant_state_full_trial.binocular];
            decoding_binocular_suppressed_state_1 = [decoding_binocular_suppressed_state_1 state_1.flash_suppression_results_all_sessions{session_index_across_sessions}.trial_decoding.(region).decoding_accuracy_testing_suppressed_state_full_trial.binocular];
            decoding_binocular_dominant_state_2 = [decoding_binocular_dominant_state_2 state_2.flash_suppression_results_all_sessions{session_index_across_sessions}.trial_decoding.(region).decoding_accuracy_testing_dominant_state_full_trial.binocular];
            decoding_binocular_suppressed_state_2 = [decoding_binocular_suppressed_state_2 state_2.flash_suppression_results_all_sessions{session_index_across_sessions}.trial_decoding.(region).decoding_accuracy_testing_suppressed_state_full_trial.binocular];
        end
    end
end

time_points = 1e-3*(state_1.flash_suppression_results_all_sessions{example_session_index}.time_window_starts+state_1.flash_suppression_results_all_sessions{example_session_index}.time_window_length/2);
[f, ax, S] = make_standard_figure(mode,'FigureNumber',801, 'HeightInHalfColumnWidths', figure2_panel_height/2.5,  'WidthInHalfColumns',1/2);
plot(time_points,100*state_1.flash_suppression_results_all_sessions{example_session_index}.trial_decoding.(region).decoding_accuracy_testing_dominant.binocular,'-','Color',[.5 .5 .5]);
plot(time_points,100*state_1.flash_suppression_results_all_sessions{example_session_index}.trial_decoding.(region).decoding_accuracy_testing_suppressed.binocular,'--','Color',[.5 .5 .5]);
set(gca,'ylim',[0 100]);
set(gca,'xlim',1e-3*[-100,2000])
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[figure_folder_name filesep 'single_trial_decoding_example_all_states'])

[f, ax, S] = make_standard_figure(mode,'FigureNumber',802, 'HeightInHalfColumnWidths', figure2_panel_height/2.5,  'WidthInHalfColumns',1/2);
plot(time_points,100*state_1.flash_suppression_results_all_sessions{example_session_index}.trial_decoding.(region).decoding_accuracy_testing_dominant_state.binocular,'-','Color',data.state_colors{1});
plot(time_points,100*state_1.flash_suppression_results_all_sessions{example_session_index}.trial_decoding.(region).decoding_accuracy_testing_suppressed_state.binocular,'--','Color',data.state_colors{1});
set(gca,'ylim',[0 100]);
set(gca,'xlim',1e-3*[-100,2000])
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[figure_folder_name filesep 'single_trial_decoding_example_state_1'])

[f, ax, S] = make_standard_figure(mode,'FigureNumber',803, 'HeightInHalfColumnWidths', figure2_panel_height/2.5,  'WidthInHalfColumns',1/2);
plot(time_points,100*state_2.flash_suppression_results_all_sessions{example_session_index}.trial_decoding.(region).decoding_accuracy_testing_dominant_state.binocular,'-','Color',data.state_colors{2});
plot(time_points,100*state_2.flash_suppression_results_all_sessions{example_session_index}.trial_decoding.(region).decoding_accuracy_testing_suppressed_state.binocular,'--','Color',data.state_colors{2});
set(gca,'ylim',[0 100]);
set(gca,'xlim',1e-3*[-100,2000])
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[figure_folder_name filesep 'single_trial_decoding_example_state_2'])

[f, ax, S] = make_standard_figure(mode,'FigureNumber',805, 'HeightInHalfColumnWidths', figure2_panel_height);
x = 1:3;
plot(x,100*[mean(decoding_binocular_dominant_all_states),mean(decoding_binocular_dominant_state_1),mean(decoding_binocular_dominant_state_2)],'k-','LineWidth',S.line_width)
plot(x,100*[decoding_binocular_dominant_all_states',decoding_binocular_dominant_state_1',decoding_binocular_dominant_state_2'],'-','LineWidth',0.1,'Color',[0 0 0 .5])
plot(x,100*[mean(decoding_binocular_suppressed_all_states),mean(decoding_binocular_suppressed_state_1),mean(decoding_binocular_suppressed_state_2)],'--','Color',[0 0 0],'LineWidth',S.line_width)
plot(x,100*[decoding_binocular_suppressed_all_states',decoding_binocular_suppressed_state_1',decoding_binocular_suppressed_state_2'],'--','Color',[0 0 0 .5],'LineWidth',0.1)
plot([1],100*[mean(decoding_binocular_dominant_all_states) ],'o','MarkerFaceColor',[.5 .5 .5],'MarkerEdgeColor',[.5 .5 .5],'MarkerSize',S.marker_size*0.75,'LineWidth',S.line_width)
plot([1],100*[mean(decoding_binocular_suppressed_all_states)],'o','MarkerEdgeColor',[.5 .5 .5],'MarkerFaceColor',[1 1 1],'MarkerSize',S.marker_size*0.75,'LineWidth',S.line_width)
plot([2],100*[mean(decoding_binocular_dominant_state_1) ],'o','MarkerFaceColor',data.state_colors{1},'MarkerEdgeColor',data.state_colors{1},'MarkerSize',S.marker_size*0.75,'LineWidth',S.line_width)
plot([2],100*[mean(decoding_binocular_suppressed_state_1)],'o','MarkerEdgeColor',data.state_colors{1},'MarkerFaceColor',[1 1 1],'MarkerSize',S.marker_size*0.75,'LineWidth',S.line_width)
plot([3],100*[mean(decoding_binocular_dominant_state_2) ],'o','MarkerFaceColor',data.state_colors{2},'MarkerEdgeColor',data.state_colors{2},'MarkerSize',S.marker_size*0.75,'LineWidth',S.line_width)
plot([3],100*[mean(decoding_binocular_suppressed_state_2)],'o','MarkerEdgeColor',data.state_colors{2},'MarkerFaceColor',[1 1 1],'MarkerSize',S.marker_size*0.75,'LineWidth',S.line_width)
set(gca,'xlim',[0.5 3.5]);set(gca,'YLim',[0 100]);set(gca,'xticklabels',{'Average','State 1','State 2'})
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[figure_folder_name filesep 'single_trial_decoding_summary'])

[~,p_single_trial_decoding_state_1,~,st_state_1] = ttest(decoding_binocular_dominant_state_1,decoding_binocular_suppressed_state_1)
[~,p_single_trial_decoding_state_2,~,st_state_2] = ttest(decoding_binocular_dominant_state_2,decoding_binocular_suppressed_state_2)
