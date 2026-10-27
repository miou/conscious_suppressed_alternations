function [config,folder_name,peri_stimulus_range,unique_stimuli,unique_stimulus_index_other_list,unique_stimuli_is_high_repeat,unique_stimuli_is_red,unique_stimuli_is_cyan,red_cyan_pair_indices,number_of_features,xml_folder,xml_filename,feat_map,feat_map_stim_condition_stimulus,feat_map_stim_names,stimulus_index_in_range,priming_stimuli,dominant_image,suppressed_image,b_trial_in_range_is_proportion_priming,trial_is_binocular_context,b_trial_in_range_is_proportion,number_of_stimuli_total_list,number_of_stimuli_for_decoding_list]...
    =flash_suppression_axes_get_stimuli(...
    config,session,paradigm_data,flash_suppression_results);

flash_suppression_get_variables;
if isfield(config,'cell_selection_scheme') && ~strcmp(config.cell_selection_scheme,'all')
    config.b_plot_single_cells=false;
end

config.folder_name_single_cells = [session.analysis_path filesep 'single_cell_plots'];

if config.b_concatenate_features_other
    concatenate_string = '_concatenate_features';
else
    concatenate_string = '';
end
if ~isempty(config.proportion_of_trials) && config.proportion_of_trials <1

    proportion_string = [filesep 'proportion_trials_' num2str(config.proportion_of_trials)];
else
    proportion_string = '';
end
if config.analyze_transparent
    transparent_string = '_transparent';
    trial_is_binocular_context = trial_is_transparent;
else
    transparent_string = '';
    trial_is_binocular_context = trial_is_binocular;
end

if isfield(config,'states_to_use') && ~isempty(config.states_to_use)
    states_string =[filesep 'states_' config.states_to_use.inference_scheme '_' num2str(config.states_to_use.state_value) '_' num2str(config.states_to_use.only_apply_to_testing) '_avgdim_' num2str(config.avg_first_dimension) filesep];
else
    states_string ='';
end


if  config.probe_index
    probe_string = [filesep 'probe_' num2str(config.probe_index) filesep];
else
    probe_string = '';
end

if config.balance_states_each_trial
    balance_string = '_balance_control';
else
    balance_string = '';
end

if config.minimum_state_proportion_per_trial
    min_proportion_string = ['_min_' num2str(config.minimum_state_proportion_per_trial)];
else
    min_proportion_string = '';
end
folder_name = '';  % diagnostic-plot folder disabled for the release (original wrote under the read-only raw-data path)

xml_filename = paradigm_data.xml_filename;

% Resolve the stimulus feature map. The maps are small and shipped under data/stimuli; pick the
% one for this stimulus set by name. This replaces the original lookup on the acquisition share
% and the on-the-fly feature-map generation (removed for the release); no stimulus images are read.
p_rel = set_paths;
if contains(xml_filename,'FlashSuppression_many_faces_Liang_2000_many_pairs')
    stimulus_set_dir = fullfile(p_rel.stimuli,'liang_2000_many_pairs');
else
    stimulus_set_dir = fullfile(p_rel.stimuli,'liang_2500_many_pairs');
end
xml_folder = stimulus_set_dir;   % string only; the release reads features from the map, never the stimulus images
if config.analyze_transparent
    feat_map_file = fullfile(stimulus_set_dir,'feat_map_priming_reconstructed_0.00_gray.mat');
else
    feat_map_file = fullfile(stimulus_set_dir,'feat_map_priming_reconstructed_0.00.mat');
end





%% Define stimuli
    number_of_stimuli_total_list = inf;
    number_of_stimuli_for_decoding_list = 1:60;
    config.b_shuffle_stimuli = false;
    config.only_test_for_decoding = true;




if ~exist(feat_map_file,'file')
    disp(['Feature map not found at ' feat_map_file])
    feat_map = [];
    feat_map_stim_condition_stimulus = [];
    feat_map_stim_names = [];
    number_of_features = 0;
