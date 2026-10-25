function decoding_results = switches_decoder_aux(training_feature_matrix_standardized,training_label_vector,testing_feature_matrix_standardized,testing_label_vector,decoding_scheme)

if ~isfield(decoding_scheme,'lambda')
    decoding_scheme.lambda = 'auto';
end
coding = 'onevsall'; %for multi-class fitcecoc without hyperparameter optimization. default: onevsone, onevsall is twice as fast and slightly better
if ~isfield(decoding_scheme,'learners') %legacy reasons, default learner 'svm' is much slower but good for multi-class with many neurons
    learners = 'linear'; % learner for fitcecoc without hyperparameter optimization. default: svm, linear is 25% faster and better for single degraded condition
else
    learners = decoding_scheme.learners; % learner for fitcecoc without hyperparameter optimization.
end
number_of_classes = unique(length(unique(training_label_vector)));
if isempty(testing_label_vector) && all(size(testing_label_vector)==0)
    
    if ~isfield(decoding_scheme,'stratify')
        decoding_scheme.stratify = false; %for legacy reasons, stratify is probably better.
    end
    %% Training and testing on same data set
    if isfield(decoding_scheme,'cvpartition')
        cvpartition_to_use = decoding_scheme.cvpartition;
    elseif isfield(decoding_scheme,'kfold')
        if decoding_scheme.stratify
            cvpartition_to_use = cvpartition(training_label_vector,'KFold',decoding_scheme.kfold,'Stratify',true);
        else
            cvpartition_to_use = cvpartition(length(training_label_vector),'KFold',decoding_scheme.kfold);
        end
    else
        if decoding_scheme.stratify
            cvpartition_to_use = cvpartition(training_label_vector,'KFold',10,'Stratify',true);
        else
            cvpartition_to_use = cvpartition(length(training_label_vector),'KFold',10);
        end
    end



    if decoding_scheme.b_hyperparameter_optimization && ~(number_of_classes>2)
        hyperparameter_optimization_options = struct();
        hyperparameter_optimization_options.CVPartition = cvpartition_to_use;
        if number_of_classes>2
            tic;[mdl,hyperparameter_optimization_results] = fitcecoc(training_feature_matrix_standardized,training_label_vector,'OptimizeHyperparameters','all','HyperParameterOptimizationOptions',hyperparameter_optimization_options);toc
            decoding_results.prediction_accuracy_training = 1 - hyperparameter_optimization_results.MinEstimatedObjective; % To implement: Split set into optimization set and crossvalidation set.

        else
            tic;[mdl,fit_info,hyperparameter_optimization_results] = fitclinear(training_feature_matrix_standardized,training_label_vector,'OptimizeHyperparameters','all','HyperParameterOptimizationOptions',hyperparameter_optimization_options);toc
            decoding_results.prediction_accuracy_training = 1 - hyperparameter_optimization_results.MinEstimatedObjective; % To implement: Split set into optimization set and crossvalidation set.
        end
        decoding_results.model = mdl;
    else
        if length(training_label_vector)>1
            if number_of_classes>2
                cv_mdl = fitcecoc(training_feature_matrix_standardized,training_label_vector,'CVPartition',cvpartition_to_use,'Coding',coding,'Learners',learners); %Leave-one-out takes too long for multi-class.
            else %to fix
                cv_mdl = fitclinear(training_feature_matrix_standardized,training_label_vector,'CVPartition',cvpartition_to_use,'Lambda',decoding_scheme.lambda); %Leave-one-out takes too long for multi-class.'LeaveOut','On'
            end
            decoding_results.prediction_accuracy_training = 1 - cv_mdl.kfoldLoss;
            [decoding_results.predicted_labels_training, decoding_results.scores_training] = cv_mdl.kfoldPredict;
            decoding_results.model = cv_mdl;

        else
            decoding_results.prediction_accuracy_training = nan;
            decoding_results.predicted_labels_training = nan; decoding_results.scores_training= nan;
        end
    end
    if iscell(training_label_vector)
            assert(all(strcmp(cv_mdl.ClassNames',unique(training_label_vector))));
    end
else
    %% Training on one dataset and testing on another
    if decoding_scheme.b_hyperparameter_optimization && ~(number_of_classes>2)
        hyperparameter_optimization_options = struct();
        hyperparameter_optimization_options.CVPartition = cvpartition(length(training_label_vector),'KFold',10);
        if number_of_classes>2
            tic;[mdl,fit_info,hyperparameter_optimization_results] = fitcecoc(training_feature_matrix_standardized,training_label_vector,'OptimizeHyperparameters','all','HyperParameterOptimizationOptions',hyperparameter_optimization_options);toc
            decoding_results.prediction_accuracy = 1 - hyperparameter_optimization_results.MinEstimatedObjective; % To implement: Split set into optimization set and crossvalidation set.

        else
            tic;[mdl,fit_info,hyperparameter_optimization_results] = fitclinear(training_feature_matrix_standardized,training_label_vector,'OptimizeHyperparameters','all','HyperParameterOptimizationOptions',hyperparameter_optimization_options);toc
            decoding_results.prediction_accuracy = 1 - hyperparameter_optimization_results.MinEstimatedObjective; % To implement: Split set into optimization set and crossvalidation set.
        end
    else
        if number_of_classes>2
            mdl = fitcecoc(training_feature_matrix_standardized,training_label_vector,'Coding',coding,'Learners',learners);
        else
            mdl = fitclinear(training_feature_matrix_standardized,training_label_vector,'Lambda',decoding_scheme.lambda);
        end
    end
    decoding_results.model = mdl;
    [decoding_results.predicted_labels_testing, decoding_results.scores_testing] = mdl.predict(testing_feature_matrix_standardized);
    if ~isempty(testing_label_vector)
        if iscell(testing_label_vector)
            decoding_results.prediction_accuracy_testing = mean(strcmp(decoding_results.predicted_labels_testing, testing_label_vector'));
            assert(all(strcmp(mdl.ClassNames',unique(training_label_vector))));
        else
            decoding_results.prediction_accuracy_testing = mean(decoding_results.predicted_labels_testing(:) == testing_label_vector(:));
            assert(all(~isnan(testing_label_vector)))
        end
    end
end