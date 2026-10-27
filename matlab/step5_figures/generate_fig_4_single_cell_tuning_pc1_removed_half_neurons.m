rivalry_config = switches_config_release;
paths = set_paths;

% These two loads supply only the POOLED state-1/state-2 responses; the per-cell axis
% fit is recomputed below on the PC1-removed features, so skip the aux's expensive
% all-cell fit + EV + decoding (b_only_pool_responses) -- result-identical here.
b_only_pool_responses = true;

%LLR:
load(release_axes_summary(paths,'dominant_binocular','states_Fixed rate LLR IT 10 ms half neurons_1_1'))
define_summary_config_ML_AM_fig_3_all_cells
across_sessions_analysis_axes_aux
responses_state_1 = responses_to_use_testing;

load(release_axes_summary(paths,'dominant_binocular','states_Fixed rate LLR IT 10 ms half neurons_2_1'))
define_summary_config_ML_AM_fig_3_all_cells
across_sessions_analysis_axes_aux
responses_state_2 = responses_to_use_testing;

responses_priming_saved = responses_priming; 


%% Remove PC1 (largely red/cyan colour) from the features, recompute the tuning axis
[coeff_col,~,~,~,~,mu_col] = pca(features);          % PC1 of raw features = colour (red vs cyan)
scores_col = (features - mu_col) * coeff_col;
scores_col(:,1) = 0;                                 % drop the colour PC
features = scores_col * coeff_col' + mu_col;         % features with colour removed (same dims)
config.skip_feature_predictions = true;  % only weights_predicting_responses & predicted_responses_cv are used below
[weights_predicting_features, weights_predicting_responses, predicted_features, ...
 predicted_features_cv, predicted_features_st, predicted_features_st_loto, ...
 predicted_responses, predicted_responses_cv] = flash_suppression_axes_predict_responses( ...
    config, features, responses_to_use_training, responses_to_use_testing, ...
    responses_st, responses_ot_stimulus, unique_stimulus_index_other_list);
%%

b_use_stimulus_rank = false;

[responses_priming_sorted,sort_matrix_priming] = sort(responses_priming_saved);
[responses_predicted_sorted,sort_matrix_predicted] = sort(predicted_responses_cv);
predicted_responses_non_cv = [ones(size(features,1),1), features] * weights_predicting_responses;

explained_variance_responses_priming_cv = nan(size(responses_priming_saved,2),1);
for cell_index = 1:size(responses_priming_saved,2)
    explained_variance_responses_priming_cv(cell_index)=Rsquared(responses_priming_saved(:,cell_index),predicted_responses_cv(:,cell_index));
end

sort_matrix_to_use = sort_matrix_predicted;
[m,n]=size(predicted_responses_cv);
sort_indices = (sub2ind([m n],sort_matrix_to_use,repmat(1:n,m,1)));
responses_priming_sorted_by_scheme = responses_priming_saved(sort_indices);
predicted_responses_cv_sorted_by_scheme = predicted_responses_cv(sort_indices);
if b_use_stimulus_rank
    x_for_regression = (1:size(responses_priming_sorted_by_scheme,1))';
else
    x_for_regression = predicted_responses_cv_sorted_by_scheme;
end

b = lscov_columns_nonan(x_for_regression,responses_priming_sorted_by_scheme);
slopes = b(2,:);
[~,neuron_sort_indices] = sort(slopes,'desc');

responses_other_state_2 = responses_state_2(unique_stimulus_index_other_list,:);


responses_priming_sorted_by_scheme_and_neurons = responses_priming_sorted_by_scheme(:,neuron_sort_indices);

responses_state_1_sorted_temp = responses_state_1(sort_indices);
responses_state_1_sorted = responses_state_1_sorted_temp(:,neuron_sort_indices);
responses_other_state_2_sorted_temp = responses_other_state_2(sort_indices);
responses_other_state_2_sorted = responses_other_state_2_sorted_temp(:,neuron_sort_indices);

%Cross:
responses_other_state_1 = responses_state_1(unique_stimulus_index_other_list,:);

responses_other_state_1_sorted_temp = responses_other_state_1(sort_indices);
responses_other_state_1_sorted = responses_other_state_1_sorted_temp(:,neuron_sort_indices);
responses_state_2_sorted_temp = responses_state_2(sort_indices);
responses_state_2_sorted = responses_state_2_sorted_temp(:,neuron_sort_indices);

