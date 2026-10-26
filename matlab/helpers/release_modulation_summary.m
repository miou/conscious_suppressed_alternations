function f = release_modulation_summary(paths, variant_name, state, make_dir)
%RELEASE_MODULATION_SUMMARY  Short path for a pooled modulation summary.
%  Used by step4_combine_modulation (save) and the modulation figures (load).
%  e.g. 'Fixed rate LLR IT 10 ms', state 1 -> modulation/summary_IT_s1.mat
if nargin < 4; make_dir = false; end
tag = variant_name;
tag = strrep(tag, 'Fixed rate LLR ', '');
tag = strrep(tag, ' 10 ms', '');
tag = strrep(tag, ' half neurons', 'half');
tag = strrep(tag, ' ', '_');
d = fullfile(paths.results, 'modulation');
if make_dir && ~exist(d,'dir'); mkdir(d); end
f = fullfile(d, ['summary_' tag '_s' num2str(state) '.mat']);
end
