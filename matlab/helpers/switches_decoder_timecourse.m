function [decoding_results,training_feature_matrix] = switches_decoder_timecourse(training_timecourse,training_on_times,training_labels_trials,testing_timecourse,testing_on_times,testing_labels_trials,decoding_scheme,b_timecourse_already_processed,labels_list)
if ~iscell(training_labels_trials) && ~iscategorical(training_labels_trials)
    classes = unique(training_labels_trials(~isnan(training_labels_trials)));
else
    classes = unique(training_labels_trials);
end

if ~isfield(decoding_scheme,'bin_distance_testing')
    decoding_scheme.bin_distance_testing=decoding_scheme.bin_distance;
end
if ~isfield(decoding_scheme,'number_of_bins_testing')
    decoding_scheme.number_of_bins_testing=decoding_scheme.number_of_bins;
end
%% Balance number of trials across classes
if decoding_scheme.b_balance_trials_across_classes
    number_of_trials_per_class_training = zeros(length(classes),1);
    for class_index = 1:length(classes)
        class = classes(class_index);
        number_of_trials_per_class_training(class_index) = sum(training_labels_trials(~isnan(training_labels_trials))==class);
    end

    minimum_number_of_trials_training = min(number_of_trials_per_class_training);
    b_use_for_training = false(length(training_labels_trials),1);
    b_use_for_testing = false(length(testing_labels_trials),1);
    for class_index= 1:length(classes)
        class = classes(class_index);
        class_indices = find(training_labels_trials == class);
        %randomly select subset of trials
        class_indices_subset = class_indices(randperm(length(class_indices),minimum_number_of_trials_training));
        b_use_for_training(class_indices_subset) = true;
    end
    if ~isempty(testing_labels_trials)
        number_of_trials_per_class_testing = zeros(length(classes),1);
        for class_index = 1:length(classes)
          class = classes(class_index);
          number_of_trials_per_class_testing(class_index) = sum(testing_labels_trials(~isnan(testing_labels_trials))==class);
       end

        minimum_number_of_trials_testing = min(number_of_trials_per_class_testing);
        b_use_for_testing = false(length(testing_labels_trials),1);
        for class_index= 1:length(classes)
            class = classes(class_index);
            class_indices = find(testing_labels_trials == class);
            %randomly select subset of trials
            class_indices_subset = class_indices(randperm(length(class_indices),minimum_number_of_trials_testing));
            b_use_for_testing(class_indices_subset) = true;
        end
    end
else
    b_use_for_training = true(length(training_labels_trials),1);
    b_use_for_testing = true(length(testing_labels_trials),1);
end

%% Select, smooth, standardize
if nargin<8 || ~b_timecourse_already_processed
    [training_timecourse_processed, testing_timecourse_processed] = switches_decoder_process_timecourses(training_timecourse,testing_timecourse,decoding_scheme); %Neurons are subselected here!
else
    training_timecourse_processed = training_timecourse;
    testing_timecourse_processed = testing_timecourse;
end
%% Pick time points for decoding
bin_points = round(0.5*decoding_scheme.bin_size + (0:decoding_scheme.bin_distance:(decoding_scheme.bin_distance*(decoding_scheme.number_of_bins-1))))';
matrix = training_on_times(b_use_for_training) + bin_points;
time_points = matrix(:);
assert(mean(time_points>size(training_timecourse_processed,1))<0.9)
training_feature_matrix_standardized = training_timecourse_processed(time_points(time_points<=size(training_timecourse_processed,1)),:);
matrix = find(b_use_for_training)' + zeros(size(bin_points));
trial_indices = matrix(:);
training_label_vector = training_labels_trials(trial_indices(time_points<=size(training_timecourse_processed,1)));
if isempty(testing_on_times)
    testing_label_vector = [];
    testing_feature_matrix_standardized = [];
    if decoding_scheme.b_use_trials_for_cvpartition
        %Training and testing on same dataset, so need to do cross-validation.
        %Since time bins may be overlapping, make a CV partition based on
        %trials.
        if ~isfield(decoding_scheme,'kfold')
            num_partitions = 10;
        else
            num_partitions = decoding_scheme.kfold;
        end
        if length(training_on_times(b_use_for_training))<num_partitions
            disp('Warning: Less repeats than number of partitions. Reducing number of partitions')
            num_partitions = length(training_on_times(b_use_for_training));
            assert(num_partitions>2);
        end
        %Utilizing matlab native cv partition to build ms-resolved partition from trial partition:
        cv_partition_trials_temp = cvpartition(training_labels_trials(b_use_for_training),'KFold',decoding_scheme.kfold,'Stratify',true);
        cv_partition_trials_b_use_for_training = nan(length(training_labels_trials(b_use_for_training)),1);
        for partition_index = 1:cv_partition_trials_temp.NumTestSets
            cv_partition_trials_b_use_for_training(cv_partition_trials_temp.test(partition_index)) = partition_index;
        end
        cv_partition_trials = nan(1,length(b_use_for_training));
        cv_partition_trials(b_use_for_training) = cv_partition_trials_b_use_for_training;
        decoding_scheme.cvpartition=cvpartition("CustomPartition",cv_partition_trials(trial_indices)); %Important.
    end
