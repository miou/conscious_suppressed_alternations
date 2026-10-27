function [b_selected,features,responses_to_use_training,responses_to_use_testing,responses_st,responses_ot_stimulus,responses_priming,responses_dominant_binocular,responses_suppressed_binocular]...
    = flash_suppression_axes_get_features_responses(...
    config,session,paradigm_data,raster_state,unique_stimuli,unique_stimulus_index_other_list,number_of_features,feat_map,feat_map_stim_condition_stimulus,feat_map_stim_names,stimulus_index_in_range,priming_stimuli,dominant_image,suppressed_image,b_trial_in_range_is_proportion_priming,trial_is_binocular_context,b_trial_in_range_is_proportion);

flash_suppression_get_variables;

gray_duration = median(on_durations_in_range(trial_is_gray));

if config.b_normalize_raster_for_axes
    neurons_mean= mean(mean(raster(trial_is_gray,find(50 == peri_stimulus_range):find(gray_duration == peri_stimulus_range),:),2),1);
    neurons_std= std(mean(raster(trial_is_gray,find(50 == peri_stimulus_range):find(gray_duration == peri_stimulus_range),:)),[],2);
    neurons_std(neurons_std==0) = inf;
else
    neurons_mean = 0;
    neurons_std = 1;
end




%% Select cells
% config.cell_selection_scheme = 'all'.
b_selected = true(1,session.number_of_units);

if  config.probe_index
    b_selected = b_selected & (session.unit_probes_index == config.probe_index);
end

%For inference schemes that only use half of the neurons, use the other
%neurons for computing axes.
if isfield(config,'states_to_use') && ~isempty(config.states_to_use) 
    inference_schemes_index = find(strcmp({session.inference_schemes.name},config.states_to_use.inference_scheme));
    if isfield(session.inference_results{config.paradigm_index,inference_schemes_index},'selected_indices_for_state_inference')
        b_selected = b_selected & (~ismember(1:length(b_selected),session.inference_results{config.paradigm_index,inference_schemes_index}.selected_indices_for_state_inference));
    end
end

%Apply after averaging:
if isempty(config.avg_first_dimension) || config.avg_first_dimension == 0 %average across all non-nan time points of a given stimulus
    nanmean_function = @(x) (squeeze(nanmean(reshape(x,[],1,size(x,3)),1)) - squeeze(neurons_mean(b_selected)))./squeeze(neurons_std(b_selected));
elseif config.avg_first_dimension == 1 %average across all trials first, then peri-stimulus-range time points
    nanmean_function = @(x) (squeeze(nanmean(nanmean(x,1),2)) - squeeze(neurons_mean(b_selected)))./squeeze(neurons_std(b_selected));
elseif config.avg_first_dimension == 2 %average across time of each trial first, trials
    nanmean_function = @(x) (squeeze(nanmean(nanmean(x,2),1)) - squeeze(neurons_mean(b_selected)))./squeeze(neurons_std(b_selected));
end



features = nan(length(unique_stimuli),number_of_features);
responses_priming = nan(length(unique_stimuli),sum(b_selected));
responses_dominant_binocular = nan(length(unique_stimuli),sum(b_selected));
responses_suppressed_binocular = nan(length(unique_stimuli),sum(b_selected));
responses_priming_testing = nan(length(unique_stimuli),sum(b_selected));
responses_dominant_binocular_testing = nan(length(unique_stimuli),sum(b_selected));
responses_suppressed_binocular_testing = nan(length(unique_stimuli),sum(b_selected));

start_index_priming = find(peri_stimulus_range==config.time_window_priming(1));
end_index_priming = find(peri_stimulus_range==config.time_window_priming(2));
start_index_binocular = find(peri_stimulus_range==config.time_window_binocular(1));
end_index_binocular = find(peri_stimulus_range==config.time_window_binocular(2));

