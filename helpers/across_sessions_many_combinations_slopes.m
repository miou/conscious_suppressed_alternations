data = switches_config_release;

fs_slope_state_1 = state_1.flash_suppression_results_all_sessions;

fs_slope_state_2 = state_2.flash_suppression_results_all_sessions;


responses_priming_all = [];

b_use_stimulus_rank = true;

responses_binocular_dominant_state_1_all = [];
responses_binocular_suppressed_state_1_all = [];
responses_binocular_dominant_state_2_all = [];
responses_binocular_suppressed_state_2_all = [];
neurons_mean = [];
neurons_std = [];
b_selected = false(0);
b_selected_all = false(0);
coefficients_state_1_dominant_all = [];
coefficients_state_2_suppressed_all = [];
for session_index = 1:length(fs_slope_state_1)
    if ~isempty(fs_slope_state_1{session_index})

        figure(1);clf;
        imagesc([squeeze(mean(fs_slope_state_1{session_index}.priming.responses_red_dominant_all,3)),squeeze(mean(fs_slope_state_1{session_index}.priming.responses_cyan_dominant_all,3))]);
        figure(2);clf;
        imagesc([squeeze(mean(fs_slope_state_1{session_index}.priming.responses_red_dominant_all,2)),squeeze(mean(fs_slope_state_1{session_index}.priming.responses_cyan_dominant_all,2))]);

        responses_priming_all_red = squeeze(mean(fs_slope_state_1{session_index}.priming.responses_red_dominant_all,2))';
        responses_priming_all_cyan = squeeze(mean(fs_slope_state_1{session_index}.priming.responses_cyan_dominant_all,3))';

        responses_binocular_dominant_red_state_1 = squeeze(mean(fs_slope_state_1{session_index}.binocular.responses_red_dominant_state_all,2))';
        responses_binocular_dominant_cyan_state_1 = squeeze(mean(fs_slope_state_1{session_index}.binocular.responses_cyan_dominant_state_all,3))';
        responses_binocular_suppressed_red_state_1 = squeeze(mean(fs_slope_state_1{session_index}.binocular.responses_cyan_dominant_state_all,2))';
        responses_binocular_suppressed_cyan_state_1 = squeeze(mean(fs_slope_state_1{session_index}.binocular.responses_red_dominant_state_all,3))';
        responses_binocular_dominant_red_state_2 = squeeze(mean(fs_slope_state_2{session_index}.binocular.responses_red_dominant_state_all,2))';
        responses_binocular_dominant_cyan_state_2 = squeeze(mean(fs_slope_state_2{session_index}.binocular.responses_cyan_dominant_state_all,3))';
        responses_binocular_suppressed_red_state_2 = squeeze(mean(fs_slope_state_2{session_index}.binocular.responses_cyan_dominant_state_all,2))';
        responses_binocular_suppressed_cyan_state_2 = squeeze(mean(fs_slope_state_2{session_index}.binocular.responses_red_dominant_state_all,3))';


        responses_priming = [responses_priming_all_red; responses_priming_all_cyan];
        responses_binocular_dominant_state_1 = [responses_binocular_dominant_red_state_1; responses_binocular_dominant_cyan_state_1];
        responses_binocular_suppressed_state_1 = [responses_binocular_suppressed_red_state_1; responses_binocular_suppressed_cyan_state_1];
        responses_binocular_dominant_state_2 =  [responses_binocular_dominant_red_state_2; responses_binocular_dominant_cyan_state_2];
        responses_binocular_suppressed_state_2 = [responses_binocular_suppressed_red_state_2; responses_binocular_suppressed_cyan_state_2];

        [responses_priming_sorted,sort_matrix_priming] = sort(responses_priming);
        sort_matrix_to_use = sort_matrix_priming;
        [m,n]=size(responses_priming);sort_indices = (sub2ind([m n],sort_matrix_to_use,repmat(1:n,m,1)));
        responses_priming_sorted_by_scheme = responses_priming(sort_indices);

        if b_use_stimulus_rank
            x_for_regression = (1:size(responses_binocular_dominant_state_1,1))';
        else
            responses_priming_sorted_by_scheme_centered = responses_priming_sorted_by_scheme-nanmean(responses_priming_sorted_by_scheme,1);
            x_for_regression = responses_priming_sorted_by_scheme_centered./max(abs(responses_priming_sorted_by_scheme_centered),[],1,'omitnan');
        end

        coefficients_state_1_dominant = lscov_columns_nonan(x_for_regression,responses_binocular_dominant_state_1(sort_indices));
        coefficients_state_1_dominant_all = [coefficients_state_1_dominant_all coefficients_state_1_dominant];
        coefficients_state_2_suppressed = lscov_columns_nonan(x_for_regression,responses_binocular_suppressed_state_2(sort_indices));
        coefficients_state_2_suppressed_all = [coefficients_state_2_suppressed_all coefficients_state_2_suppressed];
        fs_slope_state_1{session_index}.coefficients_state_1_dominant = coefficients_state_1_dominant;
        fs_slope_state_2{session_index}.coefficients_state_2_suppressed = coefficients_state_2_suppressed;
        % b_selected_all = [b_selected_all,(sum(sum(fs_slope_state_1{session_index}.priming.responses_p_value_all<0.05,3),2)>4)'];
        b_selected_all = [b_selected_all,fs_slope_state_1{session_index}.p_value_visual_response<0.05];

        if size(responses_priming,1)==10
            responses_priming_all = [responses_priming_all, responses_priming];
            responses_binocular_dominant_state_1_all = [responses_binocular_dominant_state_1_all, responses_binocular_dominant_state_1];
            responses_binocular_suppressed_state_1_all = [responses_binocular_suppressed_state_1_all, responses_binocular_suppressed_state_1];
            responses_binocular_dominant_state_2_all = [responses_binocular_dominant_state_2_all, responses_binocular_dominant_state_2];
            responses_binocular_suppressed_state_2_all = [responses_binocular_suppressed_state_2_all, responses_binocular_suppressed_state_2];
            neurons_mean = [neurons_mean, squeeze(fs_slope_state_1{session_index}.neurons_mean)'];
            neurons_std = [neurons_std, squeeze(fs_slope_state_1{session_index}.neurons_std)'];
            % b_selected = [b_selected,(sum(sum(fs_slope_state_1{session_index}.priming.responses_p_value_all<0.05,3),2)>4)'];
            b_selected = [b_selected,fs_slope_state_1{session_index}.p_value_visual_response<0.05];
        end


    end
end

[responses_priming_all_sorted,sort_matrix_priming] = sort(responses_priming_all);




sort_matrix_to_use = sort_matrix_priming;

[m,n]=size(responses_priming_all);
sort_indices = (sub2ind([m n],sort_matrix_to_use,repmat(1:n,m,1)));
responses_priming_all_sorted_by_scheme = responses_priming_all(sort_indices);

if b_use_stimulus_rank
    x_for_regression = (1:size(responses_priming_all_sorted_by_scheme,1))';
else
    responses_priming_sorted_by_scheme_centered = responses_priming_all_sorted_by_scheme-nanmean(responses_priming_all_sorted_by_scheme,1);
    x_for_regression = responses_priming_sorted_by_scheme_centered./max(abs(responses_priming_sorted_by_scheme_centered),[],1,'omitnan');
end


b = lscov_columns_nonan(x_for_regression,responses_priming_all_sorted_by_scheme);
slopes = b(2,:);
[~,neuron_sort_indices] = sort(slopes,'desc');

neuron_sort_indices = neuron_sort_indices(b_selected(neuron_sort_indices)); %Subselect selective cells

% neurons_mean = mean(responses_priming_all,1);
% neurons_std = std(responses_priming_all,[],1);

responses_priming_all_sorted_by_scheme_normalized = (responses_priming_all_sorted_by_scheme - neurons_mean)./neurons_std;

figure(1);clf;imagesc(responses_priming_all_sorted_by_scheme_normalized);
figure(1);clf;imagesc(responses_priming_all_sorted_by_scheme_normalized(:,neuron_sort_indices),[-3 3]);colormap redblue;

responses_binocular_dominant_state_1_all_sorted_by_scheme_normalized = (responses_binocular_dominant_state_1_all(sort_indices)  - neurons_mean)./neurons_std;
figure(2);clf;imagesc(responses_binocular_dominant_state_1_all_sorted_by_scheme_normalized(:,neuron_sort_indices),[-3 3]);colormap redblue;
b_state_1_dominant = lscov_columns_nonan(x_for_regression,responses_binocular_dominant_state_1_all_sorted_by_scheme_normalized);

responses_binocular_dominant_state_2_all_sorted_by_scheme_normalized = (responses_binocular_dominant_state_2_all(sort_indices)  - neurons_mean)./neurons_std;
figure(3);clf;imagesc(responses_binocular_dominant_state_2_all_sorted_by_scheme_normalized(:,neuron_sort_indices),[-3 3]);colormap redblue;
b_state_2_dominant = lscov_columns_nonan(x_for_regression,responses_binocular_dominant_state_2_all_sorted_by_scheme_normalized);

responses_binocular_suppressed_state_1_all_sorted_by_scheme_normalized = (responses_binocular_suppressed_state_1_all(sort_indices)  - neurons_mean)./neurons_std;
figure(4);clf;imagesc(responses_binocular_suppressed_state_1_all_sorted_by_scheme_normalized(:,neuron_sort_indices),[-3 3]);colormap redblue;
b_state_1_suppressed = lscov_columns_nonan(x_for_regression,responses_binocular_suppressed_state_1_all_sorted_by_scheme_normalized);

responses_binocular_suppressed_state_2_all_sorted_by_scheme_normalized = (responses_binocular_suppressed_state_2_all(sort_indices)  - neurons_mean)./neurons_std;
figure(5);clf;imagesc(responses_binocular_suppressed_state_2_all_sorted_by_scheme_normalized(:,neuron_sort_indices),[-3 3]);colormap redblue;
b_state_2_suppressed = lscov_columns_nonan(x_for_regression,responses_binocular_suppressed_state_2_all_sorted_by_scheme_normalized);

figure(1);clf;hold on;histogram(b_state_1_dominant(2,b_selected),'FaceColor',hex2rgb(data.state_colors(1)),'EdgeColor','none');histogram(b_state_2_dominant(2,b_selected),'FaceColor',0.3*hex2rgb(data.state_colors(2)),'EdgeColor','none');histogram(b_state_1_suppressed(2,b_selected),'FaceColor',0.3*hex2rgb(data.state_colors(1)),'EdgeColor','none');histogram(b_state_2_suppressed(2,b_selected),'FaceColor',hex2rgb(data.state_colors(2)),'EdgeColor','none');
legend('Conscious state 1','Conscious state 2','Suppressed state 1','Suppressed state 2')

figure(1);clf;hold on;scatter(b_state_1_dominant(2,b_selected),b_state_2_suppressed(2,b_selected),'filled','MarkerFaceColor','k','MarkerFaceAlpha',0.3,'MarkerEdgeAlpha',0.5);
lim_min = min([xlim ylim]);lim_max = max([xlim ylim]);plot([lim_min lim_max], [lim_min lim_max],'k--');plot([lim_min lim_max], [0 0],'k--');plot([0 0], [lim_min lim_max],'k--');set(gca,'xlim',[lim_min lim_max]);set(gca,'ylim',[lim_min lim_max]);xlabel('Slope state 1 conscious');ylabel('Slope state 2 suppressed');
[h,p] = ttest(b_state_1_dominant(2,b_selected),b_state_2_suppressed(2,b_selected))

 [h,p,ci,stats] = ttest(coefficients_state_1_dominant_all(2,b_selected_all),coefficients_state_2_suppressed_all(2,b_selected_all))

