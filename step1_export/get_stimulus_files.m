function stim_files = get_stimulus_files(pd, stim_root_dir)

% Subdirectory where FOB images are stored
FOB_STIM_DIR = 'Monkey_Bodyparts';

% List of stimulus filenames used for paradigm (might be empty)
stimulus_list = pd.stimulus_list;

% If stimulus list is empty, load file paths from 'pd.xml_filename'
if isempty(stimulus_list)

    % Throw error if there isn't any 'xml_filename' field
    if ~isfield(pd, 'xml_filename')
        error('Stimulus list is empty and no filename is specified')
    end

    % File path to stimulus list
    list_rel_path = get_relative_path_unix(pd.xml_filename);
    list_fpath = [stim_root_dir, '/', list_rel_path];

    % Throw error if stimulus list doesn't exist
    if ~isfile(list_fpath)
        error('Stimulus list does not exist at specified path')
    end

    % File type of stimulus list
    list_ftype = list_fpath(end-3:end);

    % For .txt files, load stimulus file names from lines in file (ignoring
    % the first line, which specifies the number of stimuli) and assume
    % stimulus files are in same directory that list file is
    if strcmp(list_ftype, '.txt')

        % Get relative path to directory containing list file
        list_parts = strsplit(list_rel_path, '/');
        list_rel_dir = strjoin(list_parts(1:end-1), '/');

        % Load list of filenames from path, ignoring first line
        stimulus_list = readcell(list_fpath, 'Delimiter', '\n', 'FileType', 'text');
        stimulus_list = stimulus_list(2:end);

        % Combine list directory with stimulus filenames to get paths
        n_stim = numel(stimulus_list);
        stim_files = cell(1, n_stim);
        for i=1:n_stim
            stim_files{i} = [list_rel_dir, '/', stimulus_list{i}];
        end

    % For .xml files, load stimulus file names from XML object, where each
    % stimulus has a corresponding object in the list at 'Media.Image' or 
    % 'Media.Movie', and the filename of this stimulus is stored in the 
    % 'FileNameAttribute' field of this object.
    elseif strcmp(list_ftype, '.xml')

        % Load XML object and extract list of stimulus structs
        stim_struct_top = readstruct(list_fpath);
        stim_struct = stim_struct_top.Media;
        if isfield(stim_struct, 'Image')
            stim_list = stim_struct.Image;
        elseif isfield(stim_struct, 'Movie')
            stim_list = stim_struct.Movie;
        else
            error('XML file does not contain path to stimulus list')
        end

        % Extract relative stimulus file path from each list entry
        n_stim = numel(stim_list);
        stim_files = cell(1, n_stim);
        for i=1:n_stim
            file_path_orig = stim_list(i).FileNameAttribute;
            stim_files{i} = get_relative_path_unix(file_path_orig);
        end

    % Throw error if list has any type besides '.txt' or '.xml'
    else
        error(['Unable to parse list of type ', list_ftype]);
    end

% If stimulus list is not empty, construct file paths from stimulus list
else

    % FOB paradigm stores stimulus files differently than others: instead
    % of subdirectory with same name as condition, FOB images are in 
    % subdirectory with arbitrary name.
    if strcmp((pd.paradigm_name), 'FOB')
        n_stim = numel(stimulus_list);
        stim_files = cell(1, n_stim);
        for i=1:n_stim
            stim_files{i} = [FOB_STIM_DIR, '/', stimulus_list{i}];
        end

    % Rest of paradigms store stimulus files according to convention
    % filename(i) = '{STIM_ROOT}/{condition}/{stimulus_list(i)}'
    else
        condition_list = pd.condition_list;
        n_stim = numel(stimulus_list);
        stim_files = cell(1, n_stim);
        for i=1:n_stim
            stim_files{i} = [condition_list{i}, '/', stimulus_list{i}];
        end
    end
end

% Check that all stimulus files exist before returning list
for i=1:numel(stim_files)
    full_path = [stim_root_dir, '/', stim_files{i}];
    if ~isfile(full_path)
        error(['Stimulus file ', full_path, ' missing']);
    end
end
end
