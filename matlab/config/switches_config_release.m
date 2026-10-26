function rivalry_config = switches_config_release()
%SWITCHES_CONFIG_RELEASE  The 19 recording sessions used in the paper.
%  Indexed 1..19: sessions 1-10 are the many_combinations sessions, 11-19 are
%  the many_faces sessions. Each session is a file
%  'session_<date>_<monkey>.mat' in paths.sessions.

paths = set_paths;

rivalry_config = struct();
rivalry_config.data_path = paths.sessions;
rivalry_config = define_analysis_rivalry(rivalry_config);

rivalry_config.lfp_filter_band = [3 9];
rivalry_config.channel_prefix = '_Ch_';
rivalry_config.unit_prefix = '_Unit_';
rivalry_config.Ch_Unit_num_digits = 3; %e.g. 001.

% Analysis windows (ms relative to stimulus onset), shared by the step-3 drivers
rivalry_config.time_window_priming   = [300 1000];
rivalry_config.time_window_binocular = [300 1000];
rivalry_config.trial_time_window     = 300:1000;

rivalry_config.sessions = struct;

% ------------------------- many_combinations sessions ------------------------
session_index = 1;
rivalry_config.sessions(session_index).session_name = 'session_250225_Alfie';
rivalry_config.sessions(session_index).acquisitionsoftware= 'spikeglx';
rivalry_config.sessions(session_index).regions = {'ML','AM'}; rivalry_config.sessions(session_index).layer_direction = {1,-1};

session_index = 2;
rivalry_config.sessions(session_index).session_name = 'session_250312_Alfie';
rivalry_config.sessions(session_index).acquisitionsoftware= 'spikeglx';
rivalry_config.sessions(session_index).regions = {'ML','AM'}; rivalry_config.sessions(session_index).layer_direction = {1,-1};

session_index = 3;
rivalry_config.sessions(session_index).session_name = 'session_250317_Alfie';
rivalry_config.sessions(session_index).acquisitionsoftware= 'spikeglx';
rivalry_config.sessions(session_index).regions = {'ML','AM'}; rivalry_config.sessions(session_index).layer_direction = {1,-1};

session_index = 4;
rivalry_config.sessions(session_index).session_name = 'session_250321_Alfie';
rivalry_config.sessions(session_index).acquisitionsoftware= 'spikeglx';
rivalry_config.sessions(session_index).regions = {'ML','AM'}; rivalry_config.sessions(session_index).layer_direction = {1,-1};

session_index = 5;
rivalry_config.sessions(session_index).session_name = 'session_250504_Mowgli';
rivalry_config.sessions(session_index).acquisitionsoftware= 'spikeglx';
rivalry_config.sessions(session_index).regions = {'ML','AM'}; rivalry_config.sessions(session_index).layer_direction = {1,-1};

session_index = 6;
rivalry_config.sessions(session_index).session_name = 'session_250513_Alfie';
rivalry_config.sessions(session_index).acquisitionsoftware= 'spikeglx';
rivalry_config.sessions(session_index).regions = {'ML','SC'}; rivalry_config.sessions(session_index).layer_direction = {1,-1};

session_index = 7;
rivalry_config.sessions(session_index).session_name = 'session_250518_Mowgli';
rivalry_config.sessions(session_index).acquisitionsoftware= 'spikeglx';
rivalry_config.sessions(session_index).regions = {'ML','AM'}; rivalry_config.sessions(session_index).layer_direction = {1,-1};

session_index = 8;
rivalry_config.sessions(session_index).session_name = 'session_250604_Alfie';
rivalry_config.sessions(session_index).acquisitionsoftware= 'spikeglx';
rivalry_config.sessions(session_index).regions = {'ML','SC'}; rivalry_config.sessions(session_index).layer_direction = {1,-1};

session_index = 9;
rivalry_config.sessions(session_index).session_name = 'session_250615_Alfie';
rivalry_config.sessions(session_index).acquisitionsoftware= 'spikeglx';
rivalry_config.sessions(session_index).regions = {'ML','PO'}; rivalry_config.sessions(session_index).layer_direction = {1,-1};

