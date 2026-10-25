flash_suppression_results.(trial_context_name).responses_red_dominant = [];
flash_suppression_results.(trial_context_name).responses_cyan_dominant = [];
MI = @(x,y) (x-y)./(x+y);

flash_suppression_results.images_red_for_modulation = high_repeat_images_red;
flash_suppression_results.images_cyan_for_modulation = high_repeat_images_cyan;

flash_suppression_results.(trial_context_name).responses_red_dominant=nan(size(raster,3),length(flash_suppression_results.images_red_for_modulation),length(flash_suppression_results.images_cyan_for_modulation));
flash_suppression_results.(trial_context_name).responses_red_dominant_state=nan(size(raster,3),length(flash_suppression_results.images_red_for_modulation),length(flash_suppression_results.images_cyan_for_modulation));
flash_suppression_results.(trial_context_name).responses_cyan_dominant=nan(size(raster,3),length(flash_suppression_results.images_red_for_modulation),length(flash_suppression_results.images_cyan_for_modulation));
flash_suppression_results.(trial_context_name).responses_cyan_dominant_state=nan(size(raster,3),length(flash_suppression_results.images_red_for_modulation),length(flash_suppression_results.images_cyan_for_modulation));
flash_suppression_results.(trial_context_name).responses_red_dominant_first_half=nan(size(raster,3),length(flash_suppression_results.images_red_for_modulation),length(flash_suppression_results.images_cyan_for_modulation));
flash_suppression_results.(trial_context_name).responses_cyan_dominant_first_half=nan(size(raster,3),length(flash_suppression_results.images_red_for_modulation),length(flash_suppression_results.images_cyan_for_modulation));
flash_suppression_results.(trial_context_name).responses_red_dominant_second_half=nan(size(raster,3),length(flash_suppression_results.images_red_for_modulation),length(flash_suppression_results.images_cyan_for_modulation));
flash_suppression_results.(trial_context_name).responses_cyan_dominant_second_half=nan(size(raster,3),length(flash_suppression_results.images_red_for_modulation),length(flash_suppression_results.images_cyan_for_modulation));