%Sorted images x neurons
b_selected_neurons = explained_variance_responses_priming_cv(neuron_sort_indices)>0.05; %Select neurons threshold!

smoothwindow = 1;%1=no smooth

b_state_1_dominant = lscov_columns_nonan(x_for_regression,responses_state_1_sorted);
b_state_2_dominant = lscov_columns_nonan(x_for_regression,responses_state_2_sorted);
b_state_1_suppressed = lscov_columns_nonan(x_for_regression,responses_other_state_1_sorted);
b_state_2_suppressed = lscov_columns_nonan(x_for_regression,responses_other_state_2_sorted);

b_state_1_dominant_unsorted = lscov_columns_nonan(x_for_regression,responses_state_1_sorted_temp);
b_state_2_suppressed_unsorted = lscov_columns_nonan(x_for_regression,responses_other_state_2_sorted_temp);




% Single cell example
cell_index = 547;% for neuron-half; used to be 1100 for full population

preferred_axis = weights_predicting_responses(2:end,cell_index); %Ignore the offset
features_orthogonalized = nan(size(features));
for stimulus_index=1:size(features,1)
    features_orthogonalized(stimulus_index,:) = features(stimulus_index,:)-(features(stimulus_index,:)*preferred_axis)*(preferred_axis/dot(preferred_axis,preferred_axis))';
end
[coeff] = pca(zscore(features_orthogonalized(2:2:end,:),[],1)); %Use one color, so that it does not extract only extract color as PC.
score = zscore(features_orthogonalized,[],1)*coeff;
orthogonal_axis = score(:,1);


%% Decoding with and without mean subtracted
%Split so that all responses from one stimulus pair stay in one half.
decoding_scheme.b_hyperparameter_optimization = false;decoding_scheme.stratify = true;

