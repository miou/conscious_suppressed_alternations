%% Compute modulation indices (the figure script draws the paper panel)
MI = @(x,y) (x-y)./(x+y);

session_names_all = cell(size(summary_state_1.flash_suppression_results_all_sessions));
session_names_not_empty = {};
for session_index_across_sessions = 1:length(summary_state_1.flash_suppression_results_all_sessions)
    if ~isempty(summary_state_1.flash_suppression_results_all_sessions{session_index_across_sessions})
        session_names_all{session_index_across_sessions} = summary_state_1.flash_suppression_results_all_sessions{session_index_across_sessions}.session_name;
        session_names_not_empty = [session_names_not_empty {summary_state_1.flash_suppression_results_all_sessions{session_index_across_sessions}.session_name}];
        assert(strcmp(summary_state_1.flash_suppression_results_all_sessions{session_index_across_sessions}.session_name,summary_state_2.flash_suppression_results_all_sessions{session_index_across_sessions}.session_name))
    end
end

b_only_face_pairs = 0;

for context_combinations_index = 1:length(context_combinations)
    context_1 = context_combinations{context_combinations_index}{1};
    context_2 = context_combinations{context_combinations_index}{2};

    modulation_indices_context_1_significant_1 = cell(length(regions_to_plot),1);
    modulation_indices_context_2_significant_1 = cell(length(regions_to_plot),1);
    modulation_indices_context_1_significant_both = cell(length(regions_to_plot),1);
    modulation_indices_context_2_significant_both = cell(length(regions_to_plot),1);

    red_dominant_context_2_significant_1 = cell(length(regions_to_plot),1);
    cyan_dominant_context_2_significant_1 = cell(length(regions_to_plot),1);
    red_dominant_state_context_2_significant_1 = cell(length(regions_to_plot),1);
    cyan_dominant_state_context_2_significant_1 = cell(length(regions_to_plot),1);


    for session_index_across_sessions = 1:length(summary_state_1.flash_suppression_results_all_sessions)
        if ~isempty(summary_state_1.flash_suppression_results_all_sessions{session_index_across_sessions})% && ismember(session_index_across_sessions,[133,137,138,140,143,145, 146,148, 167,151])
            fs_1 = summary_state_1.flash_suppression_results_all_sessions{session_index_across_sessions};
            fs_2 = summary_state_2.flash_suppression_results_all_sessions{session_index_across_sessions};
            disp(fs_1.regions)

            if isfield(fs_1.unambiguous,'modulation_indices')

                R_C_combinations = combinations(1:size(fs_1.(context_1).responses_red_dominant,2),1:size(fs_1.(context_1).responses_red_dominant,3));
                for R_C_combinations_index = 1:size(R_C_combinations,1)
                    R_1 = R_C_combinations{R_C_combinations_index,1};
                    C_1 = R_C_combinations{R_C_combinations_index,2};
                    if (contains(fs_1.images_red_for_modulation{R_1},'face') && contains(fs_1.images_cyan_for_modulation{C_1},'face')) || ~b_only_face_pairs
                        p_value_context_1 = fs_1.(context_1).responses_p_value(:,R_1,C_1);
                        modulation_indices_context_1 = fs_1.(context_1).modulation_indices(:,R_1,C_1);


                        p_value_context_2 = fs_1.(context_2).responses_p_value(:,R_1,C_1);



                        red_dominant_context_2 = fs_1.(context_2).responses_red_dominant(:,R_1,C_1);
                        cyan_dominant_context_2 = fs_1.(context_2).responses_cyan_dominant(:,R_1,C_1);
                        if b_compute_for_state==1
                            modulation_indices_context_2 = fs_1.(context_2).modulation_indices_state(:,R_1,C_1);
                            red_dominant_state_context_2 = fs_1.(context_2).responses_red_dominant_state(:,R_1,C_1);
                            cyan_dominant_state_context_2 = fs_1.(context_2).responses_cyan_dominant_state(:,R_1,C_1);
                        elseif b_compute_for_state==2
                            modulation_indices_context_2 = fs_2.(context_2).modulation_indices_state(:,R_1,C_1);
                            red_dominant_state_context_2 = fs_2.(context_2).responses_red_dominant_state(:,R_1,C_1);
                            cyan_dominant_state_context_2 = fs_2.(context_2).responses_cyan_dominant_state(:,R_1,C_1);
                        elseif b_compute_for_state==5 %Use slope scale for each cell
                            %Needs to first run:
                            % across_sessions_many_combinations_slopes
                            responses_red_dominant_state_1 = fs_1.(context_2).responses_red_dominant_state;
                            responses_red_dominant_state_2 = fs_2.(context_2).responses_red_dominant_state;
                            responses_cyan_dominant_state_1 = fs_1.(context_2).responses_cyan_dominant_state;
                            responses_cyan_dominant_state_2 = fs_2.(context_2).responses_cyan_dominant_state;

                            slopes_state_1 = fs_slope_state_1{session_index_across_sessions}.coefficients_state_1_dominant(2,:)';
                            slopes_state_2 = fs_slope_state_2{session_index_across_sessions}.coefficients_state_2_suppressed(2,:)';
                            intercepts_state_1 = fs_slope_state_1{session_index_across_sessions}.coefficients_state_1_dominant(1,:)';
                            intercepts_state_2 = fs_slope_state_2{session_index_across_sessions}.coefficients_state_2_suppressed(1,:)';
                            mean_state_1 = mean( [mean(mean(responses_red_dominant_state_1,2),3), mean(mean(responses_cyan_dominant_state_1,2),3)],2);
                            mean_state_2 = mean( [mean(mean(responses_red_dominant_state_2,2),3), mean(mean(responses_cyan_dominant_state_2,2),3)],2);
                            % %Use intercept as center (does not make sense because x=0 is not a stimulus):
                            %Use mean as center (recommended):
                            center_state_1 = mean_state_1;
                            center_state_2 = mean_state_2;

                            scale_slope_state_1_to_state_2 = slopes_state_2./slopes_state_1;
                            
                            valid_gain = sign(slopes_state_1) == sign(slopes_state_2);
                            scale_slope_state_1_to_state_2(~valid_gain) = nan;


                            responses_red_dominant_state_1_slope_normalized = ((responses_red_dominant_state_1 - center_state_1).*scale_slope_state_1_to_state_2) + center_state_1;
                            responses_red_dominant_state_2_slope_normalized = responses_red_dominant_state_2; %Leave state 2 alone
                            responses_cyan_dominant_state_1_slope_normalized = ((responses_cyan_dominant_state_1 - center_state_1).*scale_slope_state_1_to_state_2) + center_state_1;
                            responses_cyan_dominant_state_2_slope_normalized = responses_cyan_dominant_state_2; %Leave state 2 alone


                            fs_avg.(context_2).responses_red_dominant_state = (shiftdim(fs_1.(context_2).proportion_red_dominant_state,-1).*responses_red_dominant_state_1_slope_normalized + shiftdim(fs_2.(context_2).proportion_red_dominant_state,-1).*responses_red_dominant_state_2_slope_normalized)./(shiftdim(fs_1.(context_2).proportion_red_dominant_state,-1) + shiftdim(fs_2.(context_2).proportion_red_dominant_state,-1));
                            fs_avg.(context_2).responses_cyan_dominant_state = (shiftdim(fs_1.(context_2).proportion_cyan_dominant_state,-1).*responses_cyan_dominant_state_1_slope_normalized + shiftdim(fs_2.(context_2).proportion_cyan_dominant_state,-1).*responses_cyan_dominant_state_2_slope_normalized)./(shiftdim(fs_1.(context_2).proportion_cyan_dominant_state,-1) + shiftdim(fs_2.(context_2).proportion_cyan_dominant_state,-1));
                            MI = @(x,y) (x-y)./(x+y);
                            fs_avg.(context_2).modulation_indices_state = MI(fs_avg.(context_2).responses_red_dominant_state, fs_avg.(context_2).responses_cyan_dominant_state);
                            modulation_indices_context_2 = fs_avg.(context_2).modulation_indices_state;
                        elseif b_compute_for_state==0
                            modulation_indices_context_2 = fs_1.(context_2).modulation_indices(:,R_1,C_1);
                        end
                        for regions_to_plot_index = 1:length(regions_to_plot)
                            if strcmp(regions_to_plot{regions_to_plot_index},'all')
                                b_selected_region = ismember(fs_1.regions(fs_1.unit_probes_index),regions_to_plot)'; %all of the above.
                            else
                                region_probe_index = find(strcmp(fs_1.regions,regions_to_plot{regions_to_plot_index}));
                                if ~isempty(region_probe_index)
                                    b_selected_region = fs_1.unit_probes_index' == region_probe_index;
                                else
                                    b_selected_region = false(size(fs_1.unit_probes_index'));
                                end
                            end
                            at_least_one_spike = fs_1.(context_2).responses_red_dominant_state(:,R_1,C_1)>0 & fs_1.(context_2).responses_cyan_dominant_state(:,R_1,C_1) & fs_2.(context_2).responses_red_dominant_state(:,R_1,C_1)>0 & fs_2.(context_2).responses_cyan_dominant_state(:,R_1,C_1);
                            b_selected = b_selected_region & (fs_1.(context_significance).responses_p_value(:,R_1,C_1)<0.05) & at_least_one_spike; %Try priming instead!!
                            % The held-out-half restriction avoids circularity for the STATE-conditioned
                            % modulation panels (states inferred from, and modulation measured on, the same
                            % cells). Fig 1h is a CONDITION comparison (unambiguous vs binocular), not
                            % state-conditioned, so it uses the full population (paper: n=5550 cell-stimulus
                            % pairs). The Fig 1h script sets b_use_full_population=1 to skip the filter.
                            if isfield(fs_1,'b_neuron_is_not_for_state_inference') && ~(exist('b_use_full_population','var') && b_use_full_population)
                                b_selected = b_selected & fs_1.b_neuron_is_not_for_state_inference';
                            end

                            modulation_indices_context_1_significant_1{regions_to_plot_index} = [modulation_indices_context_1_significant_1{regions_to_plot_index}; modulation_indices_context_1(b_selected)];
                            modulation_indices_context_2_significant_1{regions_to_plot_index} = [modulation_indices_context_2_significant_1{regions_to_plot_index}; modulation_indices_context_2(b_selected)];
                        end
                    end
                end
            end
        end
    end
end