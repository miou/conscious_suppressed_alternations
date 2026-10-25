function timecourse = convert_raster_to_timecourse(raster,start_index,end_index,b_use_fixed_trial_duration_for_timecourse,timecourse_trial_durations,timecourse_on_times); 
if b_use_fixed_trial_duration_for_timecourse
    timecourse = reshape(raster(:,start_index:end_index)',[1 length(start_index:end_index)*size(raster,1)])'; % Concatenate raster rows into a time course
else
    timecourse = zeros(sum(timecourse_trial_durations),1,class(raster));
    for trial_index = 1:size(raster,1)
        timecourse(timecourse_on_times(trial_index):(timecourse_on_times(trial_index)+timecourse_trial_durations(trial_index)-1)) = raster(trial_index,start_index:(start_index+timecourse_trial_durations(trial_index)-1));
    end
end