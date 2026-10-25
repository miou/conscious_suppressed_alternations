function save_session_h5(session, fname)
% Extracts data from session object and saves to HDF5 

% If session file already exists, delete it so HDF5 can overwrite
if isfile(fname)
    delete(fname);
    disp(['Deleted existing file: ', fname]);
end

% Write session-wide data to file (first dataset write implicitly creates H5 file)

% Index of probe that each unit is recorded from
ds_path = '/unit_probe';
ds_data = int32(session.unit_probes_index);
h5create(fname, ds_path, size(ds_data), 'Datatype', 'int32');
h5write(fname, ds_path, ds_data);

% Kilosort ID of each unit
ds_path = '/unit_id';
ds_data = int32(session.unit_id);
h5create(fname, ds_path, size(ds_data), 'Datatype', 'int32');
h5write(fname, ds_path, ds_data);

% Channel each unit comes from
ds_path = '/unit_channel';
ds_data = int32(session.unit_channel);
h5create(fname, ds_path, size(ds_data), 'Datatype', 'int32');
h5write(fname, ds_path, ds_data);

% Quality of each unit (use standardized version)
ds_path = '/unit_quality';
ds_data = int32(session.standardized.unit_quality);
h5create(fname, ds_path, size(ds_data), 'Datatype', 'int32');
h5write(fname, ds_path, ds_data);

if isfield(session,'waveforms')
    % Waveform for each unit
    ds_path = '/unit_waveform_uv';
    ds_data = session.waveforms.unit_waveform_uV;
    h5create(fname, ds_path, size(ds_data), 'Datatype', 'double');
    h5write(fname, ds_path, ds_data);


    % Waveform time values
    ds_path = '/unit_waveform_time';
    ds_data = session.waveforms.unit_waveform_time;
    h5create(fname, ds_path, size(ds_data), 'Datatype', 'double');
    h5write(fname, ds_path, ds_data);

    % Normalized and shifted waveforms
    ds_path = '/unit_waveform_norm_shift';
    ds_data = session.waveforms.unit_waveform_normalized_shifted;
    h5create(fname, ds_path, size(ds_data), 'Datatype', 'double');
    h5write(fname, ds_path, ds_data);

end

% Name of session
h5writeatt(fname, '/', 'session_name', session.session_name);

% Index number associated with session
h5writeatt(fname, '/', 'session_index', session.session_index);

% Acquisition software 
h5writeatt(fname, '/', 'acquisition_software', session.acquisitionsoftware);

% Number of probes
n_probes = size(session.regions, 2);
h5writeatt(fname, '/', 'n_probes', n_probes);

% Number of units
n_units = size(session.unit_id, 2);
h5writeatt(fname, '/', 'n_units', n_units);

% Probe regions
h5writeatt(fname, '/', 'regions', session.regions);

% Layer directions
layer_direction = int32(cell2mat(session.layer_direction));
h5writeatt(fname, '/', 'layer_direction', layer_direction);

