function [trial_cumulative_face_forward,trial_cumulative_object_forward,trial_cumulative_face_backward,trial_cumulative_object_backward] = cumulative_fixations(b_trials_fixated_face,b_trials_fixated_object,b_consecutive)
trial_cumulative_face_forward = zeros(size(b_trials_fixated_face));
trial_cumulative_object_forward = zeros(size(b_trials_fixated_object));
trial_cumulative_face_forward(1) = b_trials_fixated_face(1);
trial_cumulative_object_forward(1) = b_trials_fixated_object(1);
for trial_index = 2:length(b_trials_fixated_face)
    if b_trials_fixated_face(trial_index)
        trial_cumulative_face_forward(trial_index) = trial_cumulative_face_forward(trial_index-1) + 1;
        trial_cumulative_object_forward(trial_index) = 0;
        last_face_trial_index = trial_index;
    elseif b_trials_fixated_object(trial_index)
        trial_cumulative_object_forward(trial_index) = trial_cumulative_object_forward(trial_index-1) + 1;
        trial_cumulative_face_forward(trial_index) = 0;
        last_object_trial_index = trial_index;
    else
        if b_consecutive
            trial_cumulative_face_forward(trial_index) = 0;
            trial_cumulative_object_forward(trial_index) = 0;
        else
            trial_cumulative_face_forward(trial_index) = trial_cumulative_face_forward(trial_index-1);
            trial_cumulative_object_forward(trial_index) = trial_cumulative_object_forward(trial_index-1);
        end
    end
end

trial_cumulative_face_backward = zeros(size(b_trials_fixated_face));
trial_cumulative_object_backward = zeros(size(b_trials_fixated_object));
trial_cumulative_face_forward(end) = b_trials_fixated_face(end);
trial_cumulative_object_forward(end) = b_trials_fixated_object(end);
for trial_index = (length(b_trials_fixated_face)-1):-1:1
    if b_trials_fixated_face(trial_index)
        trial_cumulative_face_backward(trial_index) = trial_cumulative_face_backward(trial_index+1) + 1;
        trial_cumulative_object_backward(trial_index) = 0;
        last_face_trial_index = trial_index;
    elseif b_trials_fixated_object(trial_index)
        trial_cumulative_object_backward(trial_index) = trial_cumulative_object_backward(trial_index+1) + 1;
        trial_cumulative_face_backward(trial_index) = 0;
        last_object_trial_index = trial_index;
    else
        if b_consecutive
            trial_cumulative_face_forward(trial_index) = 0;
            trial_cumulative_object_forward(trial_index) = 0;
        else
            trial_cumulative_face_backward(trial_index) = trial_cumulative_face_backward(trial_index+1);
            trial_cumulative_object_backward(trial_index) = trial_cumulative_object_backward(trial_index+1);
        end
    end
end