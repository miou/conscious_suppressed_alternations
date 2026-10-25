function [explained_variance_features,explained_variance_features_cv,explained_variance_features_cv_high_repeat,explained_variance_features_cv_high_repeat_other,explained_variance_features_st,explained_variance_features_st_loto,explained_variance_features_cv_alpha,explained_variance_responses,explained_variance_responses_cv,explained_variance_responses_cv_high_repeat,explained_variance_responses_st,explained_variance_responses_ot_stimulus,explained_variance_responses_cv_weighted_average,explained_variance_responses_cv_high_repeat_weighted_average,explained_variance_responses_cv_high_repeat_weighted_average_across_halves,alpha_strct,predicted_responses_weighted_average...
    ] = flash_suppression_axes_explained_variance(...
    config,features,responses_to_use_testing,responses_st,responses_ot_stimulus,predicted_features,predicted_features_cv,predicted_features_st,predicted_features_st_loto,predicted_responses,predicted_responses_cv,unique_stimuli_is_high_repeat,unique_stimuli,unique_stimulus_index_other_list,responses_priming,responses_dominant_binocular,red_cyan_pair_indices)


%For control 1B, use the features of the template faces (which have been
%shuffled to mismatch the actual presented faces).
if config.b_use_control_1_stimuli && isfield(config,'stim_index_abcd')
    new_unique_stimulus_indices = nan(size(unique_stimuli));
    new_unique_stimulus_indices(config.stim_index_abcd(:,1)) = config.stim_index_abcd(:,3);
    new_unique_stimulus_indices(config.stim_index_abcd(:,2)) = config.stim_index_abcd(:,4);
    features = features(new_unique_stimulus_indices,:);
end

%% Explained variance
%Explained variance of features

explained_variance_features = nan(size(features,2),1);
explained_variance_features_cv = nan(size(features,2),1);
explained_variance_features_cv_high_repeat = nan(size(features,2),1);
explained_variance_features_cv_high_repeat_other = nan(size(features,2),1);
explained_variance_features_st = nan(size(features,2),1);
explained_variance_features_st_loto = nan(size(features,2),1);


for feature_index = 1:size(features,2)
    explained_variance_features(feature_index) = Rsquared(features(:,feature_index),predicted_features(:,feature_index));
    explained_variance_features_cv(feature_index) = Rsquared(features(:,feature_index),predicted_features_cv(:,feature_index));
    explained_variance_features_cv_high_repeat(feature_index) = Rsquared(features(unique_stimuli_is_high_repeat,feature_index),predicted_features_cv(unique_stimuli_is_high_repeat,feature_index));
    explained_variance_features_cv_high_repeat_other(feature_index) = Rsquared(features(unique_stimulus_index_other_list(unique_stimuli_is_high_repeat),feature_index),predicted_features_cv(unique_stimuli_is_high_repeat,feature_index));
    explained_variance_features_st(feature_index) = Rsquared(features(:,feature_index),predicted_features_st(:,feature_index));
    explained_variance_features_st_loto(feature_index) = Rsquared(features(:,feature_index),predicted_features_st_loto(:,feature_index));
end

% (A within-state EV-contrast sign-flip permutation p-value used to be computed and
% printed here. It is NOT one of the statistics reported in the paper -- the reconstruction
% dissociation the paper reports is the paired t-test computed in the figure scripts -- and
% it was never returned or used downstream, so it has been removed.)

alpha_list = 0:.1:1;
features_average = nan(size(responses_to_use_testing,1),size(features,2),length(alpha_list));
%Fit with different alphas
if strcmp(config.use_for_training,'priming')
    for alpha_index=1:length(alpha_list)
        alpha = alpha_list(alpha_index);
        for unique_stimulus_index_to_check = 1:size(responses_to_use_testing,1);
            unique_stimulus_index_other = unique_stimulus_index_other_list(unique_stimulus_index_to_check);
            if ~isnan(unique_stimulus_index_other)
                features_average(unique_stimulus_index_to_check,:,alpha_index) = alpha*features(unique_stimulus_index_to_check,:) + (1-alpha)*features(unique_stimulus_index_other,:);
            end
        end
    end
end
explained_variance_features_cv_alpha = nan(length(alpha_list),size(features,2));
if strcmp(config.use_for_training,'priming')
    for alpha_index=1:length(alpha_list)
        for feature_index = 1:size(features_average,2)
            explained_variance_features_cv_alpha(alpha_index,feature_index) = Rsquared(features_average(unique_stimuli_is_high_repeat,feature_index,alpha_index),predicted_features_cv(unique_stimuli_is_high_repeat,feature_index));
        end
    end
