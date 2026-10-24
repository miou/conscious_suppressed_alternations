function [percentage_correct,  percentage_correct_cv, percentage_correct_st, percentage_correct_st_loto, percentage_correct_responses_st_loto,pairwise_distances_responses_st_loto,percentage_correct_cv_other, correct_cv_per_stim, correct_cvo_per_stim, count_per_stim] = ...
    flash_suppression_axes_decoding(...
    config,number_of_stimuli_for_decoding_list,folder_name,features,predicted_features,predicted_features_cv,predicted_features_st,predicted_features_st_loto,responses_st,responses_ot_stimulus,unique_stimuli_is_high_repeat,explained_variance_features_cv_high_repeat,unique_stimulus_index_other_list,num_iterations);

b_compare_one_reconstruction_to_all_ground_truths = true;

if config.b_use_control_1_stimuli && isfield(config,'stim_index_abcd')
    new_unique_stimulus_indices = nan(size(features,1),1);
    new_unique_stimulus_indices(config.stim_index_abcd(:,1)) = config.stim_index_abcd(:,3);
    new_unique_stimulus_indices(config.stim_index_abcd(:,2)) = config.stim_index_abcd(:,4);
    features = features(new_unique_stimulus_indices,:);
end

percentage_correct = nan(length(number_of_stimuli_for_decoding_list),num_iterations);
percentage_correct_cv = nan(length(number_of_stimuli_for_decoding_list),num_iterations);
percentage_correct_st = nan(length(number_of_stimuli_for_decoding_list),num_iterations);
percentage_correct_st_loto = nan(length(number_of_stimuli_for_decoding_list),num_iterations);
percentage_correct_responses_st_loto = nan(length(number_of_stimuli_for_decoding_list),num_iterations);
percentage_correct_cv_other = nan(length(number_of_stimuli_for_decoding_list),num_iterations);
pairwise_distances_responses_st_loto = nan(length(number_of_stimuli_for_decoding_list),length(number_of_stimuli_for_decoding_list));
% Per-stimulus decodability at the 10-way level (stimulus is the unit of inference for the permutation test)
correct_cv_per_stim  = zeros(size(features,1),1);
correct_cvo_per_stim = zeros(size(features,1),1);
count_per_stim       = zeros(size(features,1),1);
per_stim_number_of_identities = 10;