pair_id = min((1:size(responses_state_1,1))', unique_stimulus_index_other_list');
pairs = unique(pair_id);
num_iterations = 100;
number_of_units_list = [1:9 10:10:90 100:100:500 1000:1000:size(responses_state_1,2)];
decoding_accuracies = nan(num_iterations,length(number_of_units_list));
decoding_accuracies_mean_subtracted = nan(num_iterations,length(number_of_units_list));
for number_of_neuron_index = 1:length(number_of_units_list)
    number_of_units_to_use = number_of_units_list(number_of_neuron_index);
    for iteration_index = 1:num_iterations
        selected_cells = randperm(size(responses_state_1,2),number_of_units_to_use);

        pairs_shuffled = pairs(randperm(length(pairs)));
        train_pairs = pairs_shuffled(1:round(length(pairs_shuffled)/2));
        stimulus_pairs_training = find( ismember(pair_id, train_pairs));
        stimulus_pairs_testing = find(~ismember(pair_id, train_pairs));
        %With subtracting mean
        state_1_mean = nanmean(responses_state_1(stimulus_pairs_training,:),1);
        state_2_mean = nanmean(responses_state_2(stimulus_pairs_training,:),1);

        responses_concatenated_first_order_mean_subtracted_training = [responses_state_1(stimulus_pairs_training,:)-state_1_mean, responses_other_state_2(stimulus_pairs_training,:)-state_2_mean];
        responses_concatenated_second_order_mean_subtracted_training = [responses_other_state_2(stimulus_pairs_training,:)-state_2_mean, responses_state_1(stimulus_pairs_training,:)-state_1_mean];

        responses_concatenated_first_order_mean_subtracted_testing = [responses_state_1(stimulus_pairs_testing,:)-state_1_mean, responses_other_state_2(stimulus_pairs_testing,:)-state_2_mean];
        responses_concatenated_second_order_mean_subtracted_testing = [responses_other_state_2(stimulus_pairs_testing,:)-state_2_mean, responses_state_1(stimulus_pairs_testing,:)-state_1_mean];

        feature_matrix_mean_subtracted_training = [responses_concatenated_first_order_mean_subtracted_training;responses_concatenated_second_order_mean_subtracted_training];
        feature_matrix_mean_subtracted_testing = [responses_concatenated_first_order_mean_subtracted_testing;responses_concatenated_second_order_mean_subtracted_testing];
        label_vector_training = [ones(size(responses_concatenated_first_order_mean_subtracted_training,1),1);2*ones(size(responses_concatenated_second_order_mean_subtracted_training,1),1)];
        label_vector_testing= [ones(size(responses_concatenated_first_order_mean_subtracted_testing,1),1);2*ones(size(responses_concatenated_second_order_mean_subtracted_testing,1),1)];
        nonan_rows_mean_subtracted_training = ~any(isnan(feature_matrix_mean_subtracted_training),2);
        nonan_rows_mean_subtracted_testing = ~any(isnan(feature_matrix_mean_subtracted_testing),2);

        %Compute as function of neurons;
        decoding_results_mean_subtracted = switches_decoder_aux(feature_matrix_mean_subtracted_training(nonan_rows_mean_subtracted_training,selected_cells),label_vector_training(nonan_rows_mean_subtracted_training),feature_matrix_mean_subtracted_testing(nonan_rows_mean_subtracted_testing,selected_cells),label_vector_testing(nonan_rows_mean_subtracted_testing),decoding_scheme);
        decoding_accuracies_mean_subtracted(iteration_index,number_of_neuron_index) = decoding_results_mean_subtracted.prediction_accuracy_testing;

        %Without subtracting mean

        responses_concatenated_first_order_training = [responses_state_1(stimulus_pairs_training,:), responses_other_state_2(stimulus_pairs_training,:)];
        responses_concatenated_second_order_training = [responses_other_state_2(stimulus_pairs_training,:), responses_state_1(stimulus_pairs_training,:)];

        responses_concatenated_first_order_testing = [responses_state_1(stimulus_pairs_testing,:), responses_other_state_2(stimulus_pairs_testing,:)];
        responses_concatenated_second_order_testing = [responses_other_state_2(stimulus_pairs_testing,:), responses_state_1(stimulus_pairs_testing,:)];

        feature_matrix_training = [responses_concatenated_first_order_training;responses_concatenated_second_order_training];
        feature_matrix_testing = [responses_concatenated_first_order_testing;responses_concatenated_second_order_testing];
        label_vector_training = [ones(size(responses_concatenated_first_order_training,1),1);2*ones(size(responses_concatenated_second_order_training,1),1)];
        label_vector_testing= [ones(size(responses_concatenated_first_order_testing,1),1);2*ones(size(responses_concatenated_second_order_testing,1),1)];
        nonan_rows_training = ~any(isnan(feature_matrix_training),2);
        nonan_rows_testing = ~any(isnan(feature_matrix_testing),2);

        decoding_results = switches_decoder_aux(feature_matrix_training(nonan_rows_training,selected_cells),label_vector_training(nonan_rows_training),feature_matrix_testing(nonan_rows_testing,selected_cells),label_vector_testing(nonan_rows_testing),decoding_scheme);
        decoding_accuracies(iteration_index,number_of_neuron_index) = decoding_results.prediction_accuracy_testing;


    end
end




close all;

%% Make figures

mode='nature';

if strcmp(mode,'poster')
    panel_height = 0.8;
    panel_width = 1;
elseif strcmp(mode,'nature')
    panel_height = 0.68;
    panel_width = 0.68;
    marker_face_alpha=0.15;marker_edge_alpha=0.2; %Thinnest
end
color_range = [-3 6];

outputfolder = fullfile(paths.figures_out,'fig_4_tuning');
if ~exist(outputfolder,'dir'); mkdir(outputfolder); end
%% Population tuning panel
[f, ax, S] = make_standard_figure(mode,'FigureNumber',401, 'HeightInHalfColumnWidths', panel_height, 'WidthInHalfColumns', panel_width);
imagesc(smoothdata(responses_state_1_sorted(:,b_selected_neurons)',2,"movmean",smoothwindow),color_range);colormap redblue;
set(gca,'Ydir','reverse');set(gca,'Xlim',[1 size(responses_priming_sorted_by_scheme_and_neurons,1)]);set(gca,'YLim',[1 sum(b_selected_neurons)]);
xticks([]);yticks([]);set(gca,'yticklabels',[]);set(gca,'xticklabels',[]);axis square;
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'population_state_1_conscious']);figure(f);