b_trial_is_priming_stimulus = false(length(unique_stimuli),length(stimulus_index_in_range));
b_trial_is_dominant_stimulus_binocular = false(length(unique_stimuli),length(stimulus_index_in_range));
b_trial_is_suppressed_stimulus_binocular = false(length(unique_stimuli),length(stimulus_index_in_range));
%First fill up relevant responses with original rasters
for stimulus_index = 1:length(unique_stimuli)
    condition_stimulus = unique_stimuli{stimulus_index};
    b_trial_is_priming_stimulus(stimulus_index,:) = strcmp(priming_stimuli(stimulus_index_in_range),condition_stimulus) & b_trial_in_range_is_proportion_priming;
    b_trial_is_dominant_stimulus_binocular(stimulus_index,:) = b_trial_in_range_is_proportion & strcmp(dominant_image(stimulus_index_in_range),condition_stimulus) & trial_is_binocular_context;
    b_trial_is_suppressed_stimulus_binocular(stimulus_index,:) = b_trial_in_range_is_proportion & strcmp(suppressed_image(stimulus_index_in_range),condition_stimulus) & trial_is_binocular_context;
    if ~isfield(config,'states_to_use') || isempty(config.states_to_use) || config.states_to_use.only_apply_to_testing %Use original rasters for training, no NaNs, cause there are no states, or states are only applied to testing
        responses_priming(stimulus_index,:) = nanmean_function(raster(b_trial_is_priming_stimulus(stimulus_index,:),start_index_priming:end_index_priming,b_selected));
        responses_dominant_binocular(stimulus_index,:) = nanmean_function(raster(b_trial_is_dominant_stimulus_binocular(stimulus_index,:),start_index_binocular:end_index_binocular,b_selected));
        responses_suppressed_binocular(stimulus_index,:) = nanmean_function(raster(b_trial_is_suppressed_stimulus_binocular(stimulus_index,:),start_index_binocular:end_index_binocular,b_selected));
    end
    if ~isfield(config,'states_to_use') || isempty(config.states_to_use) %Use original rasters for training, no NaNs, cause there are no states
        responses_priming_testing(stimulus_index,:) = nanmean_function(raster(b_trial_is_priming_stimulus(stimulus_index,:),start_index_priming:end_index_priming,b_selected));
        responses_dominant_binocular_testing(stimulus_index,:) = nanmean_function(raster(b_trial_is_dominant_stimulus_binocular(stimulus_index,:),start_index_binocular:end_index_binocular,b_selected));
        responses_suppressed_binocular_testing(stimulus_index,:) = nanmean_function(raster(b_trial_is_suppressed_stimulus_binocular(stimulus_index,:),start_index_binocular:end_index_binocular,b_selected));
    end
end

%Second, fill up relevant responses with NaN-containing rasters
for stimulus_index = 1:length(unique_stimuli)
    if isfield(config,'states_to_use') && ~isempty(config.states_to_use) && ~config.states_to_use.only_apply_to_testing %Use NaN-containing rasters for training, cause there are states, and states do not only apply to testing
        responses_priming(stimulus_index,:) = nanmean_function(raster_state(b_trial_is_priming_stimulus(stimulus_index,:),start_index_priming:end_index_priming,b_selected));
        responses_dominant_binocular(stimulus_index,:) = nanmean_function(raster_state(b_trial_is_dominant_stimulus_binocular(stimulus_index,:),start_index_binocular:end_index_binocular,b_selected));
        responses_suppressed_binocular(stimulus_index,:) = nanmean_function(raster_state(b_trial_is_suppressed_stimulus_binocular(stimulus_index,:),start_index_binocular:end_index_binocular,b_selected));
    end
    if isfield(config,'states_to_use') && ~isempty(config.states_to_use) %Use original rasters for training, no NaNs, cause there are no states
        responses_priming_testing(stimulus_index,:) = nanmean_function(raster_state(b_trial_is_priming_stimulus(stimulus_index,:),start_index_priming:end_index_priming,b_selected));
        responses_dominant_binocular_testing(stimulus_index,:) = nanmean_function(raster_state(b_trial_is_dominant_stimulus_binocular(stimulus_index,:),start_index_binocular:end_index_binocular,b_selected));
        responses_suppressed_binocular_testing(stimulus_index,:) = nanmean_function(raster_state(b_trial_is_suppressed_stimulus_binocular(stimulus_index,:),start_index_binocular:end_index_binocular,b_selected));
    end
end

nan_stimuli = find(any(isnan(responses_priming),2));
if ~isempty(nan_stimuli)
   for nan_stimuli_index = 1:length(nan_stimuli)
       nan_stimulus_index = nan_stimuli(nan_stimuli_index);
       disp(['Warning: No states of selected value found for responses_priming stimulus ' num2str(nan_stimulus_index) '. Setting to average.'])
       responses_priming(nan_stimulus_index,:) = nanmean(responses_priming,1);
       responses_priming_testing(nan_stimulus_index,:) = nanmean(responses_priming,1);
   end
end
nan_stimuli = find(any(isnan(responses_dominant_binocular),2));
if ~isempty(nan_stimuli)
   for nan_stimuli_index = 1:length(nan_stimuli)
       nan_stimulus_index = nan_stimuli(nan_stimuli_index);
       disp(['Warning: No states of selected value found for responses_dominant_binocular stimulus ' num2str(nan_stimulus_index) '. Setting to average.'])
       responses_dominant_binocular(nan_stimulus_index,:) = nanmean(responses_dominant_binocular,1);
       responses_dominant_binocular_testing(nan_stimulus_index,:) = nanmean(responses_dominant_binocular,1);
   end
end
nan_stimuli = find(any(isnan(responses_suppressed_binocular),2));
if ~isempty(nan_stimuli)
   for nan_stimuli_index = 1:length(nan_stimuli)
       nan_stimulus_index = nan_stimuli(nan_stimuli_index);
       disp(['Warning: No states of selected value found for responses_suppressed_binocular stimulus ' num2str(nan_stimulus_index) '. Setting to average.'])
       responses_suppressed_binocular(nan_stimulus_index,:) = nanmean(responses_suppressed_binocular,1);
       responses_suppressed_binocular_testing(nan_stimulus_index,:) = nanmean(responses_suppressed_binocular,1);
   end