%% Decoding
for iteration_index = 1:num_iterations

    rng(iteration_index);
    for number_of_stimuli_for_decoding_index = 1:length(number_of_stimuli_for_decoding_list)
        number_of_stimuli_for_decoding = number_of_stimuli_for_decoding_list(number_of_stimuli_for_decoding_index);

        if config.b_use_same_random_stimuli_across_iterations
            rng(config.b_use_same_random_stimuli_across_iterations)
           
        end
            if config.only_test_for_decoding
                unique_stimuli_test_indices = find(unique_stimuli_is_high_repeat);
                if number_of_stimuli_for_decoding<=length(unique_stimuli_test_indices)
                    stimuli_for_decoding = unique_stimuli_test_indices(randperm(length(unique_stimuli_test_indices),number_of_stimuli_for_decoding));
                else
                    break
                end
            else
                stimuli_for_decoding = randperm(length(unique_stimuli),number_of_stimuli_for_decoding);
            end

        %All features
        %Features 1-50 (works better)
        selected_features = 1:50;
        %Features with explained variance > 0 (works about the same)

        b_normalize_features = true; %works better

        distance_metric = @(x,y) vecnorm(x-y,2,2);


        if b_normalize_features
            features_mean=mean(features,1);
            features_std = std(features,[],1);
        else
            features_mean=zeros(1,size(features,2));
            features_std = ones(1,size(features,2));
        end
        features_for_decoding = (features(:,selected_features) - features_mean(selected_features))./features_std(selected_features);
        features_for_decoding_other = (features(unique_stimulus_index_other_list,selected_features) - features_mean(selected_features))./features_std(selected_features);
        predicted_features_for_decoding = (predicted_features(:,selected_features) - features_mean(selected_features))./features_std(selected_features);
        predicted_features_for_decoding = (predicted_features(:,selected_features) - features_mean(selected_features))./features_std(selected_features);
        predicted_features_cv_for_decoding = (predicted_features_cv(:,selected_features) - features_mean(selected_features))./features_std(selected_features);
        predicted_features_cv_for_decoding_other = (predicted_features_cv(unique_stimulus_index_other_list,selected_features) - features_mean(selected_features))./features_std(selected_features);
        predicted_features_st_for_decoding = (predicted_features_st(:,selected_features) - features_mean(selected_features))./features_std(selected_features);
        predicted_features_st_loto_for_decoding = (predicted_features_st_loto(:,selected_features) - features_mean(selected_features))./features_std(selected_features);


        number_correct_decodings = 0;
        number_correct_decodings_cv = 0;
        number_correct_decodings_cv_other = 0;
        number_correct_decodings_st = 0;
        number_correct_decodings_st_loto = 0;
        number_correct_decodings_responses_st_loto = 0;
        for stimuli_for_decoding_index = 1:number_of_stimuli_for_decoding
            stimulus_index = stimuli_for_decoding(stimuli_for_decoding_index);
            if b_compare_one_reconstruction_to_all_ground_truths
                features_stimulus = predicted_features_for_decoding(stimulus_index,:);
                distances = distance_metric(features_stimulus, features_for_decoding(stimuli_for_decoding,:));
            else
                features_stimulus = features_for_decoding(stimulus_index,:);
                distances = distance_metric(features_stimulus, predicted_features_for_decoding(stimuli_for_decoding,:));
            end
            [min_distance,min_distance_stimulus_index] = min(distances);
            if min_distance_stimulus_index == stimuli_for_decoding_index
                number_correct_decodings = number_correct_decodings+1;
            end

            if b_compare_one_reconstruction_to_all_ground_truths
                features_stimulus = predicted_features_cv_for_decoding(stimulus_index,:);
                distances_cv = distance_metric(features_stimulus, features_for_decoding(stimuli_for_decoding,:));
            else
                features_stimulus = features_for_decoding(stimulus_index,:);
                distances_cv = distance_metric(features_stimulus, predicted_features_cv_for_decoding(stimuli_for_decoding,:));
            end
            [min_distance,min_distance_stimulus_index_cv] = min(distances_cv);
            if min_distance_stimulus_index_cv == stimuli_for_decoding_index
                number_correct_decodings_cv = number_correct_decodings_cv+1;
            end
            if b_compare_one_reconstruction_to_all_ground_truths
                features_stimulus = predicted_features_st_for_decoding(stimulus_index,:);
                distances_st = distance_metric(features_stimulus, features_for_decoding(stimuli_for_decoding,:));
            else
                features_stimulus = features_for_decoding(stimulus_index,:);
                distances_st = distance_metric(features_stimulus, predicted_features_st_for_decoding(stimuli_for_decoding,:));
            end
            [min_distance,min_distance_stimulus_index_st] = min(distances_st);
            if min_distance_stimulus_index_st == stimuli_for_decoding_index
                number_correct_decodings_st = number_correct_decodings_st+1;
            end
            if b_compare_one_reconstruction_to_all_ground_truths
                features_stimulus = predicted_features_st_loto_for_decoding(stimulus_index,:);
                distances_st_loto = distance_metric(features_stimulus, features_for_decoding(stimuli_for_decoding,:));
            else
                features_stimulus = features_for_decoding(stimulus_index,:);
                distances_st_loto = distance_metric(features_stimulus, predicted_features_st_loto_for_decoding(stimuli_for_decoding,:));
            end
            [min_distance,min_distance_stimulus_index_st_loto] = min(distances_st_loto);
            if min_distance_stimulus_index_st_loto == stimuli_for_decoding_index
                number_correct_decodings_st_loto = number_correct_decodings_st_loto+1;
            end

            responses_stimulus_st = responses_st(stimulus_index,:); %test vector
            distances_responses_st_loto = distance_metric(responses_stimulus_st, responses_ot_stimulus(stimuli_for_decoding,:)); %responses_ot_stimulus = template vector
            [min_distance,min_distance_stimulus_index_responses_loto] = min(distances_responses_st_loto);
            if number_of_stimuli_for_decoding_index == length(number_of_stimuli_for_decoding_list)
                pairwise_distances_responses_st_loto(stimuli_for_decoding_index,:) = distances_responses_st_loto;
            end
            if min_distance_stimulus_index_responses_loto == stimuli_for_decoding_index
                number_correct_decodings_responses_st_loto = number_correct_decodings_responses_st_loto+1;
            end

            if b_compare_one_reconstruction_to_all_ground_truths
                features_stimulus = predicted_features_cv_for_decoding_other(stimulus_index,:);
                distances_cv_other = distance_metric(features_stimulus, features_for_decoding(stimuli_for_decoding,:));
            else
                features_stimulus_other = features_for_decoding_other(stimulus_index,:);
                distances_cv_other = distance_metric(features_stimulus_other, predicted_features_cv_for_decoding(stimuli_for_decoding,:));
            end
            [min_distance,min_distance_stimulus_index_cv_other] = min(distances_cv_other);
            if min_distance_stimulus_index_cv_other == stimuli_for_decoding_index
                number_correct_decodings_cv_other = number_correct_decodings_cv_other+1;
            end
            if number_of_stimuli_for_decoding == per_stim_number_of_identities
                correct_cv_per_stim(stimulus_index)  = correct_cv_per_stim(stimulus_index)  + (min_distance_stimulus_index_cv       == stimuli_for_decoding_index);
                correct_cvo_per_stim(stimulus_index) = correct_cvo_per_stim(stimulus_index) + (min_distance_stimulus_index_cv_other == stimuli_for_decoding_index);
                count_per_stim(stimulus_index)       = count_per_stim(stimulus_index) + 1;
            end

        end
        percentage_correct(number_of_stimuli_for_decoding,iteration_index) = number_correct_decodings/number_of_stimuli_for_decoding;
        percentage_correct_cv(number_of_stimuli_for_decoding,iteration_index) = number_correct_decodings_cv/number_of_stimuli_for_decoding;
        percentage_correct_st(number_of_stimuli_for_decoding,iteration_index) = number_correct_decodings_st/number_of_stimuli_for_decoding;
        percentage_correct_st_loto(number_of_stimuli_for_decoding,iteration_index) = number_correct_decodings_st_loto/number_of_stimuli_for_decoding;
        percentage_correct_responses_st_loto(number_of_stimuli_for_decoding,iteration_index) = number_correct_decodings_responses_st_loto/number_of_stimuli_for_decoding;
        percentage_correct_cv_other(number_of_stimuli_for_decoding,iteration_index) = number_correct_decodings_cv_other/number_of_stimuli_for_decoding;
    end
end
end