[f, ax, S] = make_standard_figure(mode,'FigureNumber',402, 'HeightInHalfColumnWidths', panel_height, 'WidthInHalfColumns', panel_width);
imagesc(smoothdata(responses_state_2_sorted(:,b_selected_neurons)',2,"movmean",smoothwindow),color_range);colormap redblue
set(gca,'Ydir','reverse');set(gca,'Xlim',[1 size(responses_priming_sorted_by_scheme_and_neurons,1)]);set(gca,'YLim',[1 sum(b_selected_neurons)]);
xticks([]);yticks([]);set(gca,'yticklabels',[]);set(gca,'xticklabels',[]);axis square;
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'population_state_2_conscious']);figure(f);

[f, ax, S] = make_standard_figure(mode,'FigureNumber',403, 'HeightInHalfColumnWidths', panel_height, 'WidthInHalfColumns', panel_width);
imagesc(smoothdata(responses_other_state_1_sorted(:,b_selected_neurons)',2,"movmean",smoothwindow),color_range);colormap redblue
set(gca,'Ydir','reverse');set(gca,'Xlim',[1 size(responses_priming_sorted_by_scheme_and_neurons,1)]);set(gca,'YLim',[1 sum(b_selected_neurons)]);
xticks([]);yticks([]);set(gca,'yticklabels',[]);set(gca,'xticklabels',[]);axis square;
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'population_state_1_suppressed']);figure(f);

[f, ax, S] = make_standard_figure(mode,'FigureNumber',404, 'HeightInHalfColumnWidths', panel_height, 'WidthInHalfColumns', panel_width);
imagesc(smoothdata(responses_other_state_2_sorted(:,b_selected_neurons)',2,"movmean",smoothwindow),color_range);colormap redblue
set(gca,'Ydir','reverse');set(gca,'Xlim',[1 size(responses_priming_sorted_by_scheme_and_neurons,1)]);set(gca,'YLim',[1 sum(b_selected_neurons)]);
xticks([]);yticks([]);set(gca,'yticklabels',[]);set(gca,'xticklabels',[]);axis square;
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'population_state_2_suppressed']);figure(f);



%% Example cell panel
if strcmp(mode,'poster')
    scatter_size = 20;
    marker_face_alpha=0.15;marker_edge_alpha=0.2; %Thinnest
elseif strcmp(mode,'nature')
    scatter_size = 5;
    marker_face_alpha=0.15;marker_edge_alpha=0.2; %Thinnest
end

% Cell 1
bins_x_range=[0 5];bins_y_range=[-2 4];bin_size =1;margin_range = [0 12];x_lim_total_range = [];y_lim_total_range = [];%cell_index = 1100;

[f, ax, S] = make_standard_figure(mode,'FigureNumber',501, 'HeightInHalfColumnWidths', panel_height, 'WidthInHalfColumns', panel_width);
scatter(predicted_responses_cv(:,cell_index),orthogonal_axis,scatter_size,responses_state_1(:,cell_index),'filled');caxis([color_range]); colormap redblue;if x_lim_total_range;set(gca,'xlim',x_lim_total_range);end;if y_lim_total_range;set(gca,'xlim',y_lim_total_range);end
xticks(xlim);yticks(ylim);set(gca,'xticklabels','');set(gca,'yticklabels','');figure(f);axis square;
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'example_cell_1_state_1_conscious']);figure(f);
scatter_xlim = xlim;scatter_ylim = ylim;



[f, ax, S] = make_standard_figure(mode,'FigureNumber',502, 'HeightInHalfColumnWidths', panel_height, 'WidthInHalfColumns', panel_width);
scatter(predicted_responses_cv(:,cell_index),orthogonal_axis,scatter_size,responses_state_2(:,cell_index),'filled');caxis([color_range]); colormap redblue;if x_lim_total_range;set(gca,'xlim',x_lim_total_range);end;if y_lim_total_range;set(gca,'xlim',y_lim_total_range);end
xticks(xlim);yticks(ylim);set(gca,'xticklabels','');set(gca,'yticklabels','');figure(f);axis square;
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'example_cell_1_state_2_conscious']);figure(f);

