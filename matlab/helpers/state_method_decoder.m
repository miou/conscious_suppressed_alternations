function inference_results = state_method_decoder(inference_scheme,session,paradigm_index);
inference_results = struct;

selection_method = inference_scheme.selection_method;
folder_name = [session.analysis_path filesep 'state_method_decoder'];
mkdir(folder_name)
paradigm_data = session.paradigms_data{paradigm_index};
inference_results.state_timecourse = zeros(size(paradigm_data.timecourse_all_units,1),1);
%Define priming, dominant, and suppressed stimuli and paradigms
time_window = [300 paradigm_data.on_duration];
flash_suppression_get_variables;
trial_time_window = time_window;
flash_suppression_compute_modulation_indices_all;
timecourse_smoothed = smoothdata(paradigm_data.timecourse_all_units(:,:)',2,'movmean',inference_scheme.time_window)';

if inference_scheme.b_standardize_units
    gray_duration = median(on_durations_in_range(trial_is_gray));
    neurons_mean= mean(mean(raster(trial_is_gray,find(50 == peri_stimulus_range):find(gray_duration == peri_stimulus_range),:),2),1);
    neurons_std= std(mean(raster(trial_is_gray,find(50 == peri_stimulus_range):find(gray_duration == peri_stimulus_range),:)),[],2);
    neurons_std(neurons_std==0) = inf;
    raster_to_use = (raster - neurons_mean)./neurons_std;
    timecourse_smoothed = (timecourse_smoothed - shiftdim(neurons_mean,1))./shiftdim(neurons_std,1);
else
    raster_to_use = raster;
end

if strcmp(selection_method,'all')
    b_selected_cells=true(size(raster_to_use,3),1);
elseif strcmp(selection_method,'face_selective')
    b_selected_cells= and(session.face_vs_object(paradigm_data.paradigm_index_for_selectivity).fsi>0, session.face_vs_object(paradigm_data.paradigm_index_for_selectivity).p_value_face_vs_object<0.05);
end


flash_suppression_get_variables
trial_is_actually_red = (trial_is_red_suppressed & trial_is_priming) | (trial_is_cyan_suppressed & trial_is_binocular);
trial_is_actually_cyan = (trial_is_cyan_suppressed & trial_is_priming) | (trial_is_red_suppressed & trial_is_binocular);



decoding_scheme.bin_size = inference_scheme.time_window;
decoding_scheme.bin_distance = 1;
decoding_scheme.b_balance_trials_across_classes = true;
decoding_scheme.b_standardize = false; %seems better without
decoding_scheme.b_hyperparameter_optimization = false;
decoding_scheme.only_single_units= false;
decoding_scheme.number_of_bins = length(trial_time_window(1):trial_time_window(end));
decoding_scheme.time_offset = trial_time_window(1);

decoding_scheme.selection_scheme = selection_method;

decoding_scheme.b_selected_neurons = b_selected_cells;

decoding_scheme.b_selected_features = decoding_scheme.b_selected_neurons;
decoding_scheme.kfold = 8;
decoding_scheme.stratify = true;
decoding_scheme.learners = 'linear'; %Takes hours for 'svm'
decoding_scheme.b_use_trials_for_cvpartition = true;
decoding_scheme.number_of_dims = [];
decoding_scheme.b_use_single_resolution = true;
decoding_scheme.version = 2.2;%Implemented fixing red or cyan for multiple decoders

trial_is_selected = trial_is_priming; %Everything but gray

context_trial_indices = find(trial_is_selected);

if size(timecourse_smoothed,1)<(on_times_in_range(find(trial_is_selected,1,'last')) + trial_time_window(end))
    trial_is_selected(end) = false;
end
start_times = on_times_in_range(trial_is_selected)+decoding_scheme.time_offset;
labels = double(trial_is_actually_red(trial_is_selected)*1 + trial_is_actually_cyan(trial_is_selected)*2);
labels_list = [1 2];
decoding_scheme_probe = decoding_scheme;
b_timecourse_already_processed = true;
decoding_results_continuous_cv = switches_decoder_timecourse(timecourse_smoothed(:,decoding_scheme_probe.b_selected_features),start_times,labels,timecourse_smoothed(:,decoding_scheme_probe.b_selected_features),[],[],decoding_scheme_probe,b_timecourse_already_processed,1:length(labels_list)); %cross-paradigm
decoding_results_continuous = switches_decoder_timecourse(timecourse_smoothed(:,decoding_scheme_probe.b_selected_features),start_times,labels,timecourse_smoothed(:,decoding_scheme_probe.b_selected_features),start_times,labels,decoding_scheme_probe,b_timecourse_already_processed,1:length(labels_list)); %cross-paradigm


selected_features_decoder_probe  = true(1,sum(decoding_scheme.b_selected_neurons));

decoding_results_continuous_to_use.Beta{1} = -decoding_results_continuous.model.Beta(selected_features_decoder_probe);
decoding_results_continuous_to_use.Bias{1} = -decoding_results_continuous.model.Bias;
decoding_results_continuous_to_use.Beta{2} = decoding_results_continuous.model.Beta(selected_features_decoder_probe);
decoding_results_continuous_to_use.Bias{2} = decoding_results_continuous.model.Bias;
for partition_index = 1:length(decoding_results_continuous_cv.model.Trained)
    decoding_results_continuous_to_use.Beta_cv{1,partition_index} = -decoding_results_continuous_cv.model.Trained{partition_index}.Beta(selected_features_decoder_probe);
    decoding_results_continuous_to_use.Bias_cv{1,partition_index} = -decoding_results_continuous_cv.model.Trained{partition_index}.Bias;
    decoding_results_continuous_to_use.Beta_cv{2,partition_index} = decoding_results_continuous_cv.model.Trained{partition_index}.Beta(selected_features_decoder_probe);
    decoding_results_continuous_to_use.Bias_cv{2,partition_index} = decoding_results_continuous_cv.model.Trained{partition_index}.Bias;
end

%% Apply decoder to whole timecourse
decoding_results_continuous_to_use.cv_partition_test_trials = decoding_results_continuous_cv.cv_partition_test_trials;

decision_variable_timecourse = nan(size(timecourse_smoothed,1),length(decoding_results_continuous_to_use.Bias));
for class_index = 1:length(decoding_results_continuous_to_use.Bias)
    decision_variable_timecourse(:,class_index) = decoding_results_continuous_to_use.Bias{class_index} + timecourse_smoothed(:,selected_features_decoder_probe) * decoding_results_continuous_to_use.Beta{class_index};
    % Implement cross-validation
    for partition_index = 1:size(decoding_results_continuous_to_use.Beta_cv,2)
        on_times_partition = on_times_in_range(context_trial_indices(decoding_results_continuous_to_use.cv_partition_test_trials==partition_index))+decoding_scheme.time_offset;
        %Cross-validate with more time points:
        bin_points = round(0.5*decoding_scheme.bin_size + ((0-decoding_scheme.bin_size):decoding_scheme.bin_distance:(decoding_scheme.bin_distance*(decoding_scheme.number_of_bins-1)+decoding_scheme.bin_size)))';
        time_points_partition_matrix = on_times_partition + bin_points;
        time_points_partition = time_points_partition_matrix(:);
        decision_variable_timecourse(time_points_partition,class_index) = decoding_results_continuous_to_use.Bias_cv{class_index,partition_index} + timecourse_smoothed(time_points_partition,selected_features_decoder_probe) * decoding_results_continuous_to_use.Beta_cv{class_index,partition_index};
    end
end

inference_results.state_timecourse_red = zeros(size(paradigm_data.timecourse_all_units,1),1);
inference_results.state_timecourse_cyan = zeros(size(paradigm_data.timecourse_all_units,1),1);
for trial_index=1:length(on_times_in_range)
    trial_timepoints= on_times_in_range(trial_index)+(time_window(1):time_window(2));
    trial_timepoints = trial_timepoints(trial_timepoints<size(inference_results.state_timecourse,1));
    if trial_is_actually_red(trial_index)
        inference_results.state_timecourse(trial_timepoints) = 1*(decision_variable_timecourse(trial_timepoints,1)<0) + 2*(decision_variable_timecourse(trial_timepoints,1)>0);
        inference_results.state_timecourse_red(trial_timepoints) = 1*(decision_variable_timecourse(trial_timepoints,1)<0) + 2*(decision_variable_timecourse(trial_timepoints,1)>0);
    elseif trial_is_actually_cyan(trial_index)
        inference_results.state_timecourse(trial_timepoints) = 1*(decision_variable_timecourse(trial_timepoints,1)>0) + 2*(decision_variable_timecourse(trial_timepoints,1)<0);
        inference_results.state_timecourse_cyan(trial_timepoints) = 1*(decision_variable_timecourse(trial_timepoints,1)>0) + 2*(decision_variable_timecourse(trial_timepoints,1)<0);

    end
end

figure(1);clf;subplot(1,2,1);histogram(inference_results.state_timecourse_red);
subplot(1,2,2);histogram(inference_results.state_timecourse_cyan);


[inference_results.state_raster, b_in_range_states] = computeRaster(paradigm_data.timecourse_on_times,inference_results.state_timecourse',-peri_stimulus_range(1), peri_stimulus_range(end));
if ~(all(b_in_range_states==b_in_range))
    state_raster_temp = zeros(size(raster,1),size(raster,2));
    state_raster_temp(b_in_range_states,:) = inference_results.state_raster;
    inference_results.state_raster = state_raster_temp;
end


