%% generate_transition_rasters_251218.m
% Percept-transition rasters for session 251218_142027_Alfie, stimulus pair
% (monkey_face_120d_0051 / monkey_face_120d_0052), CYAN-DOMINANT binocular condition.
% Paper-ready (nature / poster), style of generate_fig_2_example_raster_with_states.m.
%
%   session.inference_results{paradigm_index, si_index}.state_timecourse is per-ms and
%   1 = CONSCIOUS (the dominant/flashed percept), 2 = SUPPRESSED.
% We restrict to ONE binocular condition (cyan-dominant), so the flashed/conscious image is
% always the cyan image and the suppressed image is always the red image. Then:
%   state 1 -> state 2  ==  conscious -> suppressed
%   state 2 -> state 1  ==  suppressed -> conscious
%
% Cells are split by red/cyan image PREFERENCE from priming (independent of the states).
% In cyan-dominant: red-pref == prefers the SUPPRESSED image, cyan-pref == prefers the CONSCIOUS image.
% Cells are COLOURED by percept preference (data.state_colors): suppressed-preferring = purple,
% conscious-preferring = orange -- matching the state-colour scheme used elsewhere in the figure.
%
% Six panels are produced (each its own paper-ready figure / EMF):
%   population  state1->2,  population  state2->1
%   suppressed-preferring example cell (682, purple)  state1->2 / state2->1
%   conscious-preferring  example cell (250, orange)  state1->2 / state2->1
%
% plotSpikeRaster CAVEAT (verified by test_transition_rasters.m): RasterWindowOffset is given in
% SECONDS but the plotted x-axis comes out in MILLISECONDS (offset is divided by TimePerBin=1e-3),
% and a spike at column c is drawn at x=c-50. build_raster puts the transition sample in column
% (win+1), so to place the transition exactly at x=0 use RasterWindowOffset = -(win+1)*1e-3, and
% set xlim in MS: set(gca,'xlim',[-win win])  (NOT [-win win]*1e-3, which blanks the axis).

paths = set_paths;   % adds code folders to the path and returns data locations
load(fullfile(paths.sessions,'session_251218_Alfie.mat'),'session');

mode = 'nature';
data = switches_config_release;

% Attach the release inference schemes in memory (step 3) so inference_results{:,si_index}
% is the release scheme (si_index=50 is LLR), independent of any states the session carries.
[session.inference_schemes, session.inference_results] = switches_infer_states(data, session);

% percept-state colours (state 1 = conscious, state 2 = suppressed); reuse the session's scheme
if isfield(data,'state_colors')
    % col_conscious  = data.state_colors{1};      % conscious (state 1)  -- orange
    % col_suppressed = data.state_colors{2};      % suppressed (state 2) -- purple
    col_conscious  = 'k';      % conscious (state 1)  -- black
    col_suppressed = 'k';      % suppressed (state 2) -- black
else
    % col_conscious  = '#FCAE34';                 % orange fallback
    % col_suppressed = '#543379';                 % purple fallback
    col_conscious  = 'k';      % conscious (state 1)  -- black
    col_suppressed = 'k';      % suppressed (state 2) -- black
end

paradigm_index = find(cellfun(@(x)~isempty(x) && contains(x,'flash_suppression'), session.paradigm_names));
paradigm_data  = session.paradigms_data{paradigm_index};

flash_suppression_get_variables;   % populates on_times_in_range, on_durations_in_range, stimulus_index_in_range,
                                   % trial_is_binocular, trial_red_image, trial_cyan_image, trial_dominant_image,
                                   % stimulus_properties, ...   (needs paradigm_data set above)

if strcmp(mode,'poster')
    spike_line_width        = 3;
    spike_line_width_single = 1;
else % nature
    spike_line_width        = 0.3;
    spike_line_width_single = 0.1;
end

