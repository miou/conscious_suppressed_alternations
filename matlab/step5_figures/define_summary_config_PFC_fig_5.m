%First: Load a summary across sessions. Then run this script for summary analysis.
config = flash_suppression_results_all_sessions{find(~cellfun(@isempty,flash_suppression_results_all_sessions),1,'last')}.axes.config;

summary_config.stimuli_to_include = 1:1500; %To ignore stimuli for 2000 face experiment

%Set defaults for fields the summary may not specify
if ~isfield(config,'balance_states_each_trial')
    config.balance_states_each_trial = false;
end
if ~isfield(config,'minimum_state_proportion_per_trial')
    config.minimum_state_proportion_per_trial = [];
end
if ~isfield(config,'avg_first_dimension')
    config.avg_first_dimension = 1; %default
end

monkeys_to_include = {};

if ~isempty(monkeys_to_include)
    monkeys_string = [filesep strjoin(monkeys_to_include,'_') filesep];
else
    monkeys_string = '';
end


regions_to_include = {'PO','PVL','PA'};
if ~isempty(regions_to_include)
    regions_string = [filesep strjoin(regions_to_include,'_') filesep];
else
    regions_string = '';
end
summary_config.cell_selection_scheme = 'visual_cells';

summary_config.number_of_cells_to_select = [];
summary_config.number_of_pcs = 500;


summary_config.b_use_control_1_stimuli = false;

folder_name = '';

figure_folder_name = paths.figures_out;   % release default; each generate_fig_* overrides with its own subfolder