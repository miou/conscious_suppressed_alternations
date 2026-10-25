function flash_suppression_axes_plotting(config,xml_folder,xml_filename,folder_name,responses_to_use_training,features,weights_predicting_responses,weights_predicting_features,predicted_features_cv,explained_variance_features,explained_variance_features_cv,explained_variance_features_cv_high_repeat,explained_variance_features_cv_high_repeat_other,explained_variance_features_st,explained_variance_features_st_loto,explained_variance_features_cv_alpha,explained_variance_responses,explained_variance_responses_cv,explained_variance_responses_cv_high_repeat,explained_variance_responses_st,explained_variance_responses_ot_stimulus,explained_variance_responses_cv_weighted_average,explained_variance_responses_cv_high_repeat_weighted_average,explained_variance_responses_cv_high_repeat_weighted_average_across_halves,alpha_strct,predicted_responses_weighted_average,number_of_stimuli_total_list,number_of_stimuli_for_decoding_list, percentage_correct,  percentage_correct_cv, percentage_correct_st, percentage_correct_st_loto, percentage_correct_responses_st_loto,pairwise_distances_responses_st_loto,percentage_correct_cv_other)
f=figure(1);clf;hold on;
plot(100*mean(explained_variance_features_cv_high_repeat(:,:,end),2),'LineWidth',2,'Color',[.5 .5 .5])
xlabel('Feature')
ylabel('R^2')
title(['Explained variance of features. n=' num2str(size(responses_to_use_training,2))])
set(gca,'ylim',[-100,100]);box off;
set(gca,'XLim',[0 50])
file_name = [folder_name filesep 'feature_explained_variance_cv_high_repeat'];
if folder_name; savefig(f,file_name);end

f=figure(1);clf;hold on;
plot(100*mean(explained_variance_features(:,:,end),2));
plot(100*mean(explained_variance_features_cv(:,:,end),2))
plot(100*mean(explained_variance_features_cv_high_repeat(:,:,end),2))
plot(100*mean(explained_variance_features_st(:,:,end),2));
plot(100*mean(explained_variance_features_st_loto(:,:,end),2))
legend({'No cross-validation, averaged','Leave-one-image-out average','Leave-one-image-out average high repeat','Leave-one-image-out single trials','Leave-one-trial-out single trials'})
xlabel('Feature')
ylabel('R^2')
title(['Explained variance of features. n=' num2str(size(responses_to_use_training,2))])
set(gca,'ylim',[-100,100])
file_name = [folder_name filesep 'feature_explained_variance'];
if folder_name;print(f,file_name, '-dpng','-r0');end

f=figure(2);clf;hold on;
plot(100*mean(explained_variance_features_cv_high_repeat_other(:,:,end),2),'y')
legend('Leave-one-image-out average high repeat other')
xlabel('Feature')
ylabel('R^2')
title(['Explained variance of OTHER features. n=' num2str(size(responses_to_use_training,2))])
set(gca,'ylim',[-100,100])
set(gca,'XLim',[0 50])

file_name = [folder_name filesep 'feature_explained_variance_other'];
if folder_name;print(f,file_name, '-dpng','-r0');end

if contains(xml_filename, 'FlashSuppression_many_faces_Liang_2500_many_pairs')
    num_shape_dimensions = 20;
    num_appearance_dimensions = 100;
else
    num_shape_dimensions = 25;
    num_appearance_dimensions = 25;
end
shape_dimension_to_plot = 1;
appearance_dimension_to_plot = shape_dimension_to_plot;
f=figure(3);clf;hold on;
subplot(1,2,1);hold on;
scatter(features(:,shape_dimension_to_plot),predicted_features_cv(:,shape_dimension_to_plot),20,'k','filled');
plot(xlim,xlim,'k--')
axis square;
xlabel(['Actual shape no. ' num2str(shape_dimension_to_plot) ' value']);ylabel(['Predicted shape ' num2str(shape_dimension_to_plot) ' value (leave-one-image out)'])
subplot(1,2,2);hold on;
scatter(features(:,num_shape_dimensions+appearance_dimension_to_plot),predicted_features_cv(:,num_shape_dimensions+appearance_dimension_to_plot),20,'k','filled');
plot(xlim,xlim,'k--')
xlabel(['Actual appearance no. ' num2str(appearance_dimension_to_plot) ' value']);ylabel(['Predicted appearance ' num2str(appearance_dimension_to_plot) ' value (leave-one-image out)'])
axis square
set(gca,'xlim',[min([xlim ylim]) max([xlim ylim])]);set(gca,'ylim',[min([xlim ylim]) max([xlim ylim])])
file_name = [folder_name filesep 'shape_appearance_actual_predicted_' num2str(shape_dimension_to_plot) num2str(appearance_dimension_to_plot)];
if folder_name;print(f,file_name, '-dpng','-r0');end

