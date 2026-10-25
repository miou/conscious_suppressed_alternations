function f = release_axes_summary(paths, use_for_testing, states_string, make_dir)
%RELEASE_AXES_SUMMARY  Short, Windows-MAX_PATH-safe path for an axes summary.
%  Used by BOTH combine_responses (save) and the figures (load) so the two always
%  agree. Keeps the distinguishing info -- tested condition (priming/binocular),
%  region (IT/PFC), full vs half-neuron, state (1=conscious, 2=suppressed) -- and
%  drops the constant/duplicated parts of the original lab naming that overflow the
%  260-char path limit (trained_priming_, Fixed rate LLR, 10 ms, avgdim_0, etc.).
%
%  Examples:
%    priming                                    -> axes/priming/summary_priming.mat
%    states_Fixed rate LLR IT 10 ms_1_1         -> axes/binocular/summary_IT_s1.mat
%    states_Fixed rate LLR IT 10 ms half neurons_2_1 -> axes/binocular/summary_IThalf_s2.mat
%    states_Fixed rate LLR PFC 10 ms half neurons_1_1 -> axes/binocular/summary_PFChalf_s1.mat
if nargin < 4; make_dir = false; end

if isempty(states_string)
    tag = 'priming';
else
    tag = states_string;
    tag = strrep(tag, 'states_Fixed rate LLR ', '');  % 'IT 10 ms half neurons_1_1'
    tag = strrep(tag, ' 10 ms', '');                   % 'IT half neurons_1_1'
    tag = strrep(tag, ' half neurons', 'half');        % 'IThalf_1_1'
    tag = strrep(tag, ' ', '_');
    tag = regexprep(tag, '_(\d+)_\d+$', '_s$1');       % '_1_1' (state_value, only_apply) -> '_s1'
end

switch use_for_testing
    case 'dominant_binocular'; sub = 'binocular';
    otherwise;                 sub = use_for_testing;
end
d = fullfile(paths.results, 'axes', sub);
if make_dir && ~exist(d,'dir'); mkdir(d); end
f = fullfile(d, ['summary_' tag '.mat']);
end