%% ---------------- states + raster ----------------
si_index = 50;   % LLR (conscious/suppressed) inference scheme in inference_results  (1=conscious, 2=suppressed)
state_timecourse  = session.inference_results{paradigm_index, si_index}.state_timecourse;   % 1 x nT
timecourse_raster = paradigm_data.timecourse_all_units';                                     % units x nT (spikes/ms)
nT = size(timecourse_raster,2);

%% ---------------- parameters ----------------
N         = 20;                 % >= N consecutive ms of one state, then >= N consecutive of the other (100% pure)
win       = 50;                 % display half-window (ms)
min_gap   = 100;                % refractory between same-direction transitions (ms)
pref_thr  = 0.20;               % |red-cyan| preference threshold
rate_thr  = 4;                  % Hz, min priming rate (max over the two images)
prime_win = [100 1000];         % ms after onset, for the preference measurement
raster_order = 'cell-major';  % population row order: 'transition-major' (blocks = transitions,
                                    % each holding all cells) | 'cell-major' (blocks = cells, each
                                    % holding all transitions). y-ticks are placed at the block
                                    % boundaries and labelled accordingly (transition # vs unit index).
ytick_stride = 50;                   % label ticks at 1, then every ytick_stride-th block (stride 5 -> 1,5,10,15; stride 10 -> 1,10,20)
combine_pref = false;               % transition-major only: if true, each transition block holds BOTH
                                    % red-pref and cyan-pref cells together (one raster, coloured by
                                    % preference); if false, red-pref block then cyan-pref block.
sort_cells_by_pref = true;          % if true, order ALL cells as ONE list by preference (conscious-pref/orange
                                    % on top -> suppressed-pref/purple on bottom), coloured per cell, no block
                                    % divider. Overrides the two-group layout (and combine_pref).
cumulative_ticks   = true;          % if true, y-tick labels are the cumulative cell/transition number
                                    % across the whole panel (1..N); if false they restart at 1 per block.
fig_height   = 0.58;                % HeightInHalfColumnWidths for ALL panels (population + single cells)
fig_width    = 0.5;                 % WidthInHalfColumns for ALL panels

%% ---------------- the stimulus pair + condition ----------------
red_image  = 'monkey_face_120d_0051';   % image_red of the pair (SUPPRESSED image in cyan-dominant)
cyan_image = 'monkey_face_120d_0052';   % image_cyan of the pair (CONSCIOUS/flashed image in cyan-dominant)

%% ---------------- units to consider (ML + AM) ----------------
selected_probes  = find(ismember(session.regions,{'ML','AM'}));
unit_is_selected = ismember(session.unit_probes_index, selected_probes);

%% ---------------- cell preference: red image vs cyan image (from priming) ----------------
sp = stimulus_properties;
stim_prime_red  = find(sp.is_priming & strcmp(sp.image_red,red_image) & strcmp(sp.image_cyan,cyan_image) & contains(sp.stimulus_contexts,'red_suppressed'));
stim_prime_cyan = find(sp.is_priming & strcmp(sp.image_red,red_image) & strcmp(sp.image_cyan,cyan_image) & contains(sp.stimulus_contexts,'cyan_suppressed'));

resp_red  = priming_response(timecourse_raster, on_times_in_range(stimulus_index_in_range==stim_prime_red),  prime_win);
resp_cyan = priming_response(timecourse_raster, on_times_in_range(stimulus_index_in_range==stim_prime_cyan), prime_win);

pref = (resp_red - resp_cyan) ./ (resp_red + resp_cyan);   % per unit, in [-1 1]
rate = max(resp_red, resp_cyan) * 1000;                    % Hz
b_red_pref  = unit_is_selected(:) & pref(:) >  pref_thr & rate(:) > rate_thr;   % prefers RED image = SUPPRESSED -> purple
b_cyan_pref = unit_is_selected(:) & pref(:) < -pref_thr & rate(:) > rate_thr;   % prefers CYAN image = CONSCIOUS  -> orange

red_units  = find(b_red_pref);  [~,o] = sort(pref(red_units), 'descend'); red_units  = red_units(o);
cyan_units = find(b_cyan_pref); [~,o] = sort(pref(cyan_units),'ascend');  cyan_units = cyan_units(o);

% cell y-order: one preference-sorted list (red-pref top -> cyan-pref bottom), or the two groups stacked
all_units = [red_units(:); cyan_units(:)];
if sort_cells_by_pref
    [~,o] = sort(pref(all_units),'ascend'); cell_order = all_units(o);   % conscious-pref (orange) on TOP -> suppressed-pref (purple) on BOTTOM (plotSpikeRaster uses YDir reverse: first row = top)
    unified = true;
elseif strcmp(raster_order,'transition-major') && combine_pref
    cell_order = all_units; unified = true;                               % red then cyan, together per transition
else
    unified = false;                                                     % two separate stacked blocks
end
if unified, cell_is_red = pref(cell_order) > 0; end                       % pref>0 = red image = suppressed-preferring

%% ---------------- transitions on the conscious/suppressed states (cyan-dominant trials) ----------------
% cyan-dominant  <=>  the dominant (flashed) image is the cyan image
b_pair_cyanDom = trial_is_binocular(:) & strcmp(trial_red_image(:),red_image) ...
               & strcmp(trial_cyan_image(:),cyan_image) & strcmp(trial_dominant_image(:),cyan_image);
pair_trials = find(b_pair_cyanDom);

T_c2s = []; T_s2c = [];   % conscious->suppressed (1->2) and suppressed->conscious (2->1), in session-ms (t=0 = first sample of new state)
for ti = pair_trials'
    a  = on_times_in_range(ti);
    b  = min(on_times_in_range(ti) + on_durations_in_range(ti), nT);
    st = state_timecourse(a:b);
    % conscious(1) -> suppressed(2): N pure 1's before, N pure 2's after
    for i = (find(st(1:end-1)==1 & st(2:end)==2) + 1)
        if i>N && i+N-1<=numel(st) && all(st(i-N:i-1)==1) && all(st(i:i+N-1)==2)
            T_c2s(end+1) = a + i - 1; %#ok<SAGROW>
        end
    end
    % suppressed(2) -> conscious(1)
    for i = (find(st(1:end-1)==2 & st(2:end)==1) + 1)
        if i>N && i+N-1<=numel(st) && all(st(i-N:i-1)==2) && all(st(i:i+N-1)==1)
            T_s2c(end+1) = a + i - 1; %#ok<SAGROW>
        end
    end
end
T_c2s = dedup_transitions(T_c2s, win, nT, min_gap);
T_s2c = dedup_transitions(T_s2c, win, nT, min_gap);

fprintf('cyan-dominant pair (%s / %s): %d suppressed-pref / %d conscious-pref cells; %d conscious->suppressed, %d suppressed->conscious\n', ...
        red_image, cyan_image, numel(red_units), numel(cyan_units), numel(T_c2s), numel(T_s2c));

outputfolder = fullfile(paths.figures_out,'fig_2_example_stimulus_pair');
if ~exist(outputfolder,'dir'); mkdir(outputfolder); end

% panel order: 1st = transition TO state 1 (suppressed->conscious), 2nd = transition TO state 2 (conscious->suppressed)
directions = {T_s2c, 'suppressed_to_conscious'; T_c2s, 'conscious_to_suppressed'};

%% ==================== population rasters (2 panels) ====================
for d = 1:2
    T = directions{d,1}; dirname = directions{d,2};
    [f, ax, S] = make_standard_figure(mode,'FigureNumber',900+d,'HeightInHalfColumnWidths',fig_height,'WidthInHalfColumns',fig_width);
    yt = []; ytl = {};

    if unified
        % ---- one raster over cell_order (preference-sorted or red-then-cyan), coloured per cell ----
        M = build_raster(timecourse_raster, cell_order, T, win, raster_order);
        if strcmp(raster_order,'transition-major')
            row_is_red = repmat(cell_is_red(:), numel(T), 1);                 % per transition: cells in cell_order
            block_size = numel(cell_order); n_blocks = numel(T);
            ylab = sprintf('transition # (%c %d cells)', 215, numel(cell_order));   % char(215)= x (literal, interpreter is 'none')
        else % cell-major
            row_is_red = repelem(cell_is_red(:), numel(T));                   % per cell: its transitions
            block_size = numel(T); n_blocks = numel(cell_order);
            ylab = sprintf('cell # (%c %d transitions)', 215, numel(T));
        end
        % same row layout, split by percept preference, overlaid at VertSpikePosition 0
        M_supp  = M; M_supp(~row_is_red,:) = false;    % red-image / suppressed-preferring rows -> purple
        M_consc = M; M_consc(row_is_red,:) = false;    % cyan-image / conscious-preferring rows -> orange
        plotSpikeRaster(M_supp,  'PlotType','horzline','RasterWindowOffset',-(win+1)*1e-3, ...
                        'LineFormat',struct('Color',col_suppressed,'LineWidth',spike_line_width),'VertSpikePosition',0);
        plotSpikeRaster(M_consc, 'PlotType','horzline','RasterWindowOffset',-(win+1)*1e-3, ...
                        'LineFormat',struct('Color',col_conscious,'LineWidth',spike_line_width),'VertSpikePosition',0);
        n_plotted = size(M,1);
        plot(xlim,repmat(sum(~row_is_red),[1 2]),'k-','LineWidth',S.reference_line_width)
        labels = arrayfun(@(j) num2str(j), 1:n_blocks, 'UniformOutput', false);   % single sequence -> already cumulative
        sel = unique([1, ytick_stride:ytick_stride:n_blocks]);
        yt  = (sel-1)*block_size + 0.5; ytl = labels(sel);
    else
        % ---- two groups stacked: suppressed-pref block, then conscious-pref block ----
        n_plotted = 0; blk_offset = 0;
        for grp = 1:2
            if grp==1, units = red_units; col = col_suppressed; else, units = cyan_units; col = col_conscious; end  % supp purple, consc orange
            M = build_raster(timecourse_raster, units, T, win, raster_order);
            plotSpikeRaster(M, 'PlotType','horzline', 'RasterWindowOffset', -(win+1)*1e-3, ...
                            'LineFormat', struct('Color',col,'LineWidth',spike_line_width), 'VertSpikePosition', n_plotted);
            if strcmp(raster_order,'transition-major')
                block_size = numel(units); n_blocks = numel(T);              % blocks = transitions
                ylab = sprintf('transition # (%c %d cells)', 215, numel(all_units));
            else % cell-major
                block_size = numel(T); n_blocks = numel(units);             % blocks = cells (ordinal, not unit index)
                ylab = sprintf('cell # (%c %d transitions)', 215, numel(T));
            end
            base = (1:n_blocks) + cumulative_ticks*blk_offset;   % cumulative across blocks, or restart at 1
            labels = arrayfun(@(j) num2str(j), base, 'UniformOutput', false);
            sel = unique([1, ytick_stride:ytick_stride:n_blocks]);
            yt  = [yt,  n_plotted + (sel-1)*block_size + 0.5]; %#ok<AGROW>
            ytl = [ytl, labels(sel)]; %#ok<AGROW>
            n_plotted = n_plotted + size(M,1); blk_offset = blk_offset + n_blocks;
            if grp==1
                plot([-win win], [n_plotted+.5 n_plotted+.5], 'k', 'LineWidth', S.reference_line_width/2);  % group divider (ms units)
            end
        end
    end

    xline(0, 'k--', 'LineWidth', S.reference_line_width/2);
    set(gca,'ylim',[0 n_plotted+1]); set(gca,'xlim',[-win win]);      % xlim in ms (see CAVEAT)
    % yticks(yt); yticklabels(ytl); ylabel(ylab);
    yticks(ylim);yticklabels('');ylabel([num2str(n_plotted) ' cell-transitions'])
    xticks([-win 0 win]); xticklabels({num2str(-win),'0',num2str(win)});
    finish_standard_figure(f, ax, S, 'ExportEMF', true, 'OutputBase', [outputfolder filesep sprintf('population_panel%d_%s', d, dirname)]);
    figure(f);
end

%% ==================== two opposing example cells (4 panels) ====================
cell_red  = 682;   % MATLAB unit index, prefers RED (suppressed) image -> purple; python 0-based 681, AM
cell_cyan = 250;   % MATLAB unit index, prefers CYAN (conscious) image -> orange; python 0-based 249, ML
example_cells  = [cell_red cell_cyan];
example_colors = {col_suppressed, col_conscious};   % suppressed-pref purple, conscious-pref orange
example_colors = {'k', 'k'};   % suppressed-pref purple, conscious-pref orange
for c = 1:2
    for d = 1:2
        T = directions{d,1}; dirname = directions{d,2};
        [f, ax, S] = make_standard_figure(mode,'FigureNumber',950+10*c+d,'HeightInHalfColumnWidths',fig_height,'WidthInHalfColumns',fig_width);
        M = build_raster(timecourse_raster, example_cells(c), T, win, raster_order);   % one cell: rows = transitions (order irrelevant)
        LineFormat = struct('Color', example_colors{c}, 'LineWidth', spike_line_width_single);
        plotSpikeRaster(M, 'PlotType','vertline', 'RasterWindowOffset', -(win+1)*1e-3, ...
                        'LineFormat', LineFormat, 'VertSpikePosition', 0);
        xline(0, 'k--', 'LineWidth', S.reference_line_width/2);
        set(gca,'ylim',[0 size(M,1)+1]); set(gca,'xlim',[-win win]);
        yticks(unique([1, size(M,1)])); ylabel([num2str(size(M,1)) ' transitions']);
        xticks([-win 0 win]); xticklabels({num2str(-win),'0',num2str(win)});
        finish_standard_figure(f, ax, S, 'ExportEMF', true, ...
            'OutputBase', [outputfolder filesep sprintf('cell_%d_panel%d_%s', example_cells(c), d, dirname)]);
        figure(f);
    end
end

%% ==================== helper functions ====================
function r = priming_response(tc, onsets, prime_win)
    % mean firing rate (spikes/ms) per unit over [onset+prime_win(1), onset+prime_win(2)], averaged over trials
    r = zeros(size(tc,1),1); n = 0;
    for k = 1:numel(onsets)
        a = onsets(k)+prime_win(1); b = onsets(k)+prime_win(2)-1;
        if a>=1 && b<=size(tc,2)
            r = r + sum(tc(:,a:b),2)/(prime_win(2)-prime_win(1));
            n = n + 1;
        end
    end
    r = r / max(n,1);
end

function T = dedup_transitions(T, win, nT, min_gap)
    % keep transitions whose +/-win window fits, then enforce >=min_gap ms between kept ones (keep first)
    T = sort(T(T>win & T+win<=nT));
    keep = []; last = -inf;
    for t = T
        if t-last >= min_gap, keep(end+1) = t; last = t; end %#ok<AGROW>
    end
    T = keep;
end

function M = build_raster(tc, units, T, win, order)
    % Rows grouped either by transition or by cell (columns = -win..+win-1 ms, logical):
    %   'transition-major': [trans1: unit1..unitU][trans2: unit1..unitU]...
    %   'cell-major':       [unit1: trans1..transK][unit2: trans1..transK]...
    % (For a single unit the two are identical: rows = transitions in time order.)
    if nargin<5 || isempty(order), order = 'transition-major'; end
    M = false(numel(T)*numel(units), 2*win); k = 0;
    if strcmp(order,'transition-major')
        for t = T
            for u = units(:)'
                k = k + 1; M(k,:) = tc(u, t-win : t+win-1) > 0;
            end
        end
    else % cell-major
        for u = units(:)'
            for t = T
                k = k + 1; M(k,:) = tc(u, t-win : t+win-1) > 0;
            end
        end
    end
end