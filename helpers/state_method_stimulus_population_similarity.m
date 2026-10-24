function inference_results = state_method_stimulus_population_similarity(inference_scheme,session,paradigm_index);
inference_results = struct;

if isfield(inference_scheme,'selection_method')
    selection_method = inference_scheme.selection_method;
else
    selection_method = 'all';
end
if isfield(inference_scheme,'selected_probe')
    selected_probe = inference_scheme.selected_probe;
else
    selected_probe = [];
end
folder_name = [session.analysis_path filesep 'stimulus_population_similarity'];
mkdir(folder_name)
paradigm_data = session.paradigms_data{paradigm_index};
trial_time_window = [300 paradigm_data.on_duration];

inference_results.state_timecourse = zeros(size(paradigm_data.timecourse_all_units,1),1);
%Define priming, dominant, and suppressed stimuli and paradigms
flash_suppression_get_variables;
raster_state = raster;
nanmean_function = @(x) squeeze(nanmean(reshape(x,[],1,size(x,3)),1));

flash_suppression_compute_modulation_indices_all;
if strcmp(selection_method,'all')
    b_selected_cells=true(1,size(raster,3));
elseif strcmp(selection_method,'face_selective')
    b_selected_cells= and(session.face_vs_object(paradigm_data.paradigm_index_for_selectivity).fsi>0, session.face_vs_object(paradigm_data.paradigm_index_for_selectivity).p_value_face_vs_object<0.05);
end

if ~isempty(inference_scheme.selected_probe)
    b_selected_probe = session.unit_probes_index == inference_scheme.selected_probe;
else
    b_selected_probe = true(1,size(paradigm_data.timecourse_all_units,2));
end

if isfield(inference_scheme,'select_random_half') && ~isempty(inference_scheme.select_random_half) && inference_scheme.select_random_half
    selected_half_indices = randperm(size(paradigm_data.timecourse_all_units,2),round(size(paradigm_data.timecourse_all_units,2)/2));
    b_selected_half  = ismember(1:size(paradigm_data.timecourse_all_units,2),selected_half_indices);
    inference_results.selected_indices_for_state_inference = selected_half_indices;
else
    b_selected_half = true(1,size(paradigm_data.timecourse_all_units,2));
end