end

for stimulus_index = 1:length(unique_stimuli)
    condition_stimulus = unique_stimuli{stimulus_index};
    if ~isempty(features)
        feat_map_stim_index = find(strcmp(feat_map_stim_condition_stimulus,condition_stimulus));
        feat_map_stim_name = feat_map_stim_names{feat_map_stim_index};
        features(stimulus_index,:) = feat_map(feat_map_stim_name);
    end
end

if config.b_concatenate_features_other
    features = [features features(unique_stimulus_index_other_list,:)];
    number_of_features = number_of_features*2;
end

if strcmp(config.use_for_training,'priming')
    responses_to_use_training = responses_priming;
    start_index_training = start_index_priming;
    end_index_training = end_index_priming;
elseif strcmp(config.use_for_training,'dominant_binocular')
    responses_to_use_training = responses_dominant_binocular;
    start_index_training = start_index_binocular;
    end_index_training = end_index_binocular;
elseif strcmp(config.use_for_training,'suppressed_binocular')
    responses_to_use_training = responses_suppressed_binocular;
    start_index_training = start_index_binocular;
    end_index_training = end_index_binocular;
end
if strcmp(config.use_for_testing,'priming')
    responses_to_use_testing = responses_priming_testing;
    start_index_testing = start_index_priming;
    end_index_testing = end_index_priming;
elseif strcmp(config.use_for_testing,'dominant_binocular')
    responses_to_use_testing = responses_dominant_binocular_testing;
    start_index_testing = start_index_binocular;
    end_index_testing = end_index_binocular;
elseif strcmp(config.use_for_testing,'suppressed_binocular')
    responses_to_use_testing = responses_suppressed_binocular_testing;
    start_index_testing = start_index_binocular;
    end_index_testing = end_index_binocular;
end

if strcmp(config.use_for_testing,'priming')
    stimulus_trial_indices = shuffle_array(find(b_trial_is_priming_stimulus(stimulus_index,:)));
elseif strcmp(config.use_for_testing,'dominant_binocular')
    stimulus_trial_indices = shuffle_array(find(b_trial_is_dominant_stimulus_binocular(stimulus_index,:)));
elseif strcmp(config.use_for_testing,'suppressed_binocular')
    stimulus_trial_indices = shuffle_array(find(b_trial_is_suppressed_stimulus_binocular(stimulus_index,:)));
end

responses_ot_stimulus = nan(size(responses_to_use_training));
responses_st = nan(size(responses_to_use_training));
for stimulus_index = 1:size(responses_to_use_training,1)
    if config.b_use_same_random_stimuli_across_iterations %Re-randomize
        rng('shuffle')
    end

    %Use testing stimuli
    if strcmp(config.use_for_testing,'priming')
        stimulus_trial_indices = shuffle_array(find(b_trial_is_priming_stimulus(stimulus_index,:)));
    elseif strcmp(config.use_for_testing,'dominant_binocular')
        stimulus_trial_indices = shuffle_array(find(b_trial_is_dominant_stimulus_binocular(stimulus_index,:)));
    elseif strcmp(config.use_for_testing,'suppressed_binocular')
        stimulus_trial_indices = shuffle_array(find(b_trial_is_suppressed_stimulus_binocular(stimulus_index,:)));
    end
    if stimulus_trial_indices
        %We can just use the raster for responses_st, because we are supposed to use testing raster, and the testing raster will be contain NaNs for non-states if there are states
        responses_st(stimulus_index,:) = nanmean_function(raster_state(stimulus_trial_indices(1),start_index_testing:end_index_testing,b_selected))'; %Select single trial
    end

    if ~strcmp(config.use_for_training,config.use_for_testing) %One trial out does not really make sense if training and testing are different type, but adding it anyway for completeness:
        if strcmp(config.use_for_training,'priming')
            stimulus_trial_indices = shuffle_array(find(b_trial_is_priming_stimulus(stimulus_index,:)));
        elseif strcmp(config.use_for_training,'dominant_binocular')
            stimulus_trial_indices = shuffle_array(find(b_trial_is_dominant_stimulus_binocular(stimulus_index,:)));
        elseif strcmp(config.use_for_training,'suppressed_binocular')
            stimulus_trial_indices = shuffle_array(find(b_trial_is_suppressed_stimulus_binocular(stimulus_index,:)));
        end
    end
    if length(stimulus_trial_indices)>1
        responses_ot_stimulus(stimulus_index,:) = nanmean_function(raster_state(stimulus_trial_indices(2:end),start_index_training:end_index_training,b_selected))'; %All other trials (template vector)
    end
    if any(isnan(responses_ot_stimulus(stimulus_index,:)))
    end
end

