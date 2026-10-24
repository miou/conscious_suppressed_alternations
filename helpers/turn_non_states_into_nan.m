function [raster] = turn_non_states_into_nan(raster,config,session,paradigm_index,peristimulus_index_range_of_interest)

raster = single(raster);
if isfield(config,'states_to_use') && ~isempty(config.states_to_use) % Set non-states to NaN
    inference_schemes_index = find(strcmp({session.inference_schemes.name},config.states_to_use.inference_scheme));

    b_is_state = session.inference_results{paradigm_index,inference_schemes_index}.state_raster == config.states_to_use.state_value;
    %Balance to have same number of states for each trial
    if config.balance_states_each_trial
        b_is_state_balanced = b_is_state;
        b_is_state_balanced(:,peristimulus_index_range_of_interest) = false; %Only balance peristimulus_index_range_of_interest, everything else will use the same state as without control 
        for trial_index = 1:size(b_is_state,1)
            proportion_state_1 = mean(session.inference_results{paradigm_index,inference_schemes_index}.state_raster(trial_index,peristimulus_index_range_of_interest)==1);
            proportion_state_2 = mean(session.inference_results{paradigm_index,inference_schemes_index}.state_raster(trial_index,peristimulus_index_range_of_interest)==2);
            smallest_proportion = min(proportion_state_1,proportion_state_2);
            state_time_points = find(b_is_state(trial_index,peristimulus_index_range_of_interest));
            state_time_points_subselected = state_time_points(randperm(length(state_time_points),round(smallest_proportion*length(peristimulus_index_range_of_interest))));
            b_is_state_balanced(trial_index,peristimulus_index_range_of_interest(state_time_points_subselected)) = true;

        end
        b_is_state = b_is_state_balanced;
    end
    if config.minimum_state_proportion_per_trial
        b_trial_has_proportion = mean(b_is_state(:,peristimulus_index_range_of_interest),2)>=config.minimum_state_proportion_per_trial & mean(b_is_state(:,peristimulus_index_range_of_interest),2)<=(1-config.minimum_state_proportion_per_trial);
        b_is_state(~b_trial_has_proportion,peristimulus_index_range_of_interest) = false; %Set all to false if the trial does not have enough time points of both states
    end

    for cell_index = 1:size(raster,3) % To reduce memory demands
        raster_slice = raster(:,:,cell_index);
        raster_slice(~b_is_state) = NaN;
        raster(:,:,cell_index) = raster_slice;
    end
    %Faster alternative that needs more memory:
end