[f, ax, S] = make_standard_figure(mode,'FigureNumber',503, 'HeightInHalfColumnWidths', panel_height, 'WidthInHalfColumns', panel_width);
scatter(predicted_responses_cv(:,cell_index),orthogonal_axis,scatter_size,responses_other_state_1(:,cell_index),'filled');caxis([color_range]); colormap redblue;if x_lim_total_range;set(gca,'xlim',x_lim_total_range);end;if y_lim_total_range;set(gca,'xlim',y_lim_total_range);end
xticks(xlim);yticks(ylim);set(gca,'xticklabels','');set(gca,'yticklabels','');figure(f);axis square;
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'example_cell_1_state_1_suppressed']);figure(f);

[f, ax, S] = make_standard_figure(mode,'FigureNumber',504, 'HeightInHalfColumnWidths', panel_height, 'WidthInHalfColumns', panel_width);
scatter(predicted_responses_cv(:,cell_index),orthogonal_axis,scatter_size,responses_other_state_2(:,cell_index),'filled');caxis([color_range]); colormap redblue;if x_lim_total_range;set(gca,'xlim',x_lim_total_range);end;if y_lim_total_range;set(gca,'xlim',y_lim_total_range);end
xticks(xlim);yticks(ylim);set(gca,'xticklabels','');set(gca,'yticklabels','');figure(f);axis square;
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'example_cell_1_state_2_suppressed']);

[f, ax, S] = make_standard_figure(mode,'FigureNumber',505, 'HeightInHalfColumnWidths', panel_height/1.6, 'WidthInHalfColumns', panel_width/1.6);
responses = responses_state_1(:,cell_index);
preferred_axis_responses = predicted_responses_cv(:,cell_index);
plot_axis_tuning_example_cell_margins_x
hh.Color=rivalry_config.state_colors{1};hh.LineWidth = S.reference_line_width;
p.Color=rivalry_config.state_colors{1};p.LineWidth = S.line_width;
responses = responses_other_state_2(:,cell_index);
plot_axis_tuning_example_cell_margins_x;
hh.Color=rivalry_config.state_colors{2};hh.LineWidth = S.reference_line_width;
p.Color=rivalry_config.state_colors{2};p.LineWidth = S.line_width;
xticks(xlim);set(gca,'xticklabels','');set(gca,'ylim',[0 9]);yticks([0 9])
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'example_cell_1_margins']);figure(f);

[f, ax, S] = make_standard_figure(mode,'FigureNumber',506, 'HeightInHalfColumnWidths', panel_height, 'WidthInHalfColumns', panel_width);
caxis([color_range]);colormap redblue;cb=colorbar;
cb.Ticks = [color_range(1) 0 color_range(2)];          % Removes tick labels and marks
cb.TickLength = 0;      % Removes any residual tick extension
cb.Color = 'none';      % Hides the outline border
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'colorbar']);figure(f);


%% Slopes, offset, decoding
max_slope = max([abs(b_state_1_dominant(2,b_selected_neurons)),abs(b_state_2_suppressed(2,b_selected_neurons))]);
max_offset = max([abs(b_state_1_dominant(1,b_selected_neurons)),abs(b_state_2_suppressed(1,b_selected_neurons))]);

[fig, ax, S] = make_standard_figure(mode,'FigureNumber',601, 'HeightInHalfColumnWidths', panel_height, 'WidthInHalfColumns', panel_width);

data_cell = { b_state_1_dominant(2,b_selected_neurons), b_state_1_suppressed(2,b_selected_neurons), b_state_2_dominant(2,b_selected_neurons),  b_state_2_suppressed(2,b_selected_neurons)};
labels = {'State 1 conscious', 'State 2 suppressed', 'State 1 conscious', 'State 2 suppressed'};
yline(0, '--k', 'LineWidth', 1); violin_width = 0.35; dot_alpha = 0.18;dot_size = 8;
colors = [
    hex2rgb('#FCAE34');  % state 1 conscious
    hex2rgb('#B86F1E');  % state 1 suppressed
    hex2rgb('#8E5BAA');  % state 2 conscious
    hex2rgb('#543379')   % state 2 suppressed
];
for i = 1:length(data_cell)
    x = data_cell{i};
    x = x(~isnan(x));
    [f, xi] = ksdensity(x);
    f = f ./ max(f) * violin_width;
    patch([i - f, fliplr(i + f)], [xi, fliplr(xi)], colors(i,:),'FaceAlpha', 0.35, 'EdgeColor', 'none');
    med_x = median(x, 'omitnan');
    plot([i - violin_width*0.7, i + violin_width*0.7], [med_x, med_x], 'Color', colors(i,:), 'LineWidth', 2);
    jitter = (rand(size(x)) - 0.5) * 0.16;
    scatter(i + jitter, x, 8, ...
        'MarkerFaceColor', colors(i,:), ...
        'MarkerEdgeColor', 'none', ...
        'MarkerFaceAlpha', dot_alpha);