timecourse_smoothed = smoothdata(paradigm_data.timecourse_all_units(:,:)',2,'movmean',inference_scheme.time_window)';

if inference_scheme.b_standardize_units
    gray_duration = median(on_durations_in_range(trial_is_gray));
    neurons_mean= mean(mean(raster(trial_is_gray,find(50 == peri_stimulus_range):find(gray_duration == peri_stimulus_range),:),2),1);
    neurons_std= std(mean(raster(trial_is_gray,find(50 == peri_stimulus_range):find(gray_duration == peri_stimulus_range),:)),[],2);
    neurons_std(neurons_std==0) = inf;
    raster = (raster - neurons_mean)./neurons_std;
    timecourse_smoothed = (timecourse_smoothed - shiftdim(neurons_mean,1))./shiftdim(neurons_std,1);
end

[responses_priming_stimuli, responses_priming_stimuli_minus_baseline,responses_baseline] = flash_suppression_get_priming_responses(raster,peri_stimulus_range,trial_time_window,priming_stimuli_list,priming_stimuli,stimulus_index_in_range);
if inference_scheme.b_shuffle_control
    responses_priming_stimuli = responses_priming_stimuli(randperm(size(responses_priming_stimuli_minus_baseline,1)),:);
    responses_priming_stimuli_minus_baseline = responses_priming_stimuli_minus_baseline(randperm(size(responses_priming_stimuli_minus_baseline,1)),:);
end
timecourse_smoothed_minus_baseline = timecourse_smoothed-responses_baseline;


projection_dominant_normalized_raster = nan(length(on_times_in_range),trial_time_window(2)-trial_time_window(1)+1);
projection_suppressed_normalized_raster = nan(length(on_times_in_range),trial_time_window(2)-trial_time_window(1)+1);
inference_results.projection_dominant_normalized_timecourse = nan(size(paradigm_data.timecourse_all_units,1),1);
inference_results.projection_suppressed_normalized_timecourse = nan(size(paradigm_data.timecourse_all_units,1),1);

for trial_index=1:length(on_times_in_range)
    current_trial_dominant_image = trial_dominant_image{trial_index};
    current_trial_suppressed_image = trial_suppressed_image{trial_index};
    if ~isempty(current_trial_dominant_image) && ((~strcmp(selection_method,'pair_selective')) || ismember(current_trial_dominant_image,[high_repeat_images_red high_repeat_images_cyan])) %Only include high repeat images?
        if strcmp(selection_method,'pair_selective')
            if ismember(current_trial_dominant_image,flash_suppression_results.images_red_for_modulation)
                R_1 = find(strcmp(current_trial_dominant_image,flash_suppression_results.images_red_for_modulation));
                C_1 = find(strcmp(current_trial_suppressed_image,flash_suppression_results.images_cyan_for_modulation));
            elseif ismember(current_trial_dominant_image,flash_suppression_results.images_cyan_for_modulation)
                C_1 = find(strcmp(current_trial_dominant_image,flash_suppression_results.images_cyan_for_modulation));
                R_1 = find(strcmp(current_trial_suppressed_image,flash_suppression_results.images_red_for_modulation));
            end
            b_selected_cells = flash_suppression_results.priming.responses_p_value(:,R_1,C_1)'<0.05;
        end
        b_selected_cells_probe = b_selected_cells & b_selected_probe & b_selected_half;
        priming_stimulus_index_dominant = find(strcmp(priming_stimuli_list,current_trial_dominant_image));
        priming_stimulus_index_suppressed = find(strcmp(priming_stimuli_list,current_trial_suppressed_image));
        trial_timepoints= on_times_in_range(trial_index)+(trial_time_window(1):trial_time_window(2));
        trial_timepoints = trial_timepoints(trial_timepoints<=size(timecourse_smoothed_minus_baseline,1));

        trial_difference_from_dominant_timecourse = responses_priming_stimuli_minus_baseline(priming_stimulus_index_dominant,b_selected_cells_probe) - timecourse_smoothed_minus_baseline(trial_timepoints,b_selected_cells_probe);
        trial_difference_from_suppressed_timecourse = responses_priming_stimuli_minus_baseline(priming_stimulus_index_suppressed,b_selected_cells_probe) - timecourse_smoothed_minus_baseline(trial_timepoints,b_selected_cells_probe);

        projection_dominant_timecourse = dot(repmat(responses_priming_stimuli_minus_baseline(priming_stimulus_index_dominant,b_selected_cells_probe),[length(trial_timepoints) 1]),timecourse_smoothed_minus_baseline(trial_timepoints,b_selected_cells_probe),2);
        projection_suppressed_timecourse = dot(repmat(responses_priming_stimuli_minus_baseline(priming_stimulus_index_suppressed,b_selected_cells_probe),[length(trial_timepoints) 1]),timecourse_smoothed_minus_baseline(trial_timepoints,b_selected_cells_probe),2);

        self_projection_dominant = dot(responses_priming_stimuli_minus_baseline(priming_stimulus_index_dominant,b_selected_cells_probe),responses_priming_stimuli_minus_baseline(priming_stimulus_index_dominant,b_selected_cells_probe));
        self_projection_suppressed = dot(responses_priming_stimuli_minus_baseline(priming_stimulus_index_suppressed,b_selected_cells_probe),responses_priming_stimuli_minus_baseline(priming_stimulus_index_suppressed,b_selected_cells_probe));

        projection_dominant_normalized_raster(trial_index,1:length(trial_timepoints)) = projection_dominant_timecourse/self_projection_dominant;
        projection_suppressed_normalized_raster(trial_index,1:length(trial_timepoints)) = projection_suppressed_timecourse/self_projection_suppressed;

        inference_results.projection_dominant_normalized_timecourse(trial_timepoints) = projection_dominant_normalized_raster(trial_index,1:length(trial_timepoints));
        inference_results.projection_suppressed_normalized_timecourse(trial_timepoints) = projection_suppressed_normalized_raster(trial_index,1:length(trial_timepoints));
        inference_results.state_timecourse(trial_timepoints) = 1*(projection_dominant_normalized_raster(trial_index,1:length(trial_timepoints))>projection_suppressed_normalized_raster(trial_index,1:length(trial_timepoints))) + 2*(projection_dominant_normalized_raster(trial_index,1:length(trial_timepoints))<projection_suppressed_normalized_raster(trial_index,1:length(trial_timepoints)));
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
histogram2(reshape(projection_suppressed_normalized_raster(trial_is_priming,:),1,[]),reshape(projection_dominant_normalized_raster(trial_is_priming,:),1,[]),-2:0.1:2,-2:0.1:2,'FaceColor','flat');
xlabel('Projection onto dominant');ylabel('Projection onto suppressed');xlim([-2 2]);ylim([-2 2]);axis square;colormap parula
plot3(0,1,[max(zlim)],'bx','MarkerSize',20);plot3(1,0,[max(zlim)],'cx','MarkerSize',20);plot3(0, 0,[max(zlim)],'ko','MarkerSize',20);plot3([-2 2],[-2 2],[max(zlim) max(zlim)],'k--')
file_name = [folder_name filesep 'projection_priming_dominant_suppressed'];
print(f,file_name, '-dpng','-r0')
f=figure(2);clf;hold on;
histogram2(reshape(projection_dominant_normalized_raster(trial_is_binocular,:),1,[]),reshape(projection_suppressed_normalized_raster(trial_is_binocular,:),1,[]),-2:0.1:2,-2:0.1:2,'FaceColor','flat');
xlabel('Projection onto dominant');ylabel('Projection onto suppressed');xlim([-2 2]);ylim([-2 2]);axis square;colormap parula
plot3(0,1,[max(zlim)],'bx','MarkerSize',20);plot3(1,0,[max(zlim)],'cx','MarkerSize',20);plot3(0, 0,[max(zlim)],'ko','MarkerSize',20);plot3([-2 2],[-2 2],[max(zlim) max(zlim)],'k--')
file_name = [folder_name filesep 'projection_binocular_dominant_suppressed'];
print(f,file_name, '-dpng','-r0')
f=figure(3);clf;hold on;
histogram2(reshape(projection_suppressed_normalized_raster(trial_is_binocular,:),1,[]),reshape(projection_dominant_normalized_raster(trial_is_binocular,:),1,[]),-2:0.1:2,-2:0.1:2,'FaceColor','flat');
xlabel('Projection onto suppressed');ylabel('Projection onto dominant');xlim([-2 2]);ylim([-2 2]);axis square;colormap parula
plot3(0,1,[max(zlim)],'bx','MarkerSize',20);plot3(1,0,[max(zlim)],'cx','MarkerSize',20);plot3(0, 0,[max(zlim)],'ko','MarkerSize',20);plot3([-2 2],[-2 2],[max(zlim) max(zlim)],'k--')
file_name = [folder_name filesep 'projection_binocular_dominant_suppressed_reversed'];
print(f,file_name, '-dpng','-r0')