rivalry_config = switches_config_release;

fs_slope_state_1 = summary_state_1.flash_suppression_results_all_sessions;

fs_slope_state_2 = summary_state_2.flash_suppression_results_all_sessions;


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
        b_selected_all = [b_selected_all,fs_slope_state_1{session_index}.p_value_visual_response<0.05];

        if size(responses_priming,1)==10
            responses_priming_all = [responses_priming_all, responses_priming];
            responses_binocular_dominant_state_1_all = [responses_binocular_dominant_state_1_all, responses_binocular_dominant_state_1];
            responses_binocular_suppressed_state_1_all = [responses_binocular_suppressed_state_1_all, responses_binocular_suppressed_state_1];
            responses_binocular_dominant_state_2_all = [responses_binocular_dominant_state_2_all, responses_binocular_dominant_state_2];
            responses_binocular_suppressed_state_2_all = [responses_binocular_suppressed_state_2_all, responses_binocular_suppressed_state_2];
            neurons_mean = [neurons_mean, squeeze(fs_slope_state_1{session_index}.neurons_mean)'];
            neurons_std = [neurons_std, squeeze(fs_slope_state_1{session_index}.neurons_std)'];
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


responses_priming_all_sorted_by_scheme_normalized = (responses_priming_all_sorted_by_scheme - neurons_mean)./neurons_std;

responses_binocular_dominant_state_1_all_sorted_by_scheme_normalized = (responses_binocular_dominant_state_1_all(sort_indices)  - neurons_mean)./neurons_std;
b_state_1_dominant = lscov_columns_nonan(x_for_regression,responses_binocular_dominant_state_1_all_sorted_by_scheme_normalized);

responses_binocular_dominant_state_2_all_sorted_by_scheme_normalized = (responses_binocular_dominant_state_2_all(sort_indices)  - neurons_mean)./neurons_std;
b_state_2_dominant = lscov_columns_nonan(x_for_regression,responses_binocular_dominant_state_2_all_sorted_by_scheme_normalized);

responses_binocular_suppressed_state_1_all_sorted_by_scheme_normalized = (responses_binocular_suppressed_state_1_all(sort_indices)  - neurons_mean)./neurons_std;
b_state_1_suppressed = lscov_columns_nonan(x_for_regression,responses_binocular_suppressed_state_1_all_sorted_by_scheme_normalized);

responses_binocular_suppressed_state_2_all_sorted_by_scheme_normalized = (responses_binocular_suppressed_state_2_all(sort_indices)  - neurons_mean)./neurons_std;
b_state_2_suppressed = lscov_columns_nonan(x_for_regression,responses_binocular_suppressed_state_2_all_sorted_by_scheme_normalized);

