b_balance_high_repeats_for_all_analyses = true; %Throw away trials to balance same number of retreats per stimulus (used for e.g.. trial_is_priming_selected, does not apply to trial_is_priming for compute_axes
require_previous_trial_valid = true; %Require priming trial prior to binocular/transparent/unambiguous to be valid in order for the binocular/transparent/unambiguous to be valid.


stimulus_properties = parse_flash_suppression_stimuli(paradigm_data);
priming_stimuli = num2cell(nan(1,length(stimulus_properties.stimulus_contents)));
priming_stimuli = cell(1,length(stimulus_properties.stimulus_contents));
priming_stimuli(stimulus_properties.is_priming & contains(stimulus_properties.stimulus_contents,'red_only')) = stimulus_properties.image_red(stimulus_properties.is_priming & contains(stimulus_properties.stimulus_contents,'red_only'));
priming_stimuli(stimulus_properties.is_priming & contains(stimulus_properties.stimulus_contents,'cyan_only')) = stimulus_properties.image_cyan(stimulus_properties.is_priming & contains(stimulus_properties.stimulus_contents,'cyan_only'));
priming_stimuli_list = unique(priming_stimuli(~cellfun(@isempty,priming_stimuli)));
priming_stimuli_red_list = unique(stimulus_properties.image_red(stimulus_properties.is_priming & contains(stimulus_properties.stimulus_contents,'red_only')));
priming_stimuli_cyan_list = unique(stimulus_properties.image_cyan(stimulus_properties.is_priming & contains(stimulus_properties.stimulus_contents,'cyan_only')));
priming_stimuli_list_is_red = ismember(priming_stimuli_list,priming_stimuli_red_list);
priming_stimuli_list_is_cyan = ismember(priming_stimuli_list,priming_stimuli_cyan_list);
is_gray = strcmp(stimulus_properties.stimulus_contexts,'gray');
time_window_sizes = [-200 max(paradigm_data.on_durations)];
if isfield(paradigm_data,'raster_all_units') && paradigm_data.peri_stimulus_range(end)>=max(time_window_sizes)
    peri_stimulus_range = paradigm_data.peri_stimulus_range;
        b_in_range = true(size(paradigm_data.timecourse_on_times));
    raster = paradigm_data.raster_all_units(b_in_range,:,:);
else
    peri_stimulus_range = time_window_sizes(1):time_window_sizes(2);
    [raster, b_in_range] = computeRaster(paradigm_data.timecourse_on_times,paradigm_data.timecourse_all_units',-peri_stimulus_range(1), peri_stimulus_range(end));
end

%TODO: Use paradigm_data.b_previous_trial_valid


stimulus_index_in_range = paradigm_data.stimulus_index_valid(b_in_range);


trial_priming_stimuli = priming_stimuli(stimulus_index_in_range);
trial_is_priming = stimulus_properties.is_priming(stimulus_index_in_range);
trial_is_gray = is_gray(stimulus_index_in_range);
on_times_in_range = paradigm_data.timecourse_on_times(b_in_range);
on_durations_in_range = paradigm_data.on_durations(b_in_range);
assert(all(on_durations_in_range(trial_is_gray)<2000))

stimulus_is_binocular = contains(stimulus_properties.stimulus_contents,'binocular');
stimulus_is_unambiguous= stimulus_properties.is_unambiguous;
stimulus_is_transparent = contains(stimulus_properties.stimulus_contents,'transparent');



dominant_image = cell(size(stimulus_properties.stimulus_contexts)); %Note that this is reversed for priming
dominant_image(contains(stimulus_properties.stimulus_contexts,'red_suppressed')) =stimulus_properties.image_cyan(contains(stimulus_properties.stimulus_contexts,'red_suppressed'));
dominant_image(contains(stimulus_properties.stimulus_contexts,'cyan_suppressed')) =stimulus_properties.image_red(contains(stimulus_properties.stimulus_contexts,'cyan_suppressed'));

suppressed_image = cell(size(stimulus_properties.stimulus_contexts)); %Note that this is reversed for priming
suppressed_image(contains(stimulus_properties.stimulus_contexts,'red_suppressed')) =stimulus_properties.image_red(contains(stimulus_properties.stimulus_contexts,'red_suppressed'));
suppressed_image(contains(stimulus_properties.stimulus_contexts,'cyan_suppressed')) =stimulus_properties.image_cyan(contains(stimulus_properties.stimulus_contexts,'cyan_suppressed'));

trial_dominant_image = dominant_image(stimulus_index_in_range);
trial_suppressed_image = suppressed_image(stimulus_index_in_range);

trial_is_red_suppressed = strcmp(stimulus_properties.stimulus_contexts(stimulus_index_in_range),'_red_suppressed');
trial_is_cyan_suppressed = strcmp(stimulus_properties.stimulus_contexts(stimulus_index_in_range),'_cyan_suppressed');

trial_red_image = stimulus_properties.image_red(stimulus_index_in_range);
trial_cyan_image = stimulus_properties.image_cyan(stimulus_index_in_range);

b_keep_trials = true(size(paradigm_data.b_previous_trial_valid));
if any(contains(paradigm_data.comments,'Throw away last ')) %Exception when forgot goggles
    comment_indices = find(contains(paradigm_data.comments,'Throw away last '));
    for comment_index = comment_indices
        fileparts = strsplit(paradigm_data.comments{comment_index},'Throw away last ');
        comment = fileparts{end};
        fileparts = strsplit(comment,' blocks');
        num_blocks_to_throw = str2num(fileparts{1});
        trial_index = paradigm_data.comments_succeeding_trial_index{comment_index};
        valid_trial_indices_among_all_trials = find(paradigm_data.debug.ab_valid_trials);
        trial_index_among_all_trials = valid_trial_indices_among_all_trials(trial_index);
        num_valid_trials_to_throw = sum(paradigm_data.debug.ab_valid_trials((trial_index_among_all_trials- 3*num_blocks_to_throw):trial_index_among_all_trials));
        b_keep_trials((trial_index - num_valid_trials_to_throw):trial_index) = false;
    end
    disp(['Throwing away ' num2str(sum(~b_keep_trials)) ' trials.'])
end

if require_previous_trial_valid
    b_trial_is_valid = paradigm_data.b_previous_trial_valid(b_in_range) & circshift(trial_is_priming,1) & b_keep_trials(b_in_range);
    if contains(paradigm_data.paradigm_name,'flash_suppression_many_stimuli') && length(unique(stimulus_index_in_range(b_trial_is_valid & (stimulus_is_binocular(stimulus_index_in_range) | stimulus_is_transparent(stimulus_index_in_range) )))) < length(unique(stimulus_index_in_range((stimulus_is_binocular(stimulus_index_in_range) | stimulus_is_transparent(stimulus_index_in_range) ))))
        b_trial_is_valid = b_keep_trials(b_in_range);
        disp('Exception: Not excluding binocular trials because of previous trial as we would lose some unique stimuli that way.')
    else
        disp([num2str(100*(1-mean(b_trial_is_valid(stimulus_is_binocular(stimulus_index_in_range)))),3) '% of binocular trials were excluded because of previous trial.'])
        disp([num2str(100*(1-mean(b_trial_is_valid(stimulus_is_unambiguous(stimulus_index_in_range)))),3) '% of unambiguous trials were excluded because of previous trial.'])
        disp([num2str(100*(1-mean(b_trial_is_valid(stimulus_is_transparent(stimulus_index_in_range)))),3) '% of transparent trials were excluded because of previous trial.'])
    end
else
    b_trial_is_valid = b_keep_trials(b_in_range);
end

trial_is_binocular = stimulus_is_binocular(stimulus_index_in_range) & b_trial_is_valid; %Require that trial before is priming (should be the case but fixation may be missing)
trial_is_unambiguous= stimulus_is_unambiguous(stimulus_index_in_range)  & b_trial_is_valid ; %Require that trial before is priming (should be the case but fixation may be missing)
trial_is_transparent= stimulus_is_transparent(stimulus_index_in_range)  & b_trial_is_valid; %Require that trial before is priming (should be the case but fixation may be missing)

trial_is_baseline = trial_is_gray;

%Balance for stimuli that have been sbown more often
stimulus_indices_priming = find(stimulus_properties.is_priming);
trial_counts_priming = countmember(stimulus_indices_priming,stimulus_index_in_range);
sorted_trial_counts_priming = sort(trial_counts_priming);
%Check whether there are some stimuli that have been repeated a lot more often.
[max_break,max_break_index] =max(diff(sorted_trial_counts_priming));
high_repeats_lower_bound = sorted_trial_counts_priming(max_break_index+1);
low_repeats_upper_bound = sorted_trial_counts_priming(max(1,max_break_index-1));
if (high_repeats_lower_bound- low_repeats_upper_bound)>=1.4*median(sorted_trial_counts_priming) || contains(paradigm_data.xml_filename, 'FlashSuppression_many_faces_Liang_2500_many_pairs') || contains(paradigm_data.xml_filename, 'FlashSuppression_many_faces_Liang_2000_many_pairs')
    disp('Stimuli with higher number of repeats detected.')
    b_contains_high_repeat_stimuli = true;
    assert(all(strcmp(stimulus_properties.image_red(stimulus_properties.is_priming),stimulus_properties.image_red(stimulus_is_binocular))) && all(strcmp(stimulus_properties.image_red(stimulus_properties.is_priming),stimulus_properties.image_red(stimulus_is_transparent))) && all(strcmp(stimulus_properties.image_red(stimulus_properties.is_priming),stimulus_properties.image_red(stimulus_is_unambiguous))) ...
        && all(strcmp(stimulus_properties.image_cyan(stimulus_properties.is_priming),stimulus_properties.image_cyan(stimulus_is_binocular))) && all(strcmp(stimulus_properties.image_cyan(stimulus_properties.is_priming),stimulus_properties.image_cyan(stimulus_is_transparent))) && all(strcmp(stimulus_properties.image_cyan(stimulus_properties.is_priming),stimulus_properties.image_cyan(stimulus_is_unambiguous))) )
    high_repeats_median = median(sorted_trial_counts_priming(max_break_index+1:end));
    low_repeats_median = median(sorted_trial_counts_priming(1:max_break_index));
    low_to_high_repeats_ratio = low_repeats_median/high_repeats_median;
    if contains(paradigm_data.xml_filename, 'FlashSuppression_many_faces_Liang_2500_many_pairs') || contains(paradigm_data.xml_filename, 'FlashSuppression_many_faces_Liang_2000_many_pairs')
        stimulus_pair_is_high_repeats = (1:length(stimulus_indices_priming))<=60;
    else
        stimulus_pair_is_high_repeats = trial_counts_priming>=high_repeats_lower_bound;
    end
    trial_selected_for_balancing = true(size(stimulus_index_in_range));
    trial_is_part_of_high_repeat = false(size(stimulus_index_in_range));
    stimulus_indices_context = find(stimulus_properties.is_priming);
    for stimulus_index = stimulus_indices_context(stimulus_pair_is_high_repeats)
        trial_selected_for_balancing(pick_proportion(find(stimulus_index_in_range==stimulus_index),1-low_to_high_repeats_ratio))=false;
        trial_is_part_of_high_repeat(stimulus_index_in_range==stimulus_index)=true;
    end
    stimulus_indices_context = find(stimulus_is_binocular);
    for stimulus_index = stimulus_indices_context(stimulus_pair_is_high_repeats)
        trial_selected_for_balancing(pick_proportion(find(stimulus_index_in_range==stimulus_index),1-low_to_high_repeats_ratio))=false;
        trial_is_part_of_high_repeat(stimulus_index_in_range==stimulus_index)=true;
    end
    stimulus_indices_context = find(stimulus_is_transparent);
    for stimulus_index = stimulus_indices_context(stimulus_pair_is_high_repeats)
        trial_selected_for_balancing(pick_proportion(find(stimulus_index_in_range==stimulus_index),1-low_to_high_repeats_ratio))=false;
        trial_is_part_of_high_repeat(stimulus_index_in_range==stimulus_index)=true;
    end
    stimulus_indices_context = find(stimulus_is_unambiguous);
    for stimulus_index = stimulus_indices_context(stimulus_pair_is_high_repeats)
        trial_selected_for_balancing(pick_proportion(find(stimulus_index_in_range==stimulus_index),1-low_to_high_repeats_ratio))=false;
        trial_is_part_of_high_repeat(stimulus_index_in_range==stimulus_index)=true;
    end
    high_repeat_images_red = unique(stimulus_properties.image_red(stimulus_indices_priming(stimulus_pair_is_high_repeats)));
    high_repeat_images_cyan = unique(stimulus_properties.image_cyan(stimulus_indices_priming(stimulus_pair_is_high_repeats)));
else
    b_contains_high_repeat_stimuli = false;
    high_repeat_images_red = unique(stimulus_properties.image_red(stimulus_indices_priming));
    high_repeat_images_cyan = unique(stimulus_properties.image_cyan(stimulus_indices_priming));
    trial_is_part_of_high_repeat = false(size(stimulus_index_in_range));

end

if b_balance_high_repeats_for_all_analyses && b_contains_high_repeat_stimuli
    trial_selected = trial_selected_for_balancing;
else
    trial_selected = true(size(stimulus_index_in_range));
end
trial_is_priming_selected = trial_is_priming & trial_selected;
trial_is_unambiguous_selected=trial_is_unambiguous & trial_selected;
trial_is_binocular_selected=trial_is_binocular & trial_selected;
trial_is_transparent_selected=trial_is_transparent & trial_selected;

labels_list = priming_stimuli_list;
labels_list_red = priming_stimuli_red_list;
labels_list_cyan = priming_stimuli_cyan_list;
labels_list_red_to_all_indices = nan(size(labels_list_red));
for label_index = 1:length(labels_list_red)
    labels_list_red_to_all_indices(label_index) = find(strcmp(labels_list_red{label_index},labels_list));
end
labels_list_cyan_to_all_indices = nan(size(labels_list_cyan));
for label_index = 1:length(labels_list_cyan)
    labels_list_cyan_to_all_indices(label_index) = find(strcmp(labels_list_cyan{label_index},labels_list));
end
labels_list_is_red = ismember(labels_list,labels_list_red);
labels_list_is_cyan = ismember(labels_list,labels_list_cyan);
labels_list_all_to_red_indices = nan(size(labels_list));
labels_list_all_to_cyan_indices = nan(size(labels_list));
for label_index = 1:length(labels_list)
    if labels_list_is_red(label_index)
        labels_list_all_to_red_indices(label_index) = find(strcmp(labels_list{label_index},labels_list_red));
    end
    if labels_list_is_cyan(label_index)
        labels_list_all_to_cyan_indices(label_index) = find(strcmp(labels_list{label_index},labels_list_cyan));
    end
end

