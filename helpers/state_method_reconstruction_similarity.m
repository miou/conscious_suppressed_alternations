function inference_results = state_method_reconstruction_similarity(inference_scheme,session,paradigm_index);
inference_results = struct;


config.use_axes_from_first_paradigm = 0;
config.b_use_same_random_stimuli_across_iterations = false; %seed number or false
config.b_normalize_raster_for_axes = inference_scheme.b_standardize_units;
config.time_window_priming = [300 1000];
config.time_window_binocular = [300 1000];
config.b_concatenate_features_other = false;
config.use_for_training = inference_scheme.use_for_training; %'priming', 'dominant_binocular', or 'suppressed_binocular'
config.use_for_testing = 'dominant_binocular'; % Does not matter
config.use_half_stimuli = 0;
config.min_number_occurences = 1; %Less for flash suppression?
config.b_plot_single_cells=false;
config.states_to_use = [];
config.avg_first_dimension = 0; %Does not matter when there are no states

config.paradigm_index = find(cellfun(@(x)~isempty(x) && (contains(x,'flash_suppression_many_stimuli') ),session.paradigm_names,'UniformOutput',true) ); %Liang's monkey faces
config.microstim_trials_to_include = [];
config.psychedelic_trials_to_include = [];
config.proportion_of_trials=1;
config.stimuli_to_include = '';
config.cell_selection_scheme = inference_scheme.selection_method;
config.probe_index = [];

folder_name = [session.analysis_path filesep inference_scheme.name];
mkdir(folder_name)
paradigm_data = session.paradigms_data{paradigm_index};

flash_suppression_get_variables

if contains(paradigm_data.xml_filename,'FlashSuppression_many_faces_Liang_2500_many_pairs_priming_reconstructed_0.00_transparent.xml')
    config.analyze_transparent = true;
else
    config.analyze_transparent = false;
end


%% Get stimuli
[config,folder_name,peri_stimulus_range,unique_stimuli,unique_stimulus_index_other_list,unique_stimuli_is_high_repeat,unique_stimuli_is_red,unique_stimuli_is_cyan,red_cyan_pair_indices,number_of_features,xml_folder,xml_filename,feat_map,feat_map_stim_condition_stimulus,feat_map_stim_names,stimulus_index_in_range,priming_stimuli,dominant_image,suppressed_image,b_trial_in_range_is_proportion_priming,trial_is_binocular,b_trial_in_range_is_proportion,number_of_stimuli_total_list,number_of_stimuli_for_decoding_list]...
    =flash_suppression_axes_get_stimuli(...
    config,session,paradigm_data,[]);
%% Compute features and responses
[b_selected,features,responses_to_use_training,responses_to_use_testing,responses_st,responses_ot_stimulus,responses_priming,responses_dominant_binocular,responses_suppressed_binocular]...
    = flash_suppression_axes_get_features_responses...
    (config,session,paradigm_data,raster,unique_stimuli,unique_stimulus_index_other_list,number_of_features,feat_map,feat_map_stim_condition_stimulus,feat_map_stim_names,stimulus_index_in_range,priming_stimuli,dominant_image,suppressed_image,b_trial_in_range_is_proportion_priming,trial_is_binocular,b_trial_in_range_is_proportion);

%% Normalize and select features
features_normalized = zscore(features,[],1);
if isfield(inference_scheme,'selected_features') && ~isempty(inference_scheme.selected_features)
    features = features_normalized(:,inference_scheme.selected_features);
else
    features = features_normalized(:,:);
end
%% Compute weights for features
[weights_predicting_features,weights_predicting_responses,predicted_features,predicted_features_cv,predicted_features_st,predicted_features_st_loto,predicted_responses,predicted_responses_cv]...
    = flash_suppression_axes_predict_responses( ...
    config,features,responses_to_use_training,responses_to_use_testing,responses_st,responses_ot_stimulus,unique_stimulus_index_other_list);


