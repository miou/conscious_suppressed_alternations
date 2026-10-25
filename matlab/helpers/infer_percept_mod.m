function session = infer_percept_mod(session,paradigm_data)

[fix_positions, face_fix_positions_index, object_fix_positions_index,stim_on_duration,stim_original_size] = define_no_report_paradigm(paradigm_data.paradigm_name);
fixation_time_proportion = 0.5; % proportion of time required to stay in fixation square
fixation_square_radius = 25; % in pixels
fixation_lag = 350; % in ms

correction_time_window = [];

start_index = find(paradigm_data.peri_stimulus_range == 0);
end_index = find(paradigm_data.peri_stimulus_range == stim_on_duration);

if isempty(correction_time_window)
    eye_x_valid_corrected = paradigm_data.eyex_valid;
else
    zero_x_fix_positions = find(fix_positions(:,1)==0);
    zero_x_stimulus_indices = find( and(or(isnan(face_fix_positions_index),ismember(face_fix_positions_index,zero_x_fix_positions)),...
        or(isnan(object_fix_positions_index),ismember(object_fix_positions_index,zero_x_fix_positions))) );
    zero_x_trial_indices = find(ismember(paradigm_data.stimulus_index_valid, zero_x_stimulus_indices));
    fixation_offset_x = nan(size(paradigm_data.eyex_valid,1),length((start_index+fixation_lag):end_index));
    fixation_offset_x(zero_x_trial_indices,:) = paradigm_data.eyex_valid(zero_x_trial_indices,(start_index+fixation_lag):end_index);
    fixation_offset_x(abs(fixation_offset_x)>2*fixation_square_radius) = nan; %Monkey was probably not looking
    fixation_offset_x_trial = nanmedian(fixation_offset_x,2);
    fixation_offset_x_trial_smoothed = fillmissing(smooth(fixation_offset_x_trial,correction_time_window,'moving'),'nearest');
    eye_x_valid_corrected = paradigm_data.eyex_valid - repmat(fixation_offset_x_trial_smoothed,[1 size(paradigm_data.eyex_valid,2)]);
end
if isempty(correction_time_window)
    eye_y_valid_corrected = paradigm_data.eyey_valid;
else
    zero_y_fix_positions = find(fix_positions(:,2)==0);
    zero_y_stimulus_indices = find( and(or(isnan(face_fix_positions_index),ismember(face_fix_positions_index,zero_y_fix_positions)),...
        or(isnan(object_fix_positions_index),ismember(object_fix_positions_index,zero_y_fix_positions))) );
    zero_y_trial_indices = find(ismember(paradigm_data.stimulus_index_valid, zero_y_stimulus_indices));
    fixation_offset_y = nan(size(paradigm_data.eyey_valid,1),length((start_index+fixation_lag):end_index));
    fixation_offset_y(zero_y_trial_indices,:) = paradigm_data.eyey_valid(zero_y_trial_indices,(start_index+fixation_lag):end_index);
    fixation_offset_y(abs(fixation_offset_y)>2*fixation_square_radius) = nan; %Monkey was probably not looking
    fixation_offset_y_trial = nanmedian(fixation_offset_y,2);
    fixation_offset_y_trial_smoothed = fillmissing(smooth(fixation_offset_y_trial,correction_time_window,'moving'),'nearest');
    eye_y_valid_corrected = paradigm_data.eyey_valid - repmat(fixation_offset_y_trial_smoothed,[1 size(paradigm_data.eyey_valid,2)]);
end
presented_image_size = paradigm_data.stimulus_size*2;
fix_positions_on_screen = presented_image_size*fix_positions/stim_original_size;

trial_face_position_indices = face_fix_positions_index(paradigm_data.stimulus_index_valid);
trial_object_position_indices = object_fix_positions_index(paradigm_data.stimulus_index_valid);
b_proportion_in_fixation_square= nan(length(paradigm_data.stimulus_index_valid),length(fix_positions));
for fix_position_index = 1:length(fix_positions)
    b_in_fixation_square = (abs(eye_x_valid_corrected(:,start_index+fixation_lag:end_index) - fix_positions_on_screen(fix_position_index,1) ) < fixation_square_radius) ...
        & (abs(eye_y_valid_corrected(:,start_index+fixation_lag:end_index) - fix_positions_on_screen(fix_position_index,2) ) < fixation_square_radius);
    b_proportion_in_fixation_square(:,fix_position_index) = mean(b_in_fixation_square,2);

end
[best_match_proportion,best_match_index] = max(b_proportion_in_fixation_square,[],2);
b_trials_fixated = best_match_proportion>=fixation_time_proportion;
b_trials_fixated_face = and(b_trials_fixated, best_match_index == trial_face_position_indices);
b_trials_fixated_object = and(b_trials_fixated, best_match_index == trial_object_position_indices);