for R1 = 1:length(flash_suppression_results.images_red_for_modulation)
    R1_label = flash_suppression_results.images_red_for_modulation{R1};
    for C1 = 1:length(flash_suppression_results.images_cyan_for_modulation)
        C1_label = flash_suppression_results.images_cyan_for_modulation{C1};
        % Get single neuron responses
        start_index = find(trial_time_window(1) == peri_stimulus_range);
        end_index = find(trial_time_window(end) == peri_stimulus_range);

        %Context trials (stimulus_is_context)
        if strcmp(trial_context_name,'priming') %Invert which one is dominant
            stimulus_index_R1_C1_cyan_suppressed = find(strcmp(stimulus_properties.image_red,R1_label) & strcmp(stimulus_properties.image_cyan,C1_label) & stimulus_is_context & strcmp(stimulus_properties.stimulus_contexts,'_red_suppressed'));
            stimulus_index_R1_C1_red_suppressed = find(strcmp(stimulus_properties.image_red,R1_label) & strcmp(stimulus_properties.image_cyan,C1_label) & stimulus_is_context & strcmp(stimulus_properties.stimulus_contexts,'_cyan_suppressed'));
        else
            stimulus_index_R1_C1_red_suppressed = find(strcmp(stimulus_properties.image_red,R1_label) & strcmp(stimulus_properties.image_cyan,C1_label) & stimulus_is_context & strcmp(stimulus_properties.stimulus_contexts,'_red_suppressed'));
            stimulus_index_R1_C1_cyan_suppressed = find(strcmp(stimulus_properties.image_red,R1_label) & strcmp(stimulus_properties.image_cyan,C1_label) & stimulus_is_context & strcmp(stimulus_properties.stimulus_contexts,'_cyan_suppressed'));
        end
        if ~isempty(stimulus_index_R1_C1_red_suppressed)
            trial_labels_R1_C1 = (stimulus_index_in_range == stimulus_index_R1_C1_cyan_suppressed)*2 + (stimulus_index_in_range == stimulus_index_R1_C1_red_suppressed)*1;
            trial_is_R1_C1 = trial_labels_R1_C1>0;
            trial_labels_R1_C1(~trial_is_R1_C1) = nan;

            flash_suppression_results.(trial_context_name).responses_red_dominant(:,R1,C1) = mean(mean(raster(stimulus_index_in_range == stimulus_index_R1_C1_cyan_suppressed,start_index:end_index,:),2),1);
            flash_suppression_results.(trial_context_name).responses_cyan_dominant(:,R1,C1) = mean(mean(raster(stimulus_index_in_range == stimulus_index_R1_C1_red_suppressed,start_index:end_index,:),2),1);
            indices_cyan_suppressed = find(stimulus_index_in_range == stimulus_index_R1_C1_cyan_suppressed);
            indices_red_suppressed = find(stimulus_index_in_range == stimulus_index_R1_C1_red_suppressed);
            b_indices_cyan_suppressed_first_half = rand(size(indices_cyan_suppressed))>0.5;
            b_indices_red_suppressed_first_half = rand(size(indices_red_suppressed))>0.5;
            indices_cyan_suppressed_first_half = indices_cyan_suppressed(b_indices_cyan_suppressed_first_half);
            indices_cyan_suppressed_second_half = indices_cyan_suppressed(~b_indices_cyan_suppressed_first_half);
            indices_red_suppressed_first_half = indices_red_suppressed(b_indices_red_suppressed_first_half);
            indices_red_suppressed_second_half = indices_red_suppressed(~b_indices_red_suppressed_first_half);
            flash_suppression_results.(trial_context_name).responses_red_dominant_first_half(:,R1,C1) = mean(mean(raster(indices_cyan_suppressed_first_half,start_index:end_index,:),2),1);
            flash_suppression_results.(trial_context_name).responses_cyan_dominant_first_half(:,R1,C1) = mean(mean(raster(indices_red_suppressed_first_half,start_index:end_index,:),2),1);
            flash_suppression_results.(trial_context_name).responses_red_dominant_second_half(:,R1,C1) = mean(mean(raster(indices_cyan_suppressed_second_half,start_index:end_index,:),2),1);
            flash_suppression_results.(trial_context_name).responses_cyan_dominant_second_half(:,R1,C1) = mean(mean(raster(indices_red_suppressed_second_half,start_index:end_index,:),2),1);

            for cell_index = 1:size(raster,3)
                [h,p] = ttest2(mean(raster(stimulus_index_in_range == stimulus_index_R1_C1_cyan_suppressed,start_index:end_index,cell_index),2),mean(raster(stimulus_index_in_range == stimulus_index_R1_C1_red_suppressed,start_index:end_index,cell_index),2));
                flash_suppression_results.(trial_context_name).responses_p_value(cell_index,R1,C1) = p;
            end

            if exist('raster_state','var')
                flash_suppression_results.(trial_context_name).responses_red_dominant_state(:,R1,C1) = nanmean_function(raster_state(stimulus_index_in_range == stimulus_index_R1_C1_cyan_suppressed,start_index:end_index,:));
                flash_suppression_results.(trial_context_name).responses_cyan_dominant_state(:,R1,C1) = nanmean_function(raster_state(stimulus_index_in_range == stimulus_index_R1_C1_red_suppressed,start_index:end_index,:));
                flash_suppression_results.(trial_context_name).proportion_red_dominant_state(R1,C1) = mean(reshape(~isnan(raster_state(stimulus_index_in_range == stimulus_index_R1_C1_cyan_suppressed,start_index:end_index,:)),[],1));
                flash_suppression_results.(trial_context_name).proportion_cyan_dominant_state(R1,C1) = mean(reshape(~isnan(raster_state(stimulus_index_in_range == stimulus_index_R1_C1_red_suppressed,start_index:end_index,:)),[],1));
            end
            
        end
    end
end
flash_suppression_results.(trial_context_name).modulation_indices = MI(flash_suppression_results.(trial_context_name).responses_red_dominant, flash_suppression_results.(trial_context_name).responses_cyan_dominant);
if isfield(flash_suppression_results.(trial_context_name),'responses_red_dominant_state')
    flash_suppression_results.(trial_context_name).modulation_indices_state = MI(flash_suppression_results.(trial_context_name).responses_red_dominant_state, flash_suppression_results.(trial_context_name).responses_cyan_dominant_state);
end

flash_suppression_results.(trial_context_name).modulation_indices_first_half = MI(flash_suppression_results.(trial_context_name).responses_red_dominant_first_half, flash_suppression_results.(trial_context_name).responses_cyan_dominant_first_half);
flash_suppression_results.(trial_context_name).modulation_indices_second_half = MI(flash_suppression_results.(trial_context_name).responses_red_dominant_second_half, flash_suppression_results.(trial_context_name).responses_cyan_dominant_second_half);

flash_suppression_results.unit_probes_index = session.unit_probes_index;
flash_suppression_results.probe_indices_to_analyze = 0:session.number_of_probes;


%% Compute for all stimuli as well, not only high repeat

flash_suppression_results.images_red = labels_list_red;
flash_suppression_results.images_cyan = labels_list_cyan;

