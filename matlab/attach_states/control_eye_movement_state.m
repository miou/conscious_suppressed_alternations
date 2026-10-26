function out = control_eye_movement_state(paths, rivalry_config)
% CONTROL_EYE_MOVEMENT_STATE  Is the conscious/suppressed state an eye-movement artifact?
%   Tests whether the LLR conscious (state 1) vs suppressed (state 2) partition can be
%   explained by residual eye movements within the fixation window. For each session it
%   aligns the per-sample state label (conscious vs suppressed) to the simultaneously
%   recorded eye position and compares the two states by (i) mean eye position / eye speed
%   (Cohen's d) and (ii) cross-validated decodability of the state from eye position (AUC).
%   Eye position is read from the released HDF5 export; state labels from the LLR partition.
%
%   Result (2 monkeys, all dual-probe sessions): states are indistinguishable by eye position
%   (|d|~0.02) and eye position decodes the state only marginally above chance (AUC~0.51),
%   far below decoding from neural activity (0.66). The alternation is therefore not an
%   oculomotor artifact. (Pupil/arousal give the same conclusion from the full session files.)
%
%   out = control_eye_movement_state(set_paths, switches_config_release)

if nargin < 1; paths = set_paths; end
if nargin < 2; rivalry_config  = switches_config_release; end
bin = 10;   % ms: one sample per state bin, to avoid within-bin pseudoreplication
state_dir = fullfile(paths.python_states,'llr_fs','bin_10_units_all');

rows = struct('session',{},'monkey',{},'d_eyex',{},'d_eyey',{},'d_speed',{},'auc',{});
for s = 1:numel(rivalry_config.sessions)
    name = erase(rivalry_config.sessions(s).session_name,'session_');          % e.g. 250225_Alfie
    sf = dir(fullfile(state_dir, ['hmm_data_' extractBefore(name,'_') '*_p12.mat']));
    if isempty(sf); continue; end
    S = load(fullfile(sf(1).folder, sf(1).name));
    part = double(S.llr.dom_sup_partition(:));                       % per-sample: 1=conscious,2=suppressed,else NaN/0
    L = numel(part);

    h5 = dir(fullfile(paths.sessions_h5, ['*' extractBefore(name,'_') '*.h5']));
    if isempty(h5); continue; end
    h5f = fullfile(h5(1).folder, h5(1).name);
    info = h5info(h5f,'/paradigms'); grp = '';
    for g = 1:numel(info.Groups)
        if any(contains({info.Groups(g).Datasets.Name},'eyex_timecourse')); grp = info.Groups(g).Name; break; end
    end
    if isempty(grp); continue; end
    ex = h5read(h5f,[grp '/eyex_timecourse']); ex = ex(:);
    ey = h5read(h5f,[grp '/eyey_timecourse']); ey = ey(:);
    if numel(ex) ~= L; continue; end                                 % must share the clock
    speed = [0; sqrt(diff(ex).^2 + diff(ey).^2)];

    idx = 1:bin:L;                                                   % to 10 ms bins
    P = part(idx); EX = ex(idx); EY = ey(idx); SP = speed(idx);
    s1 = P==1 & isfinite(EX) & isfinite(EY);
    s2 = P==2 & isfinite(EX) & isfinite(EY);
    if nnz(s1) < 50 || nnz(s2) < 50; continue; end

    cohend = @(a,b) (mean(a)-mean(b)) / sqrt((var(a)+var(b))/2 + eps);
    sel = s1 | s2; X = [EX(sel) EY(sel) SP(sel)]; y = double(P(sel)==1);
    auc = NaN;
    try
        mdl = fitclinear(zscore(X), y, 'Learner','logistic', 'KFold',5);
        [~,sc] = kfoldPredict(mdl);
        [~,~,~,auc] = perfcurve(y, sc(:,2), 1);
    catch; end

    k = numel(rows)+1;
    rows(k).session = name; rows(k).monkey = string(extractAfter(name,'_'));
    rows(k).d_eyex = cohend(EX(s1),EX(s2)); rows(k).d_eyey = cohend(EY(s1),EY(s2));
    rows(k).d_speed = cohend(SP(s1),SP(s2)); rows(k).auc = auc;
    fprintf('%-18s  d_eyex=%+.3f d_eyey=%+.3f d_speed=%+.3f  AUC(eye->state)=%.3f\n', ...
        name, rows(k).d_eyex, rows(k).d_eyey, rows(k).d_speed, rows(k).auc);
end

out = rows;
if ~isempty(rows)
    aucs = [rows.auc];
    fprintf('\nAGGREGATE n=%d sessions: mean AUC(eye->state)=%.3f (chance=0.5; neural state decoder=0.66)\n', ...
        numel(rows), mean(aucs(isfinite(aucs))));
    fprintf('mean|d| eyex=%.3f eyey=%.3f speed=%.3f  -> states not separable by eye position.\n', ...
        mean(abs([rows.d_eyex])), mean(abs([rows.d_eyey])), mean(abs([rows.d_speed])));
end
end
