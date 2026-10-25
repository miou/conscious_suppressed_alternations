function [inference_schemes, inference_results] = switches_infer_states(data,session);

inference_schemes = struct();

if strcmp(data.analysis_name,'Analysis_Rivalry')

    % ---- LLR schemes (per-bin log-likelihood-ratio state inference) ----
    si_index = 50; % IT
    inference_schemes(si_index).name = 'Fixed rate LLR IT 10 ms';
    inference_schemes(si_index).method = 'hmm'; %Loads data processed in Python
    inference_schemes(si_index).hmm_method = 'llr';
    inference_schemes(si_index).features = {'spikes'};
    inference_schemes(si_index).hmm_type = 'llr_fs';
    inference_schemes(si_index).selection_scheme = 'all';
    inference_schemes(si_index).regions_to_include = {'ML','AM'};
    inference_schemes(si_index).bin_size = 10;

    si_index = 52; % IT half neurons
    inference_schemes(si_index).name = 'Fixed rate LLR IT 10 ms half neurons';
    inference_schemes(si_index).method = 'hmm'; %Loads data processed in Python
    inference_schemes(si_index).hmm_method = 'unit_subset_control';
    inference_schemes(si_index).features = {'spikes'};
    inference_schemes(si_index).hmm_type = 'llr_fs';
    inference_schemes(si_index).selection_scheme = 'all';
    inference_schemes(si_index).regions_to_include = {'ML','AM'};
    inference_schemes(si_index).bin_size = 10;

    si_index = 70; % PFC (PO/PA/PVL)
    inference_schemes(si_index).name = 'Fixed rate LLR PFC 10 ms';
    inference_schemes(si_index).method = 'hmm'; %Loads data processed in Python
    inference_schemes(si_index).hmm_method = 'llr';
    inference_schemes(si_index).features = {'spikes'};
    inference_schemes(si_index).hmm_type = 'llr_fs';
    inference_schemes(si_index).selection_scheme = 'all';
    inference_schemes(si_index).regions_to_include = {'PO','PA','PVL','PFC'};
    inference_schemes(si_index).bin_size = 10;

    si_index = 72; % PFC half neurons
    inference_schemes(si_index).name = 'Fixed rate LLR PFC 10 ms half neurons';
    inference_schemes(si_index).method = 'hmm'; %Loads data processed in Python
    inference_schemes(si_index).hmm_method = 'unit_subset_control';
    inference_schemes(si_index).features = {'spikes'};
    inference_schemes(si_index).hmm_type = 'llr_fs';
    inference_schemes(si_index).selection_scheme = 'all';
    inference_schemes(si_index).regions_to_include = {'PO','PA','PVL','PFC'};
    inference_schemes(si_index).bin_size = 10;

    % ---- HMM schemes (per-patch Hidden Markov Model, for dwell / cross-patch) ----
    si_index = 61; % ML only
    inference_schemes(si_index).name = 'Fixed rate HMM ML';
    inference_schemes(si_index).method = 'hmm'; %Loads data processed in Python
    inference_schemes(si_index).hmm_method = 'fixed_hmm';
    inference_schemes(si_index).features = {'spikes'};
    inference_schemes(si_index).hmm_type = 'fixed_hmm_fs';
    inference_schemes(si_index).probe_index = [];
    inference_schemes(si_index).regions_to_include = {'ML'};

    si_index = 62; % AM only
    inference_schemes(si_index).name = 'Fixed rate HMM AM';
    inference_schemes(si_index).method = 'hmm'; %Loads data processed in Python
    inference_schemes(si_index).hmm_method = 'fixed_hmm';
    inference_schemes(si_index).features = {'spikes'};
    inference_schemes(si_index).hmm_type = 'fixed_hmm_fs';
    inference_schemes(si_index).probe_index = [];
    inference_schemes(si_index).regions_to_include = {'AM'};

end


%% Do inference
inference_results = cell(length(data.paradigms),length(inference_schemes));

for paradigm_index = 1:length(session.paradigms_data)

    if ~isempty(session.paradigms_data{paradigm_index})

        %Infer states in neural activity
        for si_index = 1:length(inference_schemes)
            if isfield(inference_schemes(si_index),'name') && ~isempty(inference_schemes(si_index).name)
                switch inference_schemes(si_index).method
                    case 'stimulus_population_similarity'
                        if contains(session.paradigm_names{paradigm_index},'flash_suppression')
                            inference_results{paradigm_index,si_index} = state_method_stimulus_population_similarity(inference_schemes(si_index),session,paradigm_index);
                        end
                    case 'reconstruction_similarity'
                        if contains(session.paradigm_names{paradigm_index},'flash_suppression')
                            inference_results{paradigm_index,si_index} = state_method_reconstruction_similarity(inference_schemes(si_index),session,paradigm_index);
                        end
                    case 'decoder'
                        if contains(session.paradigm_names{paradigm_index},'flash_suppression')
                            inference_results{paradigm_index,si_index} = state_method_decoder(inference_schemes(si_index),session,paradigm_index);
                        end
                    case 'hmm'
                        if contains(session.paradigm_names{paradigm_index},'flash_suppression')
                            inference_results{paradigm_index,si_index} = state_method_hmm(inference_schemes(si_index),session,paradigm_index);
                        end
                end
            end
        end
    end
end
end
