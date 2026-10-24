function [b_good_face_trial,b_good_object_trial] = make_inferred_percepts_stringent(inferred_percepts,rivalry_num_fixation_required_before,rivalry_num_fixation_required_after,b_consecutive,b_logical_and)
%Makes inferred_percepts more stringent.
%rivalry_num_fixation_required_before/rivalry_num_fixation_required_after is the number of fixations required before/after the current one. If both are 0: fixation during the current trial is sufficient to infer percept.
if nargin<=3
    b_consecutive = false; %Default does not require consecutive fixations
end

if nargin<=4
    b_logical_and = false;
end
[trial_cumulative_face_forward,trial_cumulative_object_forward,trial_cumulative_face_backward,trial_cumulative_object_backward] = cumulative_fixations(inferred_percepts.b_trials_fixated_face,inferred_percepts.b_trials_fixated_object,b_consecutive);
if b_logical_and
    b_cumulative_face_trial = trial_cumulative_face_forward>=(rivalry_num_fixation_required_before+1) & trial_cumulative_face_backward>=(rivalry_num_fixation_required_after+1);
    b_cumulative_object_trial = trial_cumulative_object_forward>=(rivalry_num_fixation_required_before+1) & trial_cumulative_object_backward>=(rivalry_num_fixation_required_after+1);
else
    b_cumulative_face_trial = trial_cumulative_face_forward>=(rivalry_num_fixation_required_before+1) | trial_cumulative_face_backward>=(rivalry_num_fixation_required_after+1);
    b_cumulative_object_trial = trial_cumulative_object_forward>=(rivalry_num_fixation_required_before+1) | trial_cumulative_object_backward>=(rivalry_num_fixation_required_after+1);
end
b_good_face_trial = b_cumulative_face_trial & inferred_percepts.b_trials_fixated_face;
b_good_object_trial = b_cumulative_object_trial & inferred_percepts.b_trials_fixated_object;