f=figure(4);clf;hold on;
plot(number_of_stimuli_for_decoding_list,mean(percentage_correct(:,:,end),2));
plot(number_of_stimuli_for_decoding_list,mean(percentage_correct_cv(:,:,end),2),'LineWidth',2);
plot(number_of_stimuli_for_decoding_list,mean(percentage_correct_st(:,:,end),2))
plot(number_of_stimuli_for_decoding_list,mean(percentage_correct_st_loto(:,:,end),2));
plot(number_of_stimuli_for_decoding_list,mean(percentage_correct_responses_st_loto(:,:,end),2));
legend({'No cross-validation, averaged','Leave-one-image-out average','Leave-one-image-out single trials','Leave-one-trial-out single trials','Leave-one-trial-out responses single trials'})
plot(number_of_stimuli_for_decoding_list,1./number_of_stimuli_for_decoding_list,'k--');
title('Decoding accuracy of stimuli')
xlabel('Number of stimuli for decoding')
ylabel('Decoding accuracy as number of stimuli for decoding')
ylim([0 1])
file_name = [folder_name filesep 'decoding_accuracy_number_of_stimuli'];
if folder_name;print(f,file_name, '-dpng','-r0');end

f=figure(4);clf;hold on;
plot(number_of_stimuli_for_decoding_list,mean(percentage_correct_cv(:,:,end),2),'LineWidth',2);
plot(number_of_stimuli_for_decoding_list,mean(percentage_correct_cv_other(:,:,end),2),'LineWidth',2);
plot(number_of_stimuli_for_decoding_list,1./number_of_stimuli_for_decoding_list,'k:');
title('Decoding accuracy of stimuli')
xlabel('Number of stimuli for decoding')
ylabel('Decoding accuracy as number of stimuli for decoding')
ylim([0 1])

if size(percentage_correct_cv,2)>1
    if isfield(config,'states_to_use') && ~isempty(config.states_to_use) && config.states_to_use.state_value==2
        figure(4); clf;hold on;bar_with_std(3,percentage_correct_cv(10,:));set(gca,'ylim',[0 1]);box off;set(gca,'xlim',[0 5]);h = gca;h.XAxis.Visible = 'off';
        bar_with_std(4,percentage_correct_cv_other(10,:));set(gca,'ylim',[0 1]);%axis off
        set(gca,'color','none')
        file_name = [folder_name filesep 'decoding_accuracy_10_stimuli_bargraph'];
        if folder_name;print(f,file_name, '-dpng','-r0');end
    else
        figure(4); clf;hold on;bar_with_std(1,percentage_correct_cv(10,:));set(gca,'ylim',[0 1]);box off;set(gca,'xlim',[0 5]);h = gca;h.XAxis.Visible = 'off';
        bar_with_std(2,percentage_correct_cv_other(10,:));set(gca,'ylim',[0 1]);%axis off
        set(gca,'color','none')
        file_name = [folder_name filesep 'decoding_accuracy_10_stimuli_bargraph'];
        if folder_name;print(f,file_name, '-dpng','-r0');end
    end
end


if ~isempty(explained_variance_features)
    f=figure(5);clf;hold on;
    plot(number_of_stimuli_total_list,100*squeeze(mean(explained_variance_features(1,:,:),2)));
    plot(number_of_stimuli_total_list,100*squeeze(mean(explained_variance_features_cv(1,:,:),2)))
    plot(number_of_stimuli_total_list,100*squeeze(mean(explained_variance_features_st(1,:,:),2)));
    plot(number_of_stimuli_total_list,100*squeeze(mean(explained_variance_features_st_loto(1,:,:),2)));

    legend({'No cross-validation, averaged','Leave-one-image-out average','Leave-one-image-out single trials','Leave-one-trial-out single trials'})
    xlabel('Number of stimuli for training')
    title(['Number of stimuli to discriminate between: ' num2str(number_of_stimuli_for_decoding_list(end))])

    ylabel('R^2')
