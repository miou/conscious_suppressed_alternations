function session = add_standardized_vars(session)

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
        pd_std.stimulus_files = get_stimulus_files(pd);

        % Trial on times in kilosort (i.e. wall clock) time
        if iscell(pd.debug.timecourse_on_times_in_kilosort_recording_time)
            % If variable is cell array with times for both probes, use probe 1
            pd_std.timecourse_on_times_ks = pd.debug.timecourse_on_times_in_kilosort_recording_time{1};
        else
            % Otherwise, use single array that they give us
            pd_std.timecourse_on_times_ks = pd.debug.timecourse_on_times_in_kilosort_recording_time;
        end

        % Add standardized paradigm fields to list
        std.paradigms_data{i} = pd_std;
    end

end
% Add standardized variables to session and return
session.standardized = std;
