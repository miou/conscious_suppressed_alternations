function session = add_standardized_vars(session, stim_root_dir)

% Create struct to store all standardized variables in
std = struct();

% Put unit quality field into common format
if iscell(session.unit_quality)
    n_units = size(session.unit_id, 2);
    unit_q = zeros(1, n_units);
    for i=1:n_units
        if strcmp(session.unit_quality(i), 'mua')
            unit_q(i) = 1;
        elseif strcmp(session.unit_quality(i), 'good')
            unit_q(i) = 2;
        else
            error('Unknown unit quality string')
        end
    end
    std.unit_quality = unit_q;
else
    std.unit_quality = session.unit_quality;
end

% Standardized variables for paradigms
n_paradigms = numel(session.paradigms_data);
std.paradigms_data = cell(n_paradigms, 1);
for i=1:n_paradigms

    % Ignore empty cells in paradigms_data array
    if isempty(session.paradigms_data{i})
        continue;
    end

    % Structs for original paradigm data and standardized variables
    pd = session.paradigms_data{i};
    if ~strcmp(pd.paradigm_name,'monkey_face_1500')
        pd_std = struct();

        % List of unambiguous stimulus files
        pd_std.stimulus_files = get_stimulus_files(pd, stim_root_dir);

        % Trial on times in kilosort (i.e. wall clock) time
        if iscell(pd.debug.timecourse_on_times_in_kilosort_recording_time)
            % If variable is cell array with times for both probes, use probe 1
            pd_std.timecourse_on_times_ks = pd.debug.timecourse_on_times_in_kilosort_recording_time{1};
        else
            % Otherwise, use single array that they give us
            pd_std.timecourse_on_times_ks = pd.debug.timecourse_on_times_in_kilosort_recording_time;
        end

        % Fixation points and inferred percepts for no-report rivalry paradigms
        brn_paradigms = {
            'no_report_v3_binocular_rivalry';
            'no_report_v3_binocular_rivalry_triplets'
            };
        if ismember(pd.paradigm_name, brn_paradigms)
            % Get fixation points
            [fix_positions, face_fix_positions_index, object_fix_positions_index,~,~] = define_no_report_paradigm(pd.paradigm_name);
            % Add to paradigm data
            pd_std.fix_positions = fix_positions;
            pd_std.face_fix_positions_index = face_fix_positions_index;
            pd_std.object_fix_positions_index = object_fix_positions_index;
            % Infer percepts
            session = infer_percept_mod(session, pd); % Function writes output to session object
            percepts = session.inferred_percepts(i); % Copy function output
            session = rmfield(session, 'inferred_percepts'); % Remove output to make sure we don't accidentally copy it later
            [b_good_face_trial, b_good_object_trial] = make_inferred_percepts_stringent(percepts, 1, 1);
            % Add fields to paradigm data
            pd_std.trials_fixated = percepts.b_trials_fixated;
            pd_std.trials_fixated_face = percepts.b_trials_fixated_face;
            pd_std.trials_fixated_object = percepts.b_trials_fixated_object;
            pd_std.good_face_trial = b_good_face_trial;
            pd_std.good_object_trial = b_good_object_trial;
        end

        % Fixation points for physical switches no-report paradigms
        psn_paradigms = {
            'no_report_v3_physical_switches';
            'no_report_v3_physical_switches_triplets';
            };
        if ismember(pd.paradigm_name, psn_paradigms)
            % Get fixation points
            [fix_positions, face_fix_positions_index, object_fix_positions_index,~,~] = define_no_report_paradigm(pd.paradigm_name);
            % Combine into single array (choose whatever value isn't NaN)
            n_vals = size(face_fix_positions_index, 1);
            fix_positions_index = zeros(n_vals, 1);
            for j = 1:n_vals
                if isnan(face_fix_positions_index(j))
                    fix_positions_index(j) = object_fix_positions_index(j);
                else
                    fix_positions_index(j) = face_fix_positions_index(j);
                end
            end
            % Add to paradigm data
            pd_std.fix_positions = fix_positions;
            pd_std.fix_positions_index = fix_positions_index;
        end

        % Add standardized paradigm fields to list
        std.paradigms_data{i} = pd_std;
    end

end
% Add standardized variables to session and return
session.standardized = std;