end
%% Explained variance responses
explained_variance_responses = nan(size(responses_to_use_testing,2),1);
explained_variance_responses_cv = nan(size(responses_to_use_testing,2),1);
explained_variance_responses_cv_high_repeat = nan(size(responses_to_use_testing,2),1);
explained_variance_responses_st = nan(size(responses_to_use_testing,2),1);
explained_variance_responses_ot_stimulus = nan(size(responses_to_use_testing,2),1);
explained_variance_responses_cv_weighted_average = nan(size(responses_to_use_testing,2),1);
explained_variance_responses_cv_high_repeat_weighted_average = nan(size(responses_to_use_testing,2),1);
explained_variance_responses_cv_high_repeat_weighted_average_across_halves = nan(size(responses_to_use_testing,2),1);

coefs_alpha = nan(1,size(responses_to_use_testing,2));
coefs_alpha_high_repeat = nan(1,size(responses_to_use_testing,2));
coefs_pred_alpha = nan(1,size(responses_to_use_testing,2));
coefs_pred_alpha_high_repeat = nan(1,size(responses_to_use_testing,2));
coefs_alpha_high_repeat_first_half = nan(1,size(responses_to_use_testing,2));
coefs_alpha_high_repeat_second_half = nan(1,size(responses_to_use_testing,2));
coefs_pred_alpha_high_repeat_first_half = nan(1,size(responses_to_use_testing,2));
coefs_pred_alpha_high_repeat_second_half = nan(1,size(responses_to_use_testing,2));
predicted_responses_weighted_average = nan(size(responses_priming));
%Explained variance of cell responses
%use predicted_responses_cv for each stimulus, and compare with responses_st for single trials or responses_ot_stimulus for average of trials.
for cell_index = 1:size(responses_to_use_testing,2)
    explained_variance_responses(cell_index)=Rsquared(responses_to_use_testing(:,cell_index),predicted_responses(:,cell_index));
    explained_variance_responses_cv(cell_index)=Rsquared(responses_to_use_testing(:,cell_index),predicted_responses_cv(:,cell_index));
    explained_variance_responses_cv_high_repeat(cell_index)=Rsquared(responses_to_use_testing(unique_stimuli_is_high_repeat,cell_index),predicted_responses_cv(unique_stimuli_is_high_repeat,cell_index));
    explained_variance_responses_st(cell_index)=Rsquared(responses_st(:,cell_index),predicted_responses_cv(:,cell_index));
    explained_variance_responses_ot_stimulus(cell_index)=Rsquared(responses_ot_stimulus(:,cell_index),predicted_responses_cv(:,cell_index));
    if ~any(isnan(unique_stimulus_index_other_list))
        warning off;
        %Explain responses with weighted averaging
        %response_binocular = a_1*response_conscious + (1-a_1)*response_suppressed
        %=> response_binocular-response_suppressed=alpha*(response_conscious-response_suppressed)
        %=> alpha = (response_conscious-response_suppressed)\(response_binocular-response_suppressed)
        y_alpha = [responses_dominant_binocular(:,cell_index) - responses_priming(unique_stimulus_index_other_list,cell_index)];
        X_alpha = [responses_priming(:,cell_index) - responses_priming(unique_stimulus_index_other_list,cell_index)];
        coefs_alpha(cell_index) = X_alpha\y_alpha;

        y_alpha_high_repeat = [responses_dominant_binocular(unique_stimuli_is_high_repeat,cell_index) - responses_priming(unique_stimulus_index_other_list(unique_stimuli_is_high_repeat),cell_index)];
        X_alpha_high_repeat = [responses_priming(unique_stimuli_is_high_repeat,cell_index) - responses_priming(unique_stimulus_index_other_list(unique_stimuli_is_high_repeat),cell_index)];
        coefs_alpha_high_repeat(cell_index) = X_alpha_high_repeat\y_alpha_high_repeat;

        %Debug confirmed that switching to suppressed makes
        %it 1-alpha

        y_pred_alpha = [responses_dominant_binocular(:,cell_index) - predicted_responses_cv(unique_stimulus_index_other_list,cell_index)];
        X_pred_alpha = [predicted_responses_cv(:,cell_index) - predicted_responses_cv(unique_stimulus_index_other_list,cell_index)];
        coefs_pred_alpha(cell_index) = X_pred_alpha\y_pred_alpha;

        y_pred_alpha_high_repeat = [responses_dominant_binocular(unique_stimuli_is_high_repeat,cell_index) - predicted_responses_cv(unique_stimulus_index_other_list(unique_stimuli_is_high_repeat),cell_index)];
        X_pred_alpha_high_repeat = [predicted_responses_cv(unique_stimuli_is_high_repeat,cell_index) - predicted_responses_cv(unique_stimulus_index_other_list(unique_stimuli_is_high_repeat),cell_index)];
        coefs_pred_alpha_high_repeat(cell_index) = X_pred_alpha_high_repeat\y_pred_alpha_high_repeat;

        pair_is_high_repeat = unique_stimuli_is_high_repeat(red_cyan_pair_indices(:,1)) & unique_stimuli_is_high_repeat(red_cyan_pair_indices(:,2));
        high_repeat_pair_indices = find(pair_is_high_repeat);
        shuffled_pair_indices = shuffle_array(high_repeat_pair_indices);
        pair_indices_first_half = shuffled_pair_indices(1:round(length(shuffled_pair_indices)/2));
        indices_first_half = sort([red_cyan_pair_indices(pair_indices_first_half,1);red_cyan_pair_indices(pair_indices_first_half,2)]);
        pair_indices_second_half = shuffled_pair_indices((1+round(length(shuffled_pair_indices)/2)):end);
        indices_second_half = sort([red_cyan_pair_indices(pair_indices_second_half,1);red_cyan_pair_indices(pair_indices_second_half,2)]);

        coefs_alpha_high_repeat_first_half(cell_index) = X_alpha(indices_first_half)\y_alpha(indices_first_half);
        coefs_alpha_high_repeat_second_half(cell_index) = X_alpha(indices_second_half)\y_alpha(indices_second_half);

        coefs_pred_alpha_high_repeat_first_half(cell_index) = X_pred_alpha(indices_first_half)\y_pred_alpha(indices_first_half);
        coefs_pred_alpha_high_repeat_second_half(cell_index) = X_pred_alpha(indices_second_half)\y_pred_alpha(indices_second_half);
        warning on;
        predicted_responses_weighted_average(:,cell_index) = (coefs_alpha_high_repeat(cell_index))*responses_priming(:,cell_index) + (1-coefs_alpha_high_repeat(cell_index))*responses_priming(unique_stimulus_index_other_list,cell_index);
        explained_variance_responses_cv_weighted_average(cell_index)=Rsquared(responses_dominant_binocular(:,cell_index),predicted_responses_weighted_average(:,cell_index));
        explained_variance_responses_cv_high_repeat_weighted_average(cell_index)=Rsquared(responses_dominant_binocular(unique_stimuli_is_high_repeat,cell_index),predicted_responses_weighted_average(unique_stimuli_is_high_repeat,cell_index));


        explained_variance_responses_cv_high_repeat_weighted_average_across_halves(cell_index)=Rsquared(responses_dominant_binocular(indices_second_half,cell_index),(coefs_alpha_high_repeat_first_half(cell_index))*responses_priming(indices_second_half,cell_index) + (1-coefs_alpha_high_repeat_first_half(cell_index))*responses_priming(unique_stimulus_index_other_list(indices_second_half),cell_index));
    else
        explained_variance_responses_cv_weighted_average(cell_index)=nan;explained_variance_responses_cv_high_repeat_weighted_average(cell_index)=nan;explained_variance_responses_cv_high_repeat_weighted_average_across_halves(cell_index)=nan;
    end
end

alpha_strct = struct();
alpha_strct.coefs_alpha = coefs_alpha;
alpha_strct.coefs_alpha_high_repeat = coefs_alpha_high_repeat;
alpha_strct.coefs_pred_alpha = coefs_pred_alpha;
alpha_strct.coefs_pred_alpha_high_repeat = coefs_pred_alpha_high_repeat;
alpha_strct.coefs_alpha_high_repeat_first_half = coefs_alpha_high_repeat_first_half;
alpha_strct.coefs_alpha_high_repeat_second_half = coefs_alpha_high_repeat_second_half;
alpha_strct.coefs_pred_alpha_high_repeat_first_half = coefs_pred_alpha_high_repeat_first_half;
alpha_strct.coefs_pred_alpha_high_repeat_second_half = coefs_pred_alpha_high_repeat_second_half;