end
f=figure(6);clf;hold on;
plot(number_of_stimuli_total_list,squeeze(mean(percentage_correct(end,:,:),2)));
plot(number_of_stimuli_total_list,squeeze(mean(percentage_correct_cv(end,:,:),2)));
plot(number_of_stimuli_total_list,squeeze(mean(percentage_correct_st(end,:,:),2)));
plot(number_of_stimuli_total_list,squeeze(mean(percentage_correct_st_loto(end,:,:),2)));
legend({'No cross-validation, averaged','Leave-one-image-out average','Leave-one-image-out single trials','Leave-one-trial-out single trials'})
plot(number_of_stimuli_total_list,repmat(1./number_of_stimuli_for_decoding_list(end),[1 length(number_of_stimuli_total_list)]),'k--')
xlabel('Number of stimuli for training')
ylabel('Decoding accuracy')
title(['Number of stimuli to discriminate between: ' num2str(number_of_stimuli_for_decoding_list(end))])
ylim([0 1])

f=figure(8);clf;hold on;
scatter(100*explained_variance_responses_ot_stimulus,100*explained_variance_responses_st,'k')
xlabel('Explained variance of features all but one trials averaged');ylabel('Explained variance of features single trials');
title('Explained response variance with one image left out')
make_axis_lims_equal_and_plot_diagonal;
xlim([-100 100])
ylim([-100 100])
file_name = [folder_name filesep 'response_explained_variance_average_vs_single_trial'];
if folder_name;print(f,file_name, '-dpng','-r0');end


f=figure(10);clf;hold on
[~,sort_indices2] = sort(explained_variance_responses_cv_high_repeat,'desc');
plot(explained_variance_responses_cv_high_repeat(sort_indices2),'Color',[.5 .5 .5],'LineWidth',2)
ylabel('Explained variance of response');xlabel('Unit # (sorted)');set(gca,'ylim',[-1 1]);yticks([-1:.5:1]);axis square
file_name = [folder_name filesep 'response_explained_variance'];
if folder_name;savefig(f,file_name);end

f=figure(11);clf;hold on
[~,sort_indices] = sort(explained_variance_responses_cv,'desc');
[~,sort_indices2] = sort(explained_variance_responses_cv_high_repeat,'desc');
plot(explained_variance_responses_cv(sort_indices),'r')
plot(explained_variance_responses_cv_high_repeat(sort_indices2),'m')
ylabel('Explained variance of response');xlabel('Unit # (sorted)');set(gca,'ylim',[-1 1]);yticks([-1:.5:1]);axis square
file_name = [folder_name filesep 'response_explained_variance_sorted'];
if folder_name;print(f,file_name, '-dpng','-r0');end


f=figure(12);clf;histogram(alpha_strct.coefs_pred_alpha,-0.1:.05:1.1)
title(num2str(median(alpha_strct.coefs_pred_alpha_high_repeat)));
file_name = [folder_name filesep 'histogram_alphas'];
if folder_name;print(f,file_name, '-dpng','-r0');end


f=figure(13);clf;hold on;
[~,sort_indices] = sort(explained_variance_responses_cv_high_repeat_weighted_average_across_halves,'desc');
plot(explained_variance_responses_cv_high_repeat_weighted_average_across_halves(sort_indices),'k')
[~,sort_indices] = sort(explained_variance_responses_cv_weighted_average,'desc');
plot(explained_variance_responses_cv_weighted_average(sort_indices),'r')
[~,sort_indices] = sort(explained_variance_responses_cv_weighted_average,'desc');
plot(explained_variance_responses_cv_high_repeat_weighted_average(sort_indices),'m')
legend('high repeat across halves', 'normal','high repeat')
ylabel('Explained variance of response');xlabel('Unit # (sorted)');set(gca,'ylim',[-1 1]);yticks([-1:.5:1]);axis square
file_name = [folder_name filesep 'response_explained_variance_sorted_alpha'];
if folder_name;print(f,file_name, '-dpng','-r0');end

f=figure(14);clf;
subplot(1,2,1)
scatter(alpha_strct.coefs_alpha_high_repeat_first_half,alpha_strct.coefs_alpha_high_repeat_second_half,'k','filled','MarkerFaceAlpha',0.5)
xlabel('\alpha first half of high repeat stimuli');ylabel('\alpha second half of high repeat stimuli');
set(gca,'xlim',[0 1]);set(gca,'ylim',[0 1]);axis square
[r,p] = corrcoef(alpha_strct.coefs_alpha_high_repeat_first_half,alpha_strct.coefs_alpha_high_repeat_second_half);
if length(r)>1
    title({'Alpha based on priming responses and binocular dominant responses.',['r=' num2str(r(2),4) '. p=' num2str(p(2),4) '.']})
