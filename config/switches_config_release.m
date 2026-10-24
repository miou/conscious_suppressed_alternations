function data = switches_config_release()
%SWITCHES_CONFIG_RELEASE  The 19 recording sessions used in the paper.
%  Indexed 1..19: sessions 1-10 are the many_combinations sessions, 11-19 are
%  the many_faces sessions. Each session is a file
%  'session_<date>_<monkey>.mat' in paths.sessions.

paths = set_paths;

data = struct();
data.data_path = paths.sessions;
data = define_analysis_rivalry(data);

data.lfp_filter_band = [3 9];
data.channel_prefix = '_Ch_';
data.unit_prefix = '_Unit_';
data.Ch_Unit_num_digits = 3; %e.g. 001.

data.sessions = struct;

% ------------------------- many_combinations sessions ------------------------
session_index = 1;
data.sessions(session_index).session_name = 'session_250225_Alfie';
data.sessions(session_index).acquisitionsoftware= 'spikeglx';
data.sessions(session_index).regions = {'ML','AM'}; data.sessions(session_index).layer_direction = {1,-1};

session_index = 2;
data.sessions(session_index).session_name = 'session_250312_Alfie';
data.sessions(session_index).acquisitionsoftware= 'spikeglx';
data.sessions(session_index).regions = {'ML','AM'}; data.sessions(session_index).layer_direction = {1,-1};

session_index = 3;
data.sessions(session_index).session_name = 'session_250317_Alfie';
data.sessions(session_index).acquisitionsoftware= 'spikeglx';
data.sessions(session_index).regions = {'ML','AM'}; data.sessions(session_index).layer_direction = {1,-1};

session_index = 4;
data.sessions(session_index).session_name = 'session_250321_Alfie';
data.sessions(session_index).acquisitionsoftware= 'spikeglx';
data.sessions(session_index).regions = {'ML','AM'}; data.sessions(session_index).layer_direction = {1,-1};

session_index = 5;
data.sessions(session_index).session_name = 'session_250504_Mowgli';
data.sessions(session_index).acquisitionsoftware= 'spikeglx';
data.sessions(session_index).regions = {'ML','AM'}; data.sessions(session_index).layer_direction = {1,-1};

session_index = 6;
data.sessions(session_index).session_name = 'session_250513_Alfie';
data.sessions(session_index).acquisitionsoftware= 'spikeglx';
data.sessions(session_index).regions = {'ML','SC'}; data.sessions(session_index).layer_direction = {1,-1};

session_index = 7;
data.sessions(session_index).session_name = 'session_250518_Mowgli';
data.sessions(session_index).acquisitionsoftware= 'spikeglx';
data.sessions(session_index).regions = {'ML','AM'}; data.sessions(session_index).layer_direction = {1,-1};

session_index = 8;
data.sessions(session_index).session_name = 'session_250604_Alfie';
data.sessions(session_index).acquisitionsoftware= 'spikeglx';
data.sessions(session_index).regions = {'ML','SC'}; data.sessions(session_index).layer_direction = {1,-1};

session_index = 9;
data.sessions(session_index).session_name = 'session_250615_Alfie';
data.sessions(session_index).acquisitionsoftware= 'spikeglx';
data.sessions(session_index).regions = {'ML','PO'}; data.sessions(session_index).layer_direction = {1,-1};

session_index = 10;
data.sessions(session_index).session_name = 'session_260210_Mowgli';
data.sessions(session_index).acquisitionsoftware= 'spikeglx';
data.sessions(session_index).regions = {'ML','PVL'}; data.sessions(session_index).layer_direction = {1,1};

% ---------------------------- many_faces sessions ----------------------------
session_index = 11;
data.sessions(session_index).session_name = 'session_251212_Alfie';
data.sessions(session_index).acquisitionsoftware= 'spikeglx';
data.sessions(session_index).regions = {'ML','AM'}; data.sessions(session_index).layer_direction = {1,-1};

session_index = 12;
data.sessions(session_index).session_name = 'session_251218_Alfie';
data.sessions(session_index).acquisitionsoftware= 'spikeglx';
data.sessions(session_index).regions = {'ML','AM'}; data.sessions(session_index).layer_direction = {1,-1};

session_index = 13;
data.sessions(session_index).session_name = 'session_260108_Mowgli';
data.sessions(session_index).acquisitionsoftware= 'spikeglx';
data.sessions(session_index).regions = {'ML','AM'}; data.sessions(session_index).layer_direction = {1,-1};

session_index = 14;
data.sessions(session_index).session_name = 'session_260119_Alfie';
data.sessions(session_index).acquisitionsoftware= 'spikeglx';
data.sessions(session_index).regions = {'ML','AM'}; data.sessions(session_index).layer_direction = {1,-1};

session_index = 15;
data.sessions(session_index).session_name = 'session_260205_Mowgli';
data.sessions(session_index).acquisitionsoftware= 'spikeglx';
data.sessions(session_index).regions = {'ML','AM','PVL'}; data.sessions(session_index).layer_direction = {1,-1,1};

session_index = 16;
data.sessions(session_index).session_name = 'session_260218_Mowgli';
data.sessions(session_index).acquisitionsoftware= 'spikeglx';
data.sessions(session_index).regions = {'ML','AM','PVL'}; data.sessions(session_index).layer_direction = {1,-1,1};

session_index = 17;
data.sessions(session_index).session_name = 'session_260225_Mowgli';
data.sessions(session_index).acquisitionsoftware= 'spikeglx';
data.sessions(session_index).regions = {'ML','AM','PVL'}; data.sessions(session_index).layer_direction = {1,-1,1};

session_index = 18;
data.sessions(session_index).session_name = 'session_260309_Alfie';
data.sessions(session_index).acquisitionsoftware= 'spikeglx';
data.sessions(session_index).regions = {'ML','PO','PVL'}; data.sessions(session_index).layer_direction = {1,-1,1};

session_index = 19;
data.sessions(session_index).session_name = 'session_260322_Alfie';
data.sessions(session_index).acquisitionsoftware= 'spikeglx';
data.sessions(session_index).regions = {'ML','PO','PVL'}; data.sessions(session_index).layer_direction = {1,-1,1};

% Paradigm group per session (lets the step-4a drivers select without loading):
%   many_combinations = all-combinations/unambiguous paradigm (modulation indices)
%   many_faces        = many-stimuli reconstruction paradigm (reconstruction/axes)
for session_index = 1:10;  data.sessions(session_index).group = 'many_combinations'; end
for session_index = 11:19; data.sessions(session_index).group = 'many_faces';        end

end