else
    fm = load(feat_map_file);
    stimulus_list_to_match = paradigm_data.condition_stimulus_list;
    if isfield(fm,'feat_map_SA')
        feat_map = fm.feat_map_SA;
    elseif isfield(fm,'feat_map')
        feat_map = fm.feat_map;
    elseif isfield(fm,'b0')
        assert(isequal(paradigm_data.stimulus_list', fm.stimulus_names))
        feat_map = containers.Map(fm.stimulus_names,num2cell(fm.b0,2));
        stimulus_list_to_match = paradigm_data.stimulus_list;
    else
        disp('Could not find feat map in file.')
    end
    if contains(paradigm_data.paradigm_name,'flash_suppression')
        stimulus_list_to_match = priming_stimuli;
    end

    feat_map_stim_names = keys(feat_map);
    feat_map_stim_condition_stimulus = strrep(feat_map_stim_names,'\','_');
    number_of_features = length(feat_map(feat_map_stim_names{1}));
end

%% Pick trial proportion
b_trial_is_proportion = true(size(paradigm_data.stimulus_index_valid));
if ~isempty(config.proportion_of_trials) & config.proportion_of_trials~=1
    b_trial_is_proportion(round(length(b_trial_is_proportion)*config.proportion_of_trials):end) = false;
end
b_trial_in_range_is_proportion = b_trial_is_proportion(b_in_range);
b_trial_is_proportion_priming = b_trial_is_proportion & stimulus_properties.is_priming(paradigm_data.stimulus_index_valid);
b_trial_in_range_is_proportion_priming = b_trial_is_proportion_priming(b_in_range);


%% Find which unique stimuli exist
number_of_stimuli_total = inf;
unique_stimuli = priming_stimuli_list;
if strcmp(config.use_for_training,'priming')
    number_occurrences = countmember(unique_stimuli,priming_stimuli(stimulus_index_in_range(b_trial_in_range_is_proportion_priming)));
elseif strcmp(config.use_for_training,'dominant_binocular')
    number_occurrences = countmember(unique_stimuli,dominant_image(stimulus_index_in_range(trial_is_binocular_context & b_trial_in_range_is_proportion)));
elseif strcmp(config.use_for_training,'suppressed_binocular')
    number_occurrences = countmember(unique_stimuli,suppressed_image(stimulus_index_in_range(trial_is_binocular_context & b_trial_in_range_is_proportion)));
end
unique_stimuli = unique_stimuli(number_occurrences>=config.min_number_occurences); %Less requirements for flash suppression
%Only include stimuli included in the feature map
unique_stimuli = unique_stimuli(ismember(unique_stimuli,feat_map_stim_condition_stimulus));
% Feature values are nan for the below.
unique_stimuli = unique_stimuli(~ismember(unique_stimuli,{'monkey_face_test_syn_120d_mean.tif','monkey_face_test_syn_120d_training_mark-1_texture0.tif','monkey_face_test_syn_120d_training_mark0_texture-1.tif','monkey_face_test_syn_120d_training_mark0_texture1.tif','monkey_face_test_syn_120d_training_mark1_texture0.tif'}));

if config.stimuli_to_include
    if strcmp(config.stimuli_to_include,'red')
        disp('Only including red stimuli')
        unique_stimuli = unique_stimuli(ismember(unique_stimuli,stimulus_properties.image_red));
    elseif strcmp(config.stimuli_to_include,'cyan')
        disp('Only including cyan stimuli')
        unique_stimuli = unique_stimuli(ismember(unique_stimuli,stimulus_properties.image_cyan));
    elseif strcmp(config.stimuli_to_include,'random_half')
        unique_stimuli = unique_stimuli(sort(randperm(length(unique_stimuli),round(length(unique_stimuli)*0.75))));
    end
end

disp(['Number of stimuli presented: ' num2str(length(unique_stimuli))])
if length(unique_stimuli)<number_of_stimuli_total
    number_of_stimuli_total = length(unique_stimuli);
end
disp(['Number of stimuli used for analysis: ' num2str(number_of_stimuli_total)])
if config.b_use_same_random_stimuli_across_iterations
    rng(config.b_use_same_random_stimuli_across_iterations)
end
if ~config.b_shuffle_stimuli
    unique_stimuli = unique_stimuli(1:number_of_stimuli_total);
else
    unique_stimuli = unique_stimuli(randperm(length(unique_stimuli),number_of_stimuli_total));
end

if config.use_half_stimuli==1
    unique_stimuli = unique_stimuli(1:round(length(unique_stimuli)/2));
elseif config.use_half_stimuli==2
    unique_stimuli = unique_stimuli((round(length(unique_stimuli)/2)+1):end);
end

%Find other stimulus in pair
images_red_binocular = stimulus_properties.image_red(stimulus_is_binocular);
images_cyan_binocular = stimulus_properties.image_cyan(stimulus_is_binocular);
unique_stimulus_index_other_list = nan(size(unique_stimuli));
red_cyan_pair_indices = [];
for unique_stimulus_index_to_check = 1:length(unique_stimuli)%1:length(unique_stimuli);
    unique_stimulus = unique_stimuli{unique_stimulus_index_to_check};
    if ismember(unique_stimulus,images_red_binocular)
        stimulus_indices_binocular = find(strcmp(unique_stimulus,images_red_binocular));
        assert(length(stimulus_indices_binocular)<=2)
        unique_stimulus_other = images_cyan_binocular{stimulus_indices_binocular(1)};
        unique_stimulus_index_other = find(strcmp(unique_stimulus_other,unique_stimuli));
        if ~isempty(unique_stimulus_index_other)
            red_cyan_pair_indices = [red_cyan_pair_indices;unique_stimulus_index_to_check,unique_stimulus_index_other];
        end
    elseif ismember(unique_stimulus,images_cyan_binocular)
        stimulus_indices_binocular = find(strcmp(unique_stimulus,images_cyan_binocular));
        assert(length(stimulus_indices_binocular)<=2)
        unique_stimulus_other = images_red_binocular{stimulus_indices_binocular(1)};
        unique_stimulus_index_other = find(strcmp(unique_stimulus_other,unique_stimuli));
    else
        error('Image not found in binocular')
    end
    if unique_stimulus_index_other
        unique_stimulus_index_other_list(unique_stimulus_index_to_check) = unique_stimulus_index_other;
    end

end

unique_stimuli_is_high_repeat = ismember(unique_stimuli,[high_repeat_images_red high_repeat_images_cyan]);
unique_stimuli_is_red = ismember(unique_stimuli,stimulus_properties.image_red);
unique_stimuli_is_cyan = ismember(unique_stimuli,stimulus_properties.image_cyan);