end
xlim([0.4, numel(data_cell)+0.6]);
set(gca, 'XTick', 1:numel(data_cell), 'XTickLabel', labels);
ylabel('Tuning slope');
finish_standard_figure(fig, ax, S);figure(fig);



slope_lims = [-0.5 2.5]

%Pair histograms,'EdgeColor','none'
[f, ax, S] = make_standard_figure(mode,'FigureNumber',603, 'HeightInHalfColumnWidths', panel_height/4, 'WidthInHalfColumns', panel_width);
histogram(b_state_1_dominant(2,b_selected_neurons),'FaceColor',hex2rgb(rivalry_config.state_colors(1)),'EdgeColor','none','FaceAlpha',0.3);histogram(b_state_1_suppressed(2,b_selected_neurons),'FaceColor',hex2rgb('#FFD28A'),'EdgeColor','none','FaceAlpha',0.3);
histogram(b_state_1_dominant(2,b_selected_neurons),'EdgeColor',hex2rgb(rivalry_config.state_colors(1)),'DisplayStyle','stairs');histogram(b_state_1_suppressed(2,b_selected_neurons),'EdgeColor',hex2rgb('#FFD28A'),'DisplayStyle','stairs');
set(gca,'xlim',slope_lims)
xticks([0 2]);set(gca,'xticklabels','');
yticks([0 100])
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'slope_histogram_state_1']);figure(f);

[f, ax, S] = make_standard_figure(mode,'FigureNumber',604, 'HeightInHalfColumnWidths', panel_height/4, 'WidthInHalfColumns', panel_width);
histogram(b_state_2_dominant(2,b_selected_neurons),'FaceColor',hex2rgb('#B56CC7'),'EdgeColor','none','FaceAlpha',0.3);histogram(b_state_2_suppressed(2,b_selected_neurons),'FaceColor',hex2rgb(rivalry_config.state_colors(2)),'EdgeColor','none','FaceAlpha',0.3);
histogram(b_state_2_dominant(2,b_selected_neurons),'EdgeColor',hex2rgb('#B56CC7'),'DisplayStyle','stairs');histogram(b_state_2_suppressed(2,b_selected_neurons),'EdgeColor',hex2rgb(rivalry_config.state_colors(2)),'DisplayStyle','stairs');
set(gca,'xlim',slope_lims)
xticks([0 2]);set(gca,'xticklabels','');
yticks([0 100])
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'slope_histogram_state_2']);figure(f);

[f, ax, S] = make_standard_figure(mode,'FigureNumber',605, 'HeightInHalfColumnWidths', panel_height/4, 'WidthInHalfColumns', panel_width);
histogram(b_state_1_dominant(2,b_selected_neurons),'FaceColor',hex2rgb(rivalry_config.state_colors(1)),'EdgeColor','none','FaceAlpha',0.3);histogram(b_state_2_suppressed(2,b_selected_neurons),'FaceColor',hex2rgb(rivalry_config.state_colors(2)),'EdgeColor','none','FaceAlpha',0.3);
histogram(b_state_1_dominant(2,b_selected_neurons),'EdgeColor',hex2rgb(rivalry_config.state_colors(1)),'DisplayStyle','stairs');histogram(b_state_2_suppressed(2,b_selected_neurons),'EdgeColor',hex2rgb(rivalry_config.state_colors(2)),'DisplayStyle','stairs');
set(gca,'xlim',slope_lims)
xticks([0 2]);%set(gca,'xticklabels','');
yticks([0 100])
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'slope_histogram_state_1_vs_state_2']);figure(f);



