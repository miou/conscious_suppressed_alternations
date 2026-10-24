function rel_path = get_relative_path_unix(orig_path)

% Names of stimulus root directory used on original machine (must occur 
% only once in filename, or function will return an error)
STIM_ROOT_ORIG_1 = 'StimulusSet';
STIM_ROOT_ORIG_2 = 'stimulusset';

% Figure out which stimulus root directory is in original path
if contains(orig_path, STIM_ROOT_ORIG_1)
    stim_root_orig = STIM_ROOT_ORIG_1;
elseif contains(orig_path, STIM_ROOT_ORIG_2)
    stim_root_orig = STIM_ROOT_ORIG_2;
else
   error('Stimulus root directory does not occur in path')
end

% Extract part of path that occurs after stimulus set root directory
path_parts = strsplit(orig_path, stim_root_orig);
if numel(path_parts) ~= 2
    error('Stimulus root directory name occurs more than once in path')
end
rel_path_win = path_parts{2};

% Convert to Unix-style path and return
rel_path = strrep(rel_path_win, '\', '/');

% Remove leading slash to avoid confusion
if strcmp(rel_path(1), '/')
    rel_path = rel_path(2:end);
end
end