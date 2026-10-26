function [ims_reconstructed] = flash_suppression_axes_compute_reconstructions(config,xml_folder,xml_filename,stimulus_list,priming_stimuli,folder_name,features,predicted_features_cv,unique_stimuli,unique_stimulus_index_other_list,unique_stimuli_is_high_repeat,red_cyan_pair_indices)
b_make_images_gray = true;
if isfield(config,'states_to_use') && ~isempty(config.states_to_use) && config.states_to_use.state_value == 1
    skip_image = 4;%default 3 for state 2, 4 for state 1.
elseif isfield(config,'states_to_use') && ~isempty(config.states_to_use) && config.states_to_use.state_value == 2
    skip_image =3;%default 3 for state 2, 4 for state 1.
else
    skip_image = [];
end

distance_method = 'dotproduct';
distance_features = [1:40];
if contains(xml_filename, 'FlashSuppression_many_faces_Liang_2500_many_pairs') || contains(xml_filename, 'FlashSuppression_many_faces_Liang_2000_many_pairs')
    p_rel = set_paths; addpath(genpath(p_rel.stimulus_model));
    model_data = fullfile(p_rel.stimulus_model,'Monkey_Face_Model_Data.mat');output_res = [300 300];
    model = AAM_Model(model_data);
    warning off
    if config.b_concatenate_features_other
        [ims_recomputed,landmarks] = model.gen_image_param(features(:,1:size(features,2)/2), output_res);
        [ims_reconstructed,landmarks_reconstructions] = model.gen_image_param(predicted_features_cv(:,1:size(features,2)/2), output_res);
        [ims_reconstructed_other,landmarks_reconstructions_other] = model.gen_image_param(predicted_features_cv(:,(1+size(features,2)/2):end), output_res);
    else
        if config.b_use_control_1_stimuli && isfield(config,'stim_index_abcd') %Need to recompute all stimuli because random stimuli can come from anywhere for control
            [ims_recomputed,landmarks] = model.gen_image_param(features, output_res);
            [ims_reconstructed,landmarks_reconstructions] = model.gen_image_param(predicted_features_cv, output_res);
        else
            %For time-saving, only reconstruct unique_stimuli_is_high_repeat
            [ims_recomputed(:,:,:,unique_stimuli_is_high_repeat),landmarks(:,:,unique_stimuli_is_high_repeat)] = model.gen_image_param(features(unique_stimuli_is_high_repeat,:), output_res);
            [ims_reconstructed(:,:,:,unique_stimuli_is_high_repeat),landmarks_reconstructions(:,:,unique_stimuli_is_high_repeat)] = model.gen_image_param(predicted_features_cv(unique_stimuli_is_high_repeat,:), output_res);
        end
    end
    warning on;
elseif contains(xml_filename, 'FlashSuppression_many_faces_Steven_2000_many_pairs')
    p_rel = set_paths; addpath(genpath(p_rel.stimulus_model));
    ims_recomputed = face_generator_50d(features,0);
    if config.b_concatenate_features_other
        ims_reconstructed = face_generator_50d(predicted_features_cv(:,1:size(features,2)/2),0);
        ims_reconstructed_other = face_generator_50d(predicted_features_cv(:,(1+size(features,2)/2):end),0);
    else
        ims_reconstructed = face_generator_50d(predicted_features_cv,0);
        ims_reconstructed_other = [];
    end
end

features_mean = mean(features,1);features_std = std(features,[],1);


figure(42);clf;tiledlayout(10,18)
if skip_image
    figure(43);clf;tiledlayout(10,24)
else
    figure(43);clf;tiledlayout(10,18)
end
correct_pair = nan(length(unique_stimuli_is_high_repeat),1);

