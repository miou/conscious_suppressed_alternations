function session = load_example_states_if_missing(session, paradigm_index, si_index)
%LOAD_EXAMPLE_STATES_IF_MISSING  Use the example-trial states shipped with the code if the state
% file of the example session is not in data/python_states.
%   The two Fig. 2 example scripts plot the LLR IT states of session 251218. Its state file comes
%   from the Python pipeline (step 2). If it is missing, this loads example_states_251218_Alfie.mat
%   (next to this function), which holds the states of the samples the example panels plot; all
%   other samples are NaN.
if ~isempty(session.inference_results{paradigm_index, si_index})
    return
end
example_file = fullfile(fileparts(mfilename('fullpath')), 'example_states_251218_Alfie.mat');
example = load(example_file);
assert(strcmp(example.session_name, session.session_name), ...
    'The example states shipped with the code are for session %s, not %s.', example.session_name, session.session_name);
warning('No state file for %s in data/python_states. Using the example-trial states in %s.', ...
    session.session_name, example_file);
state_timecourse = nan(example.state_timecourse_size);
state_timecourse(example.sample_indices) = example.state_values;
session.inference_results{paradigm_index, si_index} = struct('state_timecourse', state_timecourse);
end
