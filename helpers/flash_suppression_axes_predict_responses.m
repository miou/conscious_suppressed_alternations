function [weights_predicting_features,weights_predicting_responses,predicted_features,predicted_features_cv,predicted_features_st,predicted_features_st_loto,predicted_responses,predicted_responses_cv] = flash_suppression_axes_predict_responses(config,features,responses_to_use_training,responses_to_use_testing,responses_st,responses_ot_stimulus,unique_stimulus_index_other_list)

%% Compute weights predicting features and responses
lin_regress  = @(x,y)lscov(x,y);
% lin_regress  = @(x,y)regress(y,x); %Not working, only for vectors y
% lin_regress  = @(x,y)mldivide(x,y); % Same results as lscov?
% lin_regress  = @(x,y)(x'*x + 1*eye(size(x,2))) \ (x'*y); %lambda = 1? This one is different and does not break for larger number of neurons than stimuli - though reconstruction accuracy is worse.

% Callers that only need the response-predicting axes (weights_predicting_responses /
% predicted_responses_cv) -- e.g. the single-cell tuning figure -- can set
% config.skip_feature_predictions=true to skip the expensive all-cell regressions
% (weights_predicting_features*) that feed ONLY the feature-prediction outputs. The
% returned feature outputs are then [] / NaN. Default (unset/false) => identical behaviour.
b_predict_features = ~(isfield(config,'skip_feature_predictions') && config.skip_feature_predictions);

warning off
if config.use_axes_from_first_paradigm == 0 || paradigm_list_index ==1
    %Without cross-validation, almost the same result
    if b_predict_features
        weights_predicting_features = lin_regress([ones(size(responses_to_use_training,1),1), responses_to_use_training],features);
    else
        weights_predicting_features = [];
    end
    weights_predicting_responses = lin_regress([ones(size(features,1),1),features],responses_to_use_training);
elseif config.use_axes_from_first_paradigm == 1 %only use first paradigm
    weights_predicting_features = weights_predicting_features_all_paradigms{1};
    weights_predicting_responses = weights_predicting_responses_all_paradigms{1};
elseif config.use_axes_from_first_paradigm == 2 % Recompute weights based data from first and current paradigm
    weights_predicting_features = lin_regress([ones(size(responses_to_use_training_all_paradigms{1},1),1), responses_to_use_training_all_paradigms{1};  ones(size(responses_priming,1),1), responses_to_use_training],[features_all_paradigms{1};features;]);
    weights_predicting_responses = lin_regress([ones(size(features_all_paradigms{1},1),1),features_all_paradigms{1};  ones(size(features,1),1),features],[responses_to_use_training_all_paradigms{1};responses_to_use_training]);
end
warning on


if b_predict_features
    predicted_features = [ones(size(responses_to_use_testing,1),1), responses_to_use_testing] * weights_predicting_features;
else
    predicted_features = [];
end
predicted_responses = [ones(size(features,1),1), features] * weights_predicting_responses;

% (A per-cell intercepts/gains regression loop used to sit here. Its outputs were
% never returned by this function and nothing downstream used them, so it has been
% removed -- it changed no result and cost a regress() per cell on every call.)

predicted_features_st = nan(size(features));

%% Cross-validated predictions
%Cross-validated leave-one-out
predicted_features_cv = nan(size(features));
predicted_responses_cv = nan(size(responses_to_use_training));
predicted_features_st_loto = nan(size(features));

for stimulus_index = 1:size(responses_to_use_training,1)
    b_is_stimulus = false(1,size(responses_to_use_training,1));
    b_is_stimulus(stimulus_index) = true;
    b_exclude_stimulus = b_is_stimulus;
    if isfield(config,'remove_other_stimulus_from_training') && config.remove_other_stimulus_from_training
        b_exclude_stimulus(unique_stimulus_index_other_list(stimulus_index)) = true;
        
    end
    %Leave-one-image-out: response-predicting axis (cheap: features -> responses).
    %Always computed -- feeds predicted_responses_cv, which every caller uses.
    warning off
    weights_predicting_responses_cv = lin_regress([ones(size(responses_to_use_training(~b_exclude_stimulus,:),1),1), features(~b_exclude_stimulus,:)],responses_to_use_training(~b_exclude_stimulus,:));
    warning on;
    predicted_responses_cv(stimulus_index,:) = [ones(size(features(b_is_stimulus,:),1),1), features(b_is_stimulus,:)] * weights_predicting_responses_cv;

    if b_predict_features
        %Feature-predicting axis (expensive: all-cell design matrix). Only feeds the
        %feature-prediction outputs, so skipped when skip_feature_predictions is set.
        warning off
        weights_predicting_features_cv = lin_regress([ones(size(responses_to_use_training(~b_exclude_stimulus,:),1),1), responses_to_use_training(~b_exclude_stimulus,:)],features(~b_exclude_stimulus,:));
        warning on;
        predicted_features_cv(stimulus_index,:) = [ones(size(responses_to_use_testing(b_is_stimulus,:),1),1), responses_to_use_testing(b_is_stimulus,:)] * weights_predicting_features_cv;

        if ~all(isnan(responses_st(stimulus_index,:)))
            %Leave-one-image-out single trial
            predicted_features_st(stimulus_index,:) = [ones(size(responses_st(stimulus_index,:),1),1), responses_st(stimulus_index,:)] * weights_predicting_features_cv;
        end
        %Leave-one-trial out single trial
        %Other trials are being used for training.
        responses_ot = responses_to_use_training;
        responses_ot(stimulus_index,:) = responses_ot_stimulus(stimulus_index,:);

        warning off;weights_predicting_features_ot = lin_regress([ones(size(responses_ot,1),1), responses_ot],features);warning on;
        predicted_features_st_loto(stimulus_index,:) = [ones(size(responses_st(stimulus_index,:),1),1), responses_st(stimulus_index,:)] * weights_predicting_features_ot;
    end

end