end
subplot(1,2,2)
scatter(alpha_strct.coefs_pred_alpha_high_repeat_first_half,alpha_strct.coefs_pred_alpha_high_repeat_second_half,'k','filled','MarkerFaceAlpha',0.5)
xlabel('\alpha first half of high repeat stimuli');ylabel('\alpha second half of high repeat stimuli');
set(gca,'xlim',[0 1]);set(gca,'ylim',[0 1]);axis square
[r,p] = corrcoef(alpha_strct.coefs_pred_alpha_high_repeat_first_half,alpha_strct.coefs_pred_alpha_high_repeat_second_half);
if length(r)>1
    title({'Alpha based on predicted responses and binocular dominant responses.',['r=' num2str(r(2),4) '. p=' num2str(p(2),4) '.']})
end
file_name = [folder_name filesep 'alpha_first_vs_second_half'];
if folder_name;print(f,file_name, '-dpng','-r0');end


weights_predicting_responses_appearance_scaled = weights_predicting_responses;
if contains(xml_filename, 'FlashSuppression_many_faces_Liang_2500_many_pairs')
    weights_predicting_responses_appearance_scaled(22:end,:)=weights_predicting_responses(22:end,:)*30000;
end
f=figure(15);clf;imagesc(weights_predicting_responses_appearance_scaled(1:50,:)',[-25 25]);colorbar;%colormap jet;
orangemap = esa(300);
[white_color, white_pos] = max(sum(orangemap,2));
orangemap = orangemap([1:white_pos round(linspace(white_pos+1,size(orangemap,1)-2,white_pos-1))],:);
colormap(orangemap)
file_name = [folder_name filesep 'weights_predicting_responses'];
if folder_name;print(f,file_name, '-dpng','-r0');end



if config.b_plot_single_cells && strcmp(config.cell_selection_scheme,'all')
    for cell_index = 1:size(predicted_responses_weighted_average,2)
        f=figure(44);clf;
        subplot(1,3,1);hold on;
        scatter(predicted_responses_weighted_average(unique_stimuli_is_high_repeat,cell_index),responses_dominant_binocular(unique_stimuli_is_high_repeat,cell_index),'k','filled')
        [r,p] = corrcoef(predicted_responses_weighted_average(unique_stimuli_is_high_repeat,cell_index),responses_dominant_binocular(unique_stimuli_is_high_repeat,cell_index));
        title(['Fitted \alpha. r=' num2str(r(2),3) ', p=' num2str(p(2),3) ])
        set(gca,'xlim',[min([xlim ylim]) max([xlim ylim])]);set(gca,'ylim',[min([xlim ylim]) max([xlim ylim])]);axis square
        subplot(1,3,2);hold on;
        scatter(responses_priming(unique_stimuli_is_high_repeat,cell_index),responses_dominant_binocular(unique_stimuli_is_high_repeat,cell_index),'k','filled')
        [r,p] = corrcoef(responses_priming(unique_stimuli_is_high_repeat,cell_index),responses_dominant_binocular(unique_stimuli_is_high_repeat,cell_index));
        title(['\alpha=1. r=' num2str(r(2),3) ', p=' num2str(p(2),3) ])
        set(gca,'xlim',[min([xlim ylim]) max([xlim ylim])]);set(gca,'ylim',[min([xlim ylim]) max([xlim ylim])]);axis square
        subplot(1,3,3);hold on;
        scatter(responses_priming(unique_stimulus_index_other_list(unique_stimuli_is_high_repeat),cell_index),responses_dominant_binocular(unique_stimuli_is_high_repeat,cell_index),'k','filled')
        [r,p] = corrcoef(responses_priming(unique_stimulus_index_other_list(unique_stimuli_is_high_repeat),cell_index),responses_dominant_binocular(unique_stimuli_is_high_repeat,cell_index));
        title(['\alpha=0. r=' num2str(r(2),3) ', p=' num2str(p(2),3) ])
        set(gca,'xlim',[min([xlim ylim]) max([xlim ylim])]);set(gca,'ylim',[min([xlim ylim]) max([xlim ylim])]);axis square

        file_name = [config.folder_name_single_cells filesep num2str((cell_index)) '_probe_' num2str(session.unit_probes_index(cell_index)) '_channel_' num2str(session.unit_channel(cell_index)) '_unit_' num2str(session.unit_id(cell_index)) '_alpha_predictions'];
        if folder_name;print(f,file_name, '-dpng','-r0');end
    end
end