% Write paradigm data to file
for i = 1:numel(session.paradigms_data)

    % Ignore empty cells in paradigms_data array
    if isempty(session.paradigms_data{i})
        continue;
    end
   
    % Get data, name and H5 group path for paradigm
    pd = session.paradigms_data{i};
    pd_std = session.standardized.paradigms_data{i};
    if isempty(pd_std)
        continue;
    end
    name = pd.paradigm_name;
    group_path = sprintf('/paradigms/%s', name);

    % Spike data for paradigm (dataset write creates paradigm group)
    ds_path = sprintf('%s/timecourse_all_units', group_path);
    ds_data = uint8(pd.timecourse_all_units'); % Save transpose
    h5create(fname, ds_path, size(ds_data), 'Datatype', 'uint8');
    h5write(fname, ds_path, ds_data);

    % Paradigm name
    h5writeatt(fname, group_path, 'paradigm_name', pd.paradigm_name);

    % Target on duration
    h5writeatt(fname, group_path, 'on_duration', int32(pd.on_duration));

    % Target off duration
    h5writeatt(fname, group_path, 'off_duration', int32(pd.off_duration));

    % Trial on durations
    ds_path = sprintf('%s/on_durations', group_path);
    ds_data = int32(pd.on_durations);
    h5create(fname, ds_path, size(ds_data), 'Datatype', 'int32');
    h5write(fname, ds_path, ds_data);

    % Trial off durations
    ds_path = sprintf('%s/off_durations', group_path);
    ds_data = int32(pd.off_durations);
    h5create(fname, ds_path, size(ds_data), 'Datatype', 'int32');
    h5write(fname, ds_path, ds_data);

    % Total trial durations
    ds_path = sprintf('%s/trial_durations', group_path);
    ds_data = int32(pd.trial_durations);
    h5create(fname, ds_path, size(ds_data), 'Datatype', 'int32');
    h5write(fname, ds_path, ds_data);

    % Trial on times (convert to Python indexing)
    ds_path = sprintf('%s/timecourse_on_times', group_path);
    timecourse_on_times_python = pd.timecourse_on_times - 1;
    ds_data = int64(timecourse_on_times_python);
    h5create(fname, ds_path, size(ds_data), 'Datatype', 'int64');
    h5write(fname, ds_path, ds_data);

    % Trial off times (convert to Python indexing)
    ds_path = sprintf('%s/timecourse_off_times', group_path);
    timecourse_off_times_python = pd.timecourse_off_times - 1;
    ds_data = int64(timecourse_off_times_python);
    h5create(fname, ds_path, size(ds_data), 'Datatype', 'int64');
    h5write(fname, ds_path, ds_data);

    % Trial on times in kilosort (i.e. wall clock) recording time
    ds_path = sprintf('%s/timecourse_on_times_ks', group_path);
    ks_times = pd_std.timecourse_on_times_ks;
    h5create(fname, ds_path, size(ks_times), 'Datatype', 'double');
    h5write(fname, ds_path, ks_times);

    % Eye position x-coordinate
    ds_path = sprintf('%s/eyex_timecourse', group_path);
    ds_data = pd.eyex_timecourse;
    h5create(fname, ds_path, size(ds_data), 'Datatype', 'double');
    h5write(fname, ds_path, ds_data);

    % Eye position y-coordinate
    ds_path = sprintf('%s/eyey_timecourse', group_path);
    ds_data = pd.eyey_timecourse;
    h5create(fname, ds_path, size(ds_data), 'Datatype', 'double');
    h5write(fname, ds_path, ds_data);

    % Photodiode timecourse (not present in all sessions)
    if ~isempty(pd.photodiode_timecourse)
        ds_path = sprintf('%s/photodiode_timecourse', group_path);
        ds_data = pd.photodiode_timecourse;
        h5create(fname, ds_path, size(ds_data), 'Datatype', 'double');
        h5write(fname, ds_path, ds_data);
    end

    % Stimulus index for each trial
    ds_path = sprintf('%s/stimulus_index_valid', group_path);
    stimulus_index_valid_python = pd.stimulus_index_valid - 1;
    ds_data = int32(stimulus_index_valid_python);
    h5create(fname, ds_path, size(ds_data), 'Datatype', 'int32');
    h5write(fname, ds_path, ds_data);

    % List of stimulus files
    ds_path = sprintf('%s/stimulus_files', group_path);
    ds_data = string(pd_std.stimulus_files);
    h5create(fname, ds_path, size(ds_data), 'Datatype', 'string');
    h5write(fname, ds_path, ds_data);

    % Write face/object labels for labeled paradigms
    pd_labeled = {
        'FOB';
        'physical_switches_static';
        'no_report_v3_physical_switches';
        'physical_switches_static_triplets';
        'no_report_v3_physical_switches_triplets'
    };
    if ismember(name, pd_labeled)

        % Indicator: Equal to 1 if trial is face trial
    	ds_path = sprintf('%s/trial_is_face', group_path);
    	ds_data = uint8(pd.trial_is_face);
    	h5create(fname, ds_path, size(ds_data), 'Datatype', 'uint8');
    	h5write(fname, ds_path, ds_data);

	    % Indicator: Equal to 1 if trial is object trial (inverse of above)
    	ds_path = sprintf('%s/trial_is_object', group_path);
    	ds_data = uint8(pd.trial_is_object);
    	h5create(fname, ds_path, size(ds_data), 'Datatype', 'uint8');
    	h5write(fname, ds_path, ds_data);
    end

    % Write fixation points and inferred percepts for rivalry no-report paradigms
    pd_brn = {
        'no_report_v3_binocular_rivalry';
        'no_report_v3_binocular_rivalry_triplets';
    };
    if ismember(name, pd_brn)

        % List of all fixation points (x- and y-values)
        ds_path = sprintf('%s/fix_positions', group_path);
        ds_data = pd_std.fix_positions'; % Save transpose
        h5create(fname, ds_path, size(ds_data), 'Datatype', 'double');
        h5write(fname, ds_path, ds_data);

        % Index identifying fixation point in face stimulus
        ds_path = sprintf('%s/face_fix_positions_index', group_path);
        face_fix_positions_index_python = pd_std.face_fix_positions_index - 1;
        ds_data = int32(face_fix_positions_index_python);
        h5create(fname, ds_path, size(ds_data), 'Datatype', 'int32');
        h5write(fname, ds_path, ds_data);

        % Index identifying fixation point in object stimulus
        ds_path = sprintf('%s/object_fix_positions_index', group_path);
        object_fix_positions_index_python = pd_std.object_fix_positions_index - 1;
        ds_data = int32(object_fix_positions_index_python);
        h5create(fname, ds_path, size(ds_data), 'Datatype', 'int32');
        h5write(fname, ds_path, ds_data);

        % Indicator: Equal to 1 if monkey is fixating on some point during trial
    	ds_path = sprintf('%s/trials_fixated', group_path);
    	ds_data = uint8(pd_std.trials_fixated);
    	h5create(fname, ds_path, size(ds_data), 'Datatype', 'uint8');
    	h5write(fname, ds_path, ds_data);

	    % Indicator: Equal to 1 if monkey is fixating on face point during trial
    	ds_path = sprintf('%s/trials_fixated_face', group_path);
    	ds_data = uint8(pd_std.trials_fixated_face);
    	h5create(fname, ds_path, size(ds_data), 'Datatype', 'uint8');
    	h5write(fname, ds_path, ds_data);

	    % Indicator: Equal to 1 if monkey is fixating on object point during trial
    	ds_path = sprintf('%s/trials_fixated_object', group_path);
    	ds_data = uint8(pd_std.trials_fixated_object);
    	h5create(fname, ds_path, size(ds_data), 'Datatype', 'uint8');
    	h5write(fname, ds_path, ds_data);

	    % Indicator: "Good" face trials
    	ds_path = sprintf('%s/good_face_trial', group_path);
    	ds_data = uint8(pd_std.good_face_trial);
    	h5create(fname, ds_path, size(ds_data), 'Datatype', 'uint8');
    	h5write(fname, ds_path, ds_data);

	    % Indicator: "Good" object trials
    	ds_path = sprintf('%s/good_object_trial', group_path);
    	ds_data = uint8(pd_std.good_object_trial);
    	h5create(fname, ds_path, size(ds_data), 'Datatype', 'uint8');
    	h5write(fname, ds_path, ds_data);
    end

    % Write fixation points and inferred percepts for physical switches no-report paradigms
    pd_psn = {
        'no_report_v3_physical_switches'; 
        'no_report_v3_physical_switches_triplets';
    };
    if ismember(name, pd_psn)

        % List of all fixation points (x- and y-values)
        ds_path = sprintf('%s/fix_positions', group_path);
        ds_data = pd_std.fix_positions'; % Save transpose
        h5create(fname, ds_path, size(ds_data), 'Datatype', 'double');
        h5write(fname, ds_path, ds_data);

        % Index identifying fixation point in stimulus
        ds_path = sprintf('%s/fix_positions_index', group_path);
        fix_positions_index_python = pd_std.fix_positions_index - 1;
        ds_data = int32(fix_positions_index_python);
        h5create(fname, ds_path, size(ds_data), 'Datatype', 'int32');
        h5write(fname, ds_path, ds_data);
    end

    % Write variables for flash suppression paradigms
    pd_fs = {
        'flash_suppression_many_stimuli';
        'flash_suppression_many_stimuli_transparent';
        'flash_suppression_optimized';
        'flash_suppression_optimized_repeat_subset';
    };
    if ismember(name, pd_fs)

        pdfs = pd.flash_suppression;

        % Indicator: Priming trials
    	  ds_path = sprintf('%s/trial_is_priming', group_path);
    	  ds_data = uint8(pdfs.trial_is_priming);
    	  h5create(fname, ds_path, size(ds_data), 'Datatype', 'uint8');
    	  h5write(fname, ds_path, ds_data);

        % Indicator: Binocular trials
    	  ds_path = sprintf('%s/trial_is_binocular', group_path);
    	  ds_data = uint8(pdfs.trial_is_binocular);
    	  h5create(fname, ds_path, size(ds_data), 'Datatype', 'uint8');
    	  h5write(fname, ds_path, ds_data);

        % Indicator: Transparent trials
    	  ds_path = sprintf('%s/trial_is_transparent', group_path);
    	  ds_data = uint8(pdfs.trial_is_transparent);
    	  h5create(fname, ds_path, size(ds_data), 'Datatype', 'uint8');
    	  h5write(fname, ds_path, ds_data);

        % Indicator: Unambiguous trials
    	  ds_path = sprintf('%s/trial_is_unambiguous', group_path);
    	  ds_data = uint8(pdfs.trial_is_unambiguous);
    	  h5create(fname, ds_path, size(ds_data), 'Datatype', 'uint8');
    	  h5write(fname, ds_path, ds_data);
    	
        % Indicator: Gray trials
    	  ds_path = sprintf('%s/trial_is_gray', group_path);
    	  ds_data = uint8(pdfs.trial_is_gray);
    	  h5create(fname, ds_path, size(ds_data), 'Datatype', 'uint8');
    	  h5write(fname, ds_path, ds_data);

    	  % Indicator: Red stimuli
    	  ds_path = sprintf('%s/priming_stimulus_is_red', group_path);
    	  ds_data = uint8(pdfs.priming_stimuli_list_is_red);
    	  h5create(fname, ds_path, size(ds_data), 'Datatype', 'uint8');
    	  h5write(fname, ds_path, ds_data);

    	  % Indicator: Cyan stimuli
    	  ds_path = sprintf('%s/priming_stimulus_is_cyan', group_path);
    	  ds_data = uint8(pdfs.priming_stimuli_list_is_cyan);
    	  h5create(fname, ds_path, size(ds_data), 'Datatype', 'uint8');
    	  h5write(fname, ds_path, ds_data);

        % Index of dominant image for each trial (NaNs become -1)
        index_int = pdfs.trial_dominant_image_index;
        index_int(isnan(index_int)) = 0;
        index_int = int32(index_int);
        index_int_python = index_int - 1;
    	  ds_path = sprintf('%s/trial_dominant_image_index', group_path);
    	  ds_data = index_int_python;
    	  h5create(fname, ds_path, size(ds_data), 'Datatype', 'int32');
    	  h5write(fname, ds_path, ds_data);

        % Index of suppressed image for each trial (NaNs become -1)
        index_int = pdfs.trial_suppressed_image_index;
        index_int(isnan(index_int)) = 0;
        index_int = int32(index_int);
        index_int_python = index_int - 1;
    	  ds_path = sprintf('%s/trial_suppressed_image_index', group_path);
    	  ds_data = index_int_python;
    	  h5create(fname, ds_path, size(ds_data), 'Datatype', 'int32');
    	  h5write(fname, ds_path, ds_data);

        % Average responses for all stimuli
    	  ds_path = sprintf('%s/responses_priming', group_path);
    	  ds_data = pdfs.responses_priming'; % Save transpose
    	  h5create(fname, ds_path, size(ds_data), 'Datatype', 'double');
    	  h5write(fname, ds_path, ds_data);

    end
end