if ~contains(paradigm_data.paradigm_name,'flash_suppression_many_stimuli')
    flash_suppression_results.(trial_context_name).responses_red_dominant_all=nan(size(raster,3),length(labels_list_red),length(labels_list_cyan));
    flash_suppression_results.(trial_context_name).responses_red_dominant_state_all=nan(size(raster,3),length(labels_list_red),length(labels_list_cyan));
    flash_suppression_results.(trial_context_name).responses_cyan_dominant_all=nan(size(raster,3),length(labels_list_red),length(labels_list_cyan));
    flash_suppression_results.(trial_context_name).responses_cyan_dominant_state_all=nan(size(raster,3),length(labels_list_red),length(labels_list_cyan));

    for R1 = 1:length(labels_list_red)
        R1_label = labels_list_red{R1};
        for C1 = 1:length(labels_list_cyan)
            C1_label = labels_list_cyan{C1};

            %Context trials (stimulus_is_context)
            if strcmp(trial_context_name,'priming') %Invert which one is dominant
                stimulus_index_R1_C1_cyan_suppressed = find(strcmp(stimulus_properties.image_red,R1_label) & strcmp(stimulus_properties.image_cyan,C1_label) & stimulus_is_context & strcmp(stimulus_properties.stimulus_contexts,'_red_suppressed'));
                stimulus_index_R1_C1_red_suppressed = find(strcmp(stimulus_properties.image_red,R1_label) & strcmp(stimulus_properties.image_cyan,C1_label) & stimulus_is_context & strcmp(stimulus_properties.stimulus_contexts,'_cyan_suppressed'));
            else
                stimulus_index_R1_C1_red_suppressed = find(strcmp(stimulus_properties.image_red,R1_label) & strcmp(stimulus_properties.image_cyan,C1_label) & stimulus_is_context & strcmp(stimulus_properties.stimulus_contexts,'_red_suppressed'));
                stimulus_index_R1_C1_cyan_suppressed = find(strcmp(stimulus_properties.image_red,R1_label) & strcmp(stimulus_properties.image_cyan,C1_label) & stimulus_is_context & strcmp(stimulus_properties.stimulus_contexts,'_cyan_suppressed'));
            end
            if ~isempty(stimulus_index_R1_C1_red_suppressed)
                trial_labels_R1_C1 = (stimulus_index_in_range == stimulus_index_R1_C1_cyan_suppressed)*2 + (stimulus_index_in_range == stimulus_index_R1_C1_red_suppressed)*1;
                trial_is_R1_C1 = trial_labels_R1_C1>0;
                trial_labels_R1_C1(~trial_is_R1_C1) = nan;

                % Get single neuron responses
                start_index = find(trial_time_window(1) == peri_stimulus_range);
                end_index = find(trial_time_window(end) == peri_stimulus_range);
                flash_suppression_results.(trial_context_name).responses_red_dominant_all(:,R1,C1) = mean(mean(raster(stimulus_index_in_range == stimulus_index_R1_C1_cyan_suppressed,start_index:end_index,:),2),1);
                flash_suppression_results.(trial_context_name).responses_cyan_dominant_all(:,R1,C1) = mean(mean(raster(stimulus_index_in_range == stimulus_index_R1_C1_red_suppressed,start_index:end_index,:),2),1);

                for cell_index = 1:size(raster,3)
                    [h,p] = ttest2(mean(raster(stimulus_index_in_range == stimulus_index_R1_C1_cyan_suppressed,start_index:end_index,cell_index),2),mean(raster(stimulus_index_in_range == stimulus_index_R1_C1_red_suppressed,start_index:end_index,cell_index),2));
                    flash_suppression_results.(trial_context_name).responses_p_value_all(cell_index,R1,C1) = p;
                end

                if exist('raster_state','var')
                    flash_suppression_results.(trial_context_name).responses_red_dominant_state_all(:,R1,C1) = nanmean_function(raster_state(stimulus_index_in_range == stimulus_index_R1_C1_cyan_suppressed,start_index:end_index,:));
                    flash_suppression_results.(trial_context_name).responses_cyan_dominant_state_all(:,R1,C1) = nanmean_function(raster_state(stimulus_index_in_range == stimulus_index_R1_C1_red_suppressed,start_index:end_index,:));
                    flash_suppression_results.(trial_context_name).proportion_red_dominant_state_all(R1,C1) = mean(reshape(~isnan(raster_state(stimulus_index_in_range == stimulus_index_R1_C1_cyan_suppressed,start_index:end_index,:)),[],1));
                    flash_suppression_results.(trial_context_name).proportion_cyan_dominant_state_all(R1,C1) = mean(reshape(~isnan(raster_state(stimulus_index_in_range == stimulus_index_R1_C1_red_suppressed,start_index:end_index,:)),[],1));
                end

            end
        end
    end
end