%% Detect saccades
time_window_for_saccade_detection = 60;
b_in_fixated_fixation_square = nan(length(paradigm_data.stimulus_index_valid),length(start_index:end_index)); %num_trials x num_time_points
saccade_reaction_time = nan(length(paradigm_data.stimulus_index_valid),1);
distance_from_face_fixation_spot_raster = nan(size(eye_x_valid_corrected));
distance_from_object_fixation_spot_raster = nan(size(eye_x_valid_corrected));
for trial_index = 1:length(paradigm_data.stimulus_index_valid)
    if b_trials_fixated(trial_index) %Compute when saccade to fixation spot was made
        fix_position_index = best_match_index(trial_index);
        b_in_fixated_fixation_square(trial_index,:) = (abs(eye_x_valid_corrected(trial_index,start_index:end_index) - fix_positions_on_screen(fix_position_index,1) ) < fixation_square_radius) ...
            & (abs(eye_y_valid_corrected(trial_index,start_index:end_index) - fix_positions_on_screen(fix_position_index,2) ) < fixation_square_radius);
        fixation_proportion_timecourse = movmean(b_in_fixated_fixation_square(trial_index,:),[0 time_window_for_saccade_detection-1],'Endpoints',0);
        time_index = find(fixation_proportion_timecourse >= fixation_time_proportion,1); %First time where for the next 'time_window_for_saccade_detection' time points at least half of the time the monkey fixated.
        saccade_reaction_time(trial_index) = time_index + time_window_for_saccade_detection/2;
    end
    %Compute distance of face and object fixation spot, respectively.
    if isnan(trial_face_position_indices(trial_index))
        distance_from_face_fixation_spot_raster(trial_index,:) = nan;
    else
        distance_from_face_fixation_spot_raster(trial_index,:) = vecnorm([eye_x_valid_corrected(trial_index,:) - fix_positions_on_screen(trial_face_position_indices(trial_index),1);eye_y_valid_corrected(trial_index,:) - fix_positions_on_screen(trial_face_position_indices(trial_index),2)],2,1);
    end
    if isnan(trial_object_position_indices(trial_index))
        distance_from_object_fixation_spot_raster(trial_index,:) = nan;
    else
        distance_from_object_fixation_spot_raster(trial_index,:) = vecnorm([eye_x_valid_corrected(trial_index,:) - fix_positions_on_screen(trial_object_position_indices(trial_index),1);eye_y_valid_corrected(trial_index,:) - fix_positions_on_screen(trial_object_position_indices(trial_index),2)],2,1);
    end
end

% Field 'b_use_fixed_trial_duration_for_timecourse' wasn't in session, so I
% had to add value for it here. I assume that it is false, because even if
% it's true, the function will still compute the correct result, but just
% slower. 
B_USE_FIXED_TRIAL_DURATION_FOR_TIMECOURSE = 0;
distance_from_face_fixation_spot_timecourse = convert_raster_to_timecourse(distance_from_face_fixation_spot_raster,start_index,end_index,B_USE_FIXED_TRIAL_DURATION_FOR_TIMECOURSE,paradigm_data.trial_durations,paradigm_data.timecourse_on_times);
distance_from_object_fixation_spot_timecourse = convert_raster_to_timecourse(distance_from_object_fixation_spot_raster,start_index,end_index,B_USE_FIXED_TRIAL_DURATION_FOR_TIMECOURSE,paradigm_data.trial_durations,paradigm_data.timecourse_on_times);
assert(length(distance_from_face_fixation_spot_timecourse) == size(paradigm_data.timecourse_all_units,1))

proportion_correctly_fixated_all_trials = sum(b_trials_fixated_face+b_trials_fixated_object)/length(b_trials_fixated);
proportion_correctly_fixated_fixating_trials = sum(b_trials_fixated_face+b_trials_fixated_object)/sum(b_trials_fixated);

trials_fixated_face_times = (find(b_trials_fixated_face)-1)*(paradigm_data.on_duration+paradigm_data.off_duration+1)+1;
trials_fixated_object_times = (find(b_trials_fixated_object)-1)*(paradigm_data.on_duration+paradigm_data.off_duration+1)+1;

session.inferred_percepts(paradigm_data.paradigm_index).proportion_correctly_fixated_all_trials = proportion_correctly_fixated_all_trials;
session.inferred_percepts(paradigm_data.paradigm_index).proportion_correctly_fixated_fixating_trials  = proportion_correctly_fixated_fixating_trials;
session.inferred_percepts(paradigm_data.paradigm_index).b_trials_fixated = b_trials_fixated;
session.inferred_percepts(paradigm_data.paradigm_index).b_trials_fixated_face = b_trials_fixated_face;
session.inferred_percepts(paradigm_data.paradigm_index).b_trials_fixated_object  = b_trials_fixated_object ;
session.inferred_percepts(paradigm_data.paradigm_index).trials_fixated_face_times = trials_fixated_face_times;
session.inferred_percepts(paradigm_data.paradigm_index).trials_fixated_object_times  = trials_fixated_object_times ;
session.inferred_percepts(paradigm_data.paradigm_index).saccade_reaction_time = saccade_reaction_time;
session.inferred_percepts(paradigm_data.paradigm_index).b_in_fixated_fixation_square = b_in_fixated_fixation_square;
session.inferred_percepts(paradigm_data.paradigm_index).distance_from_face_fixation_spot_timecourse = distance_from_face_fixation_spot_timecourse;
session.inferred_percepts(paradigm_data.paradigm_index).distance_from_object_fixation_spot_timecourse = distance_from_object_fixation_spot_timecourse;
