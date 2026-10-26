function [inference_schemes, inference_results] = switches_infer_states(rivalry_config,session)
% SWITCHES_INFER_STATES  Attach the conscious/suppressed state partition to a session.
%
% Returns the release's state-inference schemes and, for each (paradigm, scheme),
% the inferred state time course. States are not computed here: they were produced
% by the Python LLR/HMM pipeline (step 2) and are loaded from paths.conor_states by
% state_method_hmm. This function just defines which schemes to load and calls it.
%
% Each scheme is one row of the table below. The fields that matter downstream:
%   name         human-readable key; this is how figures/configs select a scheme
%                (via states_to_use.inference_scheme), so the NAME is the real id.
%   method       dispatch key for how the states are obtained. All release schemes
%                use 'load_python_states' (states precomputed in Python, loaded on
%                attach). hmm_method is what actually distinguishes the variants.
%   hmm_method   'llr' (per-bin log-likelihood ratio), 'unit_subset_control'
%                (LLR on one neuron half, for the cross-neuron control), or
%                'fixed_hmm' (per-patch fixed-rate HMM, for dwell / cross-patch).
%   regions_to_include   which recorded areas the scheme's states come from.

inference_schemes = struct();

if strcmp(rivalry_config.analysis_name,'Analysis_Rivalry')

    % ---- LLR schemes (per-bin log-likelihood-ratio state inference) ----
    si_index = 1; % IT
    inference_schemes(si_index).name = 'Fixed rate LLR IT 10 ms';
    inference_schemes(si_index).method = 'load_python_states';
    inference_schemes(si_index).hmm_method = 'llr';
    inference_schemes(si_index).features = {'spikes'};
    inference_schemes(si_index).hmm_type = 'llr_fs';
    inference_schemes(si_index).selection_scheme = 'all';
    inference_schemes(si_index).regions_to_include = {'ML','AM'};
    inference_schemes(si_index).bin_size = 10;

    si_index = 2; % IT half neurons
    inference_schemes(si_index).name = 'Fixed rate LLR IT 10 ms half neurons';
    inference_schemes(si_index).method = 'load_python_states';
    inference_schemes(si_index).hmm_method = 'unit_subset_control';
    inference_schemes(si_index).features = {'spikes'};
    inference_schemes(si_index).hmm_type = 'llr_fs';
    inference_schemes(si_index).selection_scheme = 'all';
    inference_schemes(si_index).regions_to_include = {'ML','AM'};
    inference_schemes(si_index).bin_size = 10;

    si_index = 3; % PFC (PO/PA/PVL)
    inference_schemes(si_index).name = 'Fixed rate LLR PFC 10 ms';
    inference_schemes(si_index).method = 'load_python_states';
    inference_schemes(si_index).hmm_method = 'llr';
    inference_schemes(si_index).features = {'spikes'};
    inference_schemes(si_index).hmm_type = 'llr_fs';
    inference_schemes(si_index).selection_scheme = 'all';
    inference_schemes(si_index).regions_to_include = {'PO','PA','PVL','PFC'};
    inference_schemes(si_index).bin_size = 10;

    si_index = 4; % PFC half neurons
    inference_schemes(si_index).name = 'Fixed rate LLR PFC 10 ms half neurons';
    inference_schemes(si_index).method = 'load_python_states';
    inference_schemes(si_index).hmm_method = 'unit_subset_control';
    inference_schemes(si_index).features = {'spikes'};
    inference_schemes(si_index).hmm_type = 'llr_fs';
    inference_schemes(si_index).selection_scheme = 'all';
    inference_schemes(si_index).regions_to_include = {'PO','PA','PVL','PFC'};
    inference_schemes(si_index).bin_size = 10;

    % ---- HMM schemes (per-patch Hidden Markov Model, for dwell / cross-patch) ----
    si_index = 5; % ML only
    inference_schemes(si_index).name = 'Fixed rate HMM ML';
    inference_schemes(si_index).method = 'load_python_states';
    inference_schemes(si_index).hmm_method = 'fixed_hmm';
    inference_schemes(si_index).features = {'spikes'};
    inference_schemes(si_index).hmm_type = 'fixed_hmm_fs';
    inference_schemes(si_index).probe_index = [];
    inference_schemes(si_index).regions_to_include = {'ML'};

    si_index = 6; % AM only
    inference_schemes(si_index).name = 'Fixed rate HMM AM';
    inference_schemes(si_index).method = 'load_python_states';
    inference_schemes(si_index).hmm_method = 'fixed_hmm';
    inference_schemes(si_index).features = {'spikes'};
    inference_schemes(si_index).hmm_type = 'fixed_hmm_fs';
    inference_schemes(si_index).probe_index = [];
    inference_schemes(si_index).regions_to_include = {'AM'};

end


%% Do inference
inference_results = cell(length(rivalry_config.paradigms),length(inference_schemes));

for paradigm_index = 1:length(session.paradigms_data)

    if ~isempty(session.paradigms_data{paradigm_index})

        %Infer states in neural activity
        for si_index = 1:length(inference_schemes)
            if isfield(inference_schemes(si_index),'name') && ~isempty(inference_schemes(si_index).name)
                switch inference_schemes(si_index).method
                    case 'load_python_states'
                        if contains(session.paradigm_names{paradigm_index},'flash_suppression')
                            inference_results{paradigm_index,si_index} = state_method_hmm(inference_schemes(si_index),session,paradigm_index);
                        end
                    case 'stimulus_population_similarity'
                        % Not used by any release scheme; kept for reference/extension.
                        if contains(session.paradigm_names{paradigm_index},'flash_suppression')
                            inference_results{paradigm_index,si_index} = state_method_stimulus_population_similarity(inference_schemes(si_index),session,paradigm_index);
                        end
                end
            end
        end
    end
end
end