else
    bin_points = round(0.5*decoding_scheme.bin_size + (0:decoding_scheme.bin_distance_testing:(decoding_scheme.bin_distance_testing*(decoding_scheme.number_of_bins_testing-1))))';
    matrix = testing_on_times(b_use_for_testing) + bin_points;
    time_points = matrix(:);
    matrix = find(b_use_for_testing)' + zeros(size(bin_points));
    trial_indices = matrix(:);
    testing_label_vector = testing_labels_trials(trial_indices);
    testing_feature_matrix_standardized = testing_timecourse_processed(time_points,:);
end

decoding_results = switches_decoder_aux(training_feature_matrix_standardized,training_label_vector,testing_feature_matrix_standardized,testing_label_vector,decoding_scheme);
decoding_results.b_use_for_training = b_use_for_training;
decoding_results.b_use_for_testing = b_use_for_testing;
if isempty(testing_on_times)
    decoding_results.cv_partition_test_trials = cv_partition_trials;
end

if nargin>=9 && ~isequal(labels_list,classes) && length(labels_list)>2 %Fill in missing classes
    decoding_results_original_classes = decoding_results;
    if isempty(testing_on_times) %Cross-validation
        decoding_results_original_classes.scores_training = nan(size(decoding_results.scores_training,1),length(labels_list));
        decoding_results_original_classes.model = struct();%Overwrite and make a fake model
        for partition_index = 1:length(decoding_results.model.Trained)
            decoding_results_original_classes.model.Trained{partition_index}.BinaryLearners = cell(length(labels_list),1);%Overwrite and make a fake model
            for class_index = labels_list
                class_index_current = find(classes==class_index);
                if ~isempty(class_index_current)
                    decoding_results_original_classes.model.Trained{partition_index}.BinaryLearners{class_index} = decoding_results.model.Trained{partition_index}.BinaryLearners{class_index_current};
                    decoding_results_original_classes.scores_training = decoding_results.scores_training(:,class_index_current);
                else
                    decoding_results_original_classes.model.Trained{partition_index}.BinaryLearners{class_index}.Bias = nan(size(decoding_results.model.Trained{partition_index}.BinaryLearners{1}.Bias));
                    decoding_results_original_classes.model.Trained{partition_index}.BinaryLearners{class_index}.Beta = nan(size(decoding_results.model.Trained{partition_index}.BinaryLearners{1}.Beta));
                end
            end
        end
    else
        decoding_results_original_classes.scores_testing = nan(size(decoding_results.scores_testing,1),length(labels_list));
        decoding_results_original_classes.model = struct();%Overwrite and make a fake model
        decoding_results_original_classes.model.BinaryLearners = cell(length(labels_list),1);%Overwrite and make a fake model
        for class_index = labels_list
            class_index_current = find(classes==class_index);
            if ~isempty(class_index_current)
                decoding_results_original_classes.model.BinaryLearners{class_index} = decoding_results.model.BinaryLearners{class_index_current};
                decoding_results_original_classes.scores_testing = decoding_results.scores_testing(:,class_index_current);
            else
                decoding_results_original_classes.model.BinaryLearners{class_index}.Bias = nan(size(decoding_results.model.BinaryLearners{1}.Bias));
                decoding_results_original_classes.model.BinaryLearners{class_index}.Beta = nan(size(decoding_results.model.BinaryLearners{1}.Beta));
            end
        end
    end
    decoding_results = decoding_results_original_classes;
end