for unique_stimulus_index_to_check = find(unique_stimuli_is_high_repeat)%1:length(unique_stimuli);
    unique_stimulus = unique_stimuli{unique_stimulus_index_to_check};
    stimulus_index = find(strcmp(priming_stimuli,unique_stimulus));
    stimulus_file_name = stimulus_list{stimulus_index};
    stimulus_image = imread([xml_folder filesep stimulus_file_name]);

    unique_stimulus_index_other = unique_stimulus_index_other_list(unique_stimulus_index_to_check);

    if config.b_use_control_1_stimuli && ~isnan(unique_stimulus_index_other) && isfield(config,'stim_index_abcd')
        row_index = find(config.stim_index_abcd(:,1) == unique_stimulus_index_to_check & config.stim_index_abcd(:,2) == unique_stimulus_index_other);

        if ~isempty(row_index)
            unique_stimulus_index_to_check_for_recomputed = config.stim_index_abcd(row_index,3);
            unique_stimulus_index_other_for_recomputed = config.stim_index_abcd(row_index,4);
        else
            row_index = find(config.stim_index_abcd(:,2) == unique_stimulus_index_to_check & config.stim_index_abcd(:,1) == unique_stimulus_index_other);
            unique_stimulus_index_to_check_for_recomputed = config.stim_index_abcd(row_index,4);
            unique_stimulus_index_other_for_recomputed = config.stim_index_abcd(row_index,3);
        end
        
    else
        unique_stimulus_index_to_check_for_recomputed = unique_stimulus_index_to_check;
        unique_stimulus_index_other_for_recomputed = unique_stimulus_index_other;
    end

    if contains(xml_filename, 'FlashSuppression_many_faces_Liang_2500_many_pairs') || contains(xml_filename, 'FlashSuppression_many_faces_Liang_2000_many_pairs')
        recomputed_image = ims_recomputed(:,:,:,unique_stimulus_index_to_check_for_recomputed);
        reconstructed_image = ims_reconstructed(:,:,:,unique_stimulus_index_to_check);
        if ~isnan(unique_stimulus_index_other)
            recomputed_image_other = ims_recomputed(:,:,:,unique_stimulus_index_other_for_recomputed);
            reconstructed_image_other = ims_reconstructed(:,:,:,unique_stimulus_index_other);
        end
        if config.b_concatenate_features_other
            reconstructed_image_other = ims_reconstructed_other(:,:,:,unique_stimulus_index_to_check);
        end
    else
        recomputed_image = uint8(255*(ims_recomputed{unique_stimulus_index_to_check_for_recomputed}));
        reconstructed_image = uint8(255*(ims_reconstructed{unique_stimulus_index_to_check}));
        if ~isnan(unique_stimulus_index_other)
            recomputed_image_other = uint8(255*(ims_recomputed{unique_stimulus_index_other_for_recomputed}));
            reconstructed_image_other = uint8(255*(ims_reconstructed{unique_stimulus_index_other}));
        end
        if config.b_concatenate_features_other
            reconstructed_image_other = uint8(255*(ims_reconstructed_other{unique_stimulus_index_to_check}));
        end
    end
    figure(42)
    nexttile
    imshow(uint8(stimulus_image))
    title('Presented')
    nexttile
    imshow(uint8(recomputed_image))
    title('Recomputed')
    nexttile
    imshow(uint8(reconstructed_image))
    title('Reconstructed')
    figure(43)

    %Compare whether reconstruction is closer to recomputed_image or
    %recomputed_image_other
    if b_make_images_gray
        recomputed_image_gray=repmat(max(recomputed_image,[],3),[1 1 3]);
        if ~isnan(unique_stimulus_index_other)
            recomputed_image_other_gray=repmat(max(recomputed_image_other,[],3),[1 1 3]);
        end
        reconstructed_image_gray=repmat(max(reconstructed_image,[],3),[1 1 3]);


        features_to_check = compute_param(model,{recomputed_image_gray},landmarks(:,:,unique_stimulus_index_to_check));
        features_other = compute_param(model,{recomputed_image_other_gray},landmarks(:,:,unique_stimulus_index_other));
        features_reconstructed = compute_param(model,{reconstructed_image_gray},landmarks_reconstructions(:,:,unique_stimulus_index_to_check));
        %This recomputes the gray (this does not work that well, it still retains some red/cyan somehow)
        recomputed_image=recomputed_image_gray;
        if ~isnan(unique_stimulus_index_other);recomputed_image_other=recomputed_image_other_gray;end
        reconstructed_image=reconstructed_image_gray;

    else
        features_to_check = features(unique_stimulus_index_to_check,:);
        if ~isnan(unique_stimulus_index_other);features_other = features(unique_stimulus_index_other,:);end
        features_reconstructed = predicted_features_cv(unique_stimulus_index_to_check,:);
    end


    nexttile
    imshow(uint8(recomputed_image))
    title('Dominant')
    nexttile
    if ~isnan(unique_stimulus_index_other)
        imshow(uint8(recomputed_image_other))
    end
    title('Suppressed')
    if skip_image==3
        nexttile;axis off;
    end
    nexttile
    imshow(uint8(reconstructed_image))
    title('Dominant-Reconstructed')
    if config.b_concatenate_features_other
        nexttile
        imshow(uint8(reconstructed_image_other))
        title('Suppressed-Reconstructed')
    end
    if skip_image==4
        nexttile;axis off;
    end

    features_normalized_selected_to_check = (features_to_check(:,distance_features) - features_mean(:,distance_features))./features_std(:,distance_features);
    if ~isnan(unique_stimulus_index_other);
        features_normalized_selected_other = (features_other(:,distance_features) - features_mean(:,distance_features))./features_std(:,distance_features);
    end
    features_normalized_selected_reconstructed = (features_reconstructed(:,distance_features) - features_mean(:,distance_features))./features_std(:,distance_features);
    if ~isnan(unique_stimulus_index_other);
        if strcmp(distance_method,'euclidean')
            distance_to_check = norm(features_normalized_selected_to_check,features_normalized_selected_reconstructed);
            distance_other = norm(features_normalized_selected_other,features_normalized_selected_reconstructed);
            correct_pair(unique_stimulus_index_to_check) = distance_to_check<distance_other;
        elseif strcmp(distance_method,'dotproduct')
            distance_to_check = dot(features_normalized_selected_to_check,features_normalized_selected_reconstructed);
            distance_other = dot(features_normalized_selected_other,features_normalized_selected_reconstructed);
            correct_pair(unique_stimulus_index_to_check) = distance_to_check>distance_other;
        end
    end
end

f=figure(42);set(f,'Units','normalized','Position',[0         0    1.5000    1.4730])
file_name = [folder_name filesep 'reconstructions'];
if folder_name;print(f,file_name, '-dpng','-r0');end
f=figure(43);set(f,'Units','normalized','Position',[0         0    1.5000    1.4730])
if ~isnan(unique_stimulus_index_other)
sgtitle([num2str(nanmean(correct_pair)*100) '% correct.'])
end
if b_make_images_gray
    gray_string = '_gray';
else
    gray_string = '';
end
if config.b_use_control_1_stimuli
    control_1b_string = '_control_1b_template_pairs';
else
    control_1b_string = '';
end
file_name = [folder_name filesep 'reconstructions_with_other' gray_string control_1b_string];
if folder_name;print(f,file_name, '-dpng','-r0');end