[~,p_slope_state_1_conscious_vs_suppressed,~,st_state_1] = ttest(b_state_1_dominant(2,b_selected_neurons),b_state_1_suppressed(2,b_selected_neurons))
[~,p_slope_state_2_conscious_vs_suppressed,~,st_state_2] = ttest(b_state_2_dominant(2,b_selected_neurons),b_state_2_suppressed(2,b_selected_neurons))

if strcmp(mode,'poster')
    scatter_size = 20;
    marker_face_alpha=0.15;marker_edge_alpha=0.2; %Thinnest
elseif strcmp(mode,'nature')
    scatter_size = 0.5;
    marker_face_alpha=1;marker_edge_alpha=1; %Thinnest
end


[f, ax, S] = make_standard_figure(mode,'FigureNumber',606, 'HeightInHalfColumnWidths', panel_height, 'WidthInHalfColumns', panel_width);
scatter(b_state_1_dominant(2,b_selected_neurons),b_state_2_suppressed(2,b_selected_neurons),scatter_size/2,'filled','MarkerFaceColor','k','MarkerFaceAlpha',marker_face_alpha,'MarkerEdgeAlpha',marker_edge_alpha);hold on;
plot([slope_lims], [slope_lims],'k--','linewidth',S.reference_line_width);plot([slope_lims], [0 0],'k--','linewidth',S.reference_line_width);plot([0 0], [slope_lims],'k--','linewidth',S.reference_line_width);set(gca,'xlim',[slope_lims]);set(gca,'ylim',[slope_lims]);
xticks([0 2]);%set(gca,'xticklabels','');
yticks([0 2]);%set(gca,'yticklabels','');
axis square;
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'slope_scatter']);figure(f);

mean_slope_ratio = nanmean(b_state_1_dominant(2,b_selected_neurons))./nanmean(b_state_2_suppressed(2,b_selected_neurons))
[~,p_slope_state_1_conscious_vs_state_2_suppressed,~,st_slope_state_1_conscious_vs_state_2_suppressed] = ttest(b_state_1_dominant(2,b_selected_neurons),b_state_2_suppressed(2,b_selected_neurons))
[r_slope_state_1_conscious_vs_state_2_suppressed,p_correlation_slope_state_1_conscious_vs_state_2_suppressed] = corrcoef(b_state_1_dominant(2,b_selected_neurons),b_state_2_suppressed(2,b_selected_neurons),'Rows','complete')

mean_lims = [0 3];
[f, ax, S] = make_standard_figure(mode,'FigureNumber',609, 'HeightInHalfColumnWidths', panel_height, 'WidthInHalfColumns', panel_width);
scatter(mean(responses_state_1_sorted(:,b_selected_neurons),1),mean(responses_state_2_sorted(:,b_selected_neurons),1),scatter_size/2,'filled','MarkerFaceColor','k','MarkerFaceAlpha',marker_face_alpha,'MarkerEdgeAlpha',marker_edge_alpha);
plot([mean_lims], [mean_lims],'k--','linewidth',S.reference_line_width);plot([mean_lims], [0 0],'k--','linewidth',S.reference_line_width);plot([0 0], [mean_lims],'k--','linewidth',S.reference_line_width);set(gca,'xlim',[mean_lims]);set(gca,'ylim',[mean_lims]);
xticks(mean_lims);yticks(mean_lims);set(gca,'xticklabels','');
axis square;
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'mean_scatter']);figure(f);

[~,p_mean,~,st_mean] = ttest(mean(responses_state_1_sorted(:,b_selected_neurons & ~isnan(b_state_1_dominant(2,:))'),1),mean(responses_state_2_sorted(:,b_selected_neurons & ~isnan(b_state_1_dominant(2,:))'),1))

%Decoding
[f, ax, S] = make_standard_figure(mode,'FigureNumber',610, 'HeightInHalfColumnWidths', panel_height, 'WidthInHalfColumns', panel_width);
[p,errorarea] = plot_with_std(number_of_units_list,100*decoding_accuracies);
p.Color='k';errorarea.FaceColor='k';
plot(xlim,[50 50],'k--','LineWidth',S.reference_line_width)
ylim([0 100]);axis square;xticks(xlim);
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'state_1_vs_state_2_decoding']);figure(f);
