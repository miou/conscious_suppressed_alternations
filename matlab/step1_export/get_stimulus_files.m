function stim_files = get_stimulus_files(pd)
% GET_STIMULUS_FILES  Relative stimulus filenames for one paradigm, built from the paradigm's own
% stored condition_list / stimulus_list (filename(i) = '<condition>/<stimulus>'). These are written
% into the exported HDF5 as metadata only: neither the Python state-inference pipeline nor the
% MATLAB analysis reads the stimulus image pixels, so the stimulus images are not required.

condition_list = pd.condition_list;
stimulus_list  = pd.stimulus_list;
n_stim = numel(stimulus_list);
stim_files = cell(1, n_stim);
for i = 1:n_stim
    stim_files{i} = [condition_list{i}, '/', stimulus_list{i}];
end
end