inference_results.state_timecourse = zeros(size(paradigm_data.timecourse_all_units,1),1);
%Define priming, dominant, and suppressed stimuli and paradigms
timecourse_smoothed = smoothdata(paradigm_data.timecourse_all_units(:,:)',2,'movmean',inference_scheme.time_window)';
%% Normalize time course
if inference_scheme.b_standardize_units
    gray_duration = median(on_durations_in_range(trial_is_gray));
    neurons_mean= mean(mean(raster(trial_is_gray,find(50 == peri_stimulus_range):find(gray_duration == peri_stimulus_range),:),2),1);
    neurons_std= std(mean(raster(trial_is_gray,find(50 == peri_stimulus_range):find(gray_duration == peri_stimulus_range),:)),[],2);
    neurons_std(neurons_std==0) = inf;

    timecourse_smoothed = (timecourse_smoothed - shiftdim(neurons_mean,1))./shiftdim(neurons_std,1);
end
%% Select neurons
timecourse_smoothed = timecourse_smoothed(:,b_selected);

predicted_features_timecourse = [ones(size(timecourse_smoothed,1),1), timecourse_smoothed] * weights_predicting_features;

time_window = [300 paradigm_data.on_duration];

start_index=find(peri_stimulus_range==time_window(1));
end_index=find(peri_stimulus_range==time_window(2));

%% Compute time courses
projection_dominant_normalized_timecourse = nan(length(on_times_in_range),time_window(2)-time_window(1)+1);
projection_suppressed_normalized_timecourse = nan(length(on_times_in_range),time_window(2)-time_window(1)+1);
for trial_index=1:length(on_times_in_range)
    current_trial_dominant_image = trial_dominant_image{trial_index};
    current_trial_suppressed_image = trial_suppressed_image{trial_index};
    if ~isempty(current_trial_dominant_image) 
        priming_stimulus_index_dominant = find(strcmp(priming_stimuli_list,current_trial_dominant_image));
        priming_stimulus_index_suppressed = find(strcmp(priming_stimuli_list,current_trial_suppressed_image));
        trial_timepoints= on_times_in_range(trial_index)+(time_window(1):time_window(2));
        trial_timepoints = trial_timepoints(trial_timepoints<=size(predicted_features_timecourse,1));

        projection_dominant_timecourse = dot(repmat(features(priming_stimulus_index_dominant,:),[length(trial_timepoints) 1]),predicted_features_timecourse(trial_timepoints,:),2);
        projection_suppressed_timecourse = dot(repmat(features(priming_stimulus_index_suppressed,:),[length(trial_timepoints) 1]),predicted_features_timecourse(trial_timepoints,:),2);

        self_projection_dominant = dot(features(priming_stimulus_index_dominant,:),features(priming_stimulus_index_dominant,:));
        self_projection_suppressed = dot(features(priming_stimulus_index_suppressed,:),features(priming_stimulus_index_suppressed,:));

        projection_dominant_normalized_timecourse(trial_index,1:length(trial_timepoints)) = projection_dominant_timecourse/self_projection_dominant;
        projection_suppressed_normalized_timecourse(trial_index,1:length(trial_timepoints)) = projection_suppressed_timecourse/self_projection_suppressed;

        inference_results.state_timecourse(trial_timepoints) = 1*(projection_dominant_normalized_timecourse(trial_index,1:length(trial_timepoints))>projection_suppressed_normalized_timecourse(trial_index,1:length(trial_timepoints))) + 2*(projection_dominant_normalized_timecourse(trial_index,1:length(trial_timepoints))<projection_suppressed_normalized_timecourse(trial_index,1:length(trial_timepoints)));
    end
end
[inference_results.state_raster, b_in_range_states] = computeRaster(paradigm_data.timecourse_on_times,inference_results.state_timecourse',-peri_stimulus_range(1), peri_stimulus_range(end));
if ~(all(b_in_range_states==b_in_range))
    state_raster_temp = zeros(size(raster,1),size(raster,2));
    state_raster_temp(b_in_range_states,:) = inference_results.state_raster;
    inference_results.state_raster = state_raster_temp;
end
f=figure(1);clf;hold on;
%Turn around for priming
histogram2(reshape(projection_suppressed_normalized_timecourse(trial_is_priming,:),1,[]),reshape(projection_dominant_normalized_timecourse(trial_is_priming,:),1,[]),-2:0.1:2,-2:0.1:2,'FaceColor','flat');
xlabel('Projection onto dominant');ylabel('Projection onto suppressed');xlim([-2 2]);ylim([-2 2]);axis square;
plot3(0,1,[max(zlim)],'bx','MarkerSize',20);plot3(1,0,[max(zlim)],'cx','MarkerSize',20);plot3(0, 0,[max(zlim)],'ko','MarkerSize',20);plot3([-2 2],[-2 2],[max(zlim) max(zlim)],'k--')
file_name = [folder_name filesep 'projection_priming_dominant_suppressed'];
print(f,file_name, '-dpng','-r0')
f=figure(2);clf;hold on;
histogram2(reshape(projection_dominant_normalized_timecourse(trial_is_binocular,:),1,[]),reshape(projection_suppressed_normalized_timecourse(trial_is_binocular,:),1,[]),-2:0.1:2,-2:0.1:2,'FaceColor','flat');
xlabel('Projection onto dominant');ylabel('Projection onto suppressed');xlim([-2 2]);ylim([-2 2]);axis square;
plot3(0,1,[max(zlim)],'bx','MarkerSize',20);plot3(1,0,[max(zlim)],'cx','MarkerSize',20);plot3(0, 0,[max(zlim)],'ko','MarkerSize',20);plot3([-2 2],[-2 2],[max(zlim) max(zlim)],'k--')
file_name = [folder_name filesep 'projection_binocular_dominant_suppressed'];
print(f,file_name, '-dpng','-r0')
f=figure(3);clf;hold on;
histogram2(reshape(projection_suppressed_normalized_timecourse(trial_is_binocular,:),1,[]),reshape(projection_dominant_normalized_timecourse(trial_is_binocular,:),1,[]),-2:0.1:2,-2:0.1:2,'FaceColor','flat');
xlabel('Projection onto suppressed');ylabel('Projection onto dominant');xlim([-2 2]);ylim([-2 2]);axis square;
plot3(0,1,[max(zlim)],'bx','MarkerSize',20);plot3(1,0,[max(zlim)],'cx','MarkerSize',20);plot3(0, 0,[max(zlim)],'ko','MarkerSize',20);plot3([-2 2],[-2 2],[max(zlim) max(zlim)],'k--')
file_name = [folder_name filesep 'projection_binocular_dominant_suppressed_reversed'];
print(f,file_name, '-dpng','-r0')