session_index = 10;
rivalry_config.sessions(session_index).session_name = 'session_260210_Mowgli';
rivalry_config.sessions(session_index).acquisitionsoftware= 'spikeglx';
rivalry_config.sessions(session_index).regions = {'ML','PVL'}; rivalry_config.sessions(session_index).layer_direction = {1,1};

% ---------------------------- many_faces sessions ----------------------------
session_index = 11;
rivalry_config.sessions(session_index).session_name = 'session_251212_Alfie';
rivalry_config.sessions(session_index).acquisitionsoftware= 'spikeglx';
rivalry_config.sessions(session_index).regions = {'ML','AM'}; rivalry_config.sessions(session_index).layer_direction = {1,-1};

session_index = 12;
rivalry_config.sessions(session_index).session_name = 'session_251218_Alfie';
rivalry_config.sessions(session_index).acquisitionsoftware= 'spikeglx';
rivalry_config.sessions(session_index).regions = {'ML','AM'}; rivalry_config.sessions(session_index).layer_direction = {1,-1};

session_index = 13;
rivalry_config.sessions(session_index).session_name = 'session_260108_Mowgli';
rivalry_config.sessions(session_index).acquisitionsoftware= 'spikeglx';
rivalry_config.sessions(session_index).regions = {'ML','AM'}; rivalry_config.sessions(session_index).layer_direction = {1,-1};

session_index = 14;
rivalry_config.sessions(session_index).session_name = 'session_260119_Alfie';
rivalry_config.sessions(session_index).acquisitionsoftware= 'spikeglx';
rivalry_config.sessions(session_index).regions = {'ML','AM'}; rivalry_config.sessions(session_index).layer_direction = {1,-1};

session_index = 15;
rivalry_config.sessions(session_index).session_name = 'session_260205_Mowgli';
rivalry_config.sessions(session_index).acquisitionsoftware= 'spikeglx';
rivalry_config.sessions(session_index).regions = {'ML','AM','PVL'}; rivalry_config.sessions(session_index).layer_direction = {1,-1,1};

session_index = 16;
rivalry_config.sessions(session_index).session_name = 'session_260218_Mowgli';
rivalry_config.sessions(session_index).acquisitionsoftware= 'spikeglx';
rivalry_config.sessions(session_index).regions = {'ML','AM','PVL'}; rivalry_config.sessions(session_index).layer_direction = {1,-1,1};

session_index = 17;
rivalry_config.sessions(session_index).session_name = 'session_260225_Mowgli';
rivalry_config.sessions(session_index).acquisitionsoftware= 'spikeglx';
rivalry_config.sessions(session_index).regions = {'ML','AM','PVL'}; rivalry_config.sessions(session_index).layer_direction = {1,-1,1};

session_index = 18;
rivalry_config.sessions(session_index).session_name = 'session_260309_Alfie';
rivalry_config.sessions(session_index).acquisitionsoftware= 'spikeglx';
rivalry_config.sessions(session_index).regions = {'ML','PO','PVL'}; rivalry_config.sessions(session_index).layer_direction = {1,-1,1};

session_index = 19;
rivalry_config.sessions(session_index).session_name = 'session_260322_Alfie';
rivalry_config.sessions(session_index).acquisitionsoftware= 'spikeglx';
rivalry_config.sessions(session_index).regions = {'ML','PO','PVL'}; rivalry_config.sessions(session_index).layer_direction = {1,-1,1};

% Paradigm group per session (lets the step-3 drivers select without loading):
%   many_combinations = all-combinations/unambiguous paradigm (modulation indices)
%   many_faces        = many-stimuli reconstruction paradigm (reconstruction/axes)
for session_index = 1:10;  rivalry_config.sessions(session_index).group = 'many_combinations'; end
for session_index = 11:19; rivalry_config.sessions(session_index).group = 'many_faces';        end

end
