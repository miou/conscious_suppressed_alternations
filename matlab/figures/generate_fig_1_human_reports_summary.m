function generate_figure_1_human_reports_summary()
paths = set_paths;
d = dir(fullfile(paths.human,'*.mat'));
outputFiles=fullfile({d.folder}, {d.name});
for outputFileIndex = 1:length(outputFiles)
    outputFile = outputFiles{outputFileIndex};
    session = load(outputFile); % Load file as session
    if ~isfield(session, 'data') || ~isfield(session.data, 'timestampsReports') || ...
            ~isfield(session.data, 'percepts')
        error('The selected file does not contain the expected data structure.');
    end

    % Choose time source: 'trialTime', 'trialFlipTime', or 'none' (no block
    % onset times). Should set to 'none' if there is no flash suppression
    % and just rivalry.
    if session.config.blankDurationSeconds == 0 && session.config.unambiguousDurationSeconds == 0
        timeSource = 'none'; % Options: 'trialTime', 'trialFlipTime', 'none'
    elseif session.config.blankDurationSeconds == 0
        timeSource = 'trialTime'; % Options: 'trialTime', 'trialFlipTime', 'none'
    else
        timeSource = 'trialFlipTime'; % Options: 'trialTime', 'trialFlipTime', 'none'
    end

    % Extract data
    timestampsReports = reshape(session.data.timestampsReports,[],1); % Ensure row vector
    percepts = session.data.percepts;
    trialStimulus = session.data.trialStimulus; % Stimulus and block indices

    if isempty(timestampsReports)
        error('No perceptual data found. Check the input file for completeness.');
    end


    % Extract appropriate block onset times based on timeSource
    if ismember(timeSource, {'trialTime', 'trialFlipTime'})
        allTrialOnsets = session.data.(timeSource)(:); % Get selected time source
        % Find indices of rivalry onsets in the global list of all trials
        rivalryIndices = find(cellfun(@(x) x(2) == session.config.cRivalry, session.data.trialStimulus))';
        % Compute rivalry ON and OFF events
        rivalryOnsets = allTrialOnsets(rivalryIndices);
        rivalryOffsets = arrayfun(@(idx) allTrialOnsets(min(idx + 1, numel(allTrialOnsets))), rivalryIndices);
        % Handle the last rivalry period
        if rivalryOffsets(end) == allTrialOnsets(end)
            rivalryOffsets(end) = allTrialOnsets(end) + session.config.rivalryDurationSeconds;
        end

    elseif strcmp(timeSource, 'none') %Assuming it's all rivalry
        allTrialOnsets = 0; % Get selected time source

        rivalryOnsets = 0;
        rivalryOffsets = timestampsReports(end)+1;
    else
        error('Invalid timeSource selected. Choose "trialTime", "trialFlipTime", or "none".');
    end

    % Restrict percepts to within rivalry epochs
    timestampsReportsRivalry = [];
    perceptsRivalry = {};
    for i = 1:length(rivalryOnsets)
        % Get current rivalry epoch
        epochStart = rivalryOnsets(i);
        epochEnd = rivalryOffsets(i);

        % Find percept timestamps within this epoch
        mask = session.data.timestampsReports >= epochStart & session.data.timestampsReports < epochEnd;
        timestampsReportsRivalry = [timestampsReportsRivalry; timestampsReports(mask)];
        perceptsRivalry = [perceptsRivalry; percepts(mask)];
    end

    resultsTable = computeDominanceDurationsWithinRivalry(outputFile,timestampsReportsRivalry,perceptsRivalry,rivalryOnsets,rivalryOffsets,allTrialOnsets,timeSource);

    [binsNew,meanPercept,config,perceptsOfInterest] = computeDominanceCourse(outputFile,session.config, timestampsReports,percepts,trialStimulus,allTrialOnsets,timeSource);
    if outputFileIndex>1
        assert(all(bins==binsNew));
        assert(unambiguousDurationSeconds == config.unambiguousDurationSeconds);
    end
    bins = binsNew;
    unambiguousDurationSeconds = config.unambiguousDurationSeconds;
    meanPerceptPrimingRedSubjects(:,:,outputFileIndex) = meanPercept.PrimingRed;
    meanPerceptPrimingCyanSubjects(:,:,outputFileIndex) = meanPercept.PrimingCyan;
end
SEM = @(x,dim)std(x,[],dim)/sqrt(size(x,dim));


mode='nature';
outputfolder = fullfile(paths.figures_out,'fig_1'); if ~exist(outputfolder,'dir'); mkdir(outputfolder); end
cmap = colororder;

% Red suppressed trials
[f, ax, S] = make_standard_figure(mode,'FigureNumber',100, 'HeightInHalfColumnWidths', 0.75);
[p,errorarea]=plot_with_sem(bins-unambiguousDurationSeconds, 100*squeeze(meanPerceptPrimingRedSubjects(1,:,:))');p.Color=cmap(1,:);p.LineWidth=S.line_width;errorarea.FaceColor = cmap(1,:);
[p,errorarea]=plot_with_sem(bins-unambiguousDurationSeconds, 100*squeeze(meanPerceptPrimingRedSubjects(2,:,:))');p.Color=cmap(2,:);p.LineWidth=S.line_width;errorarea.FaceColor = cmap(2,:);
[p,errorarea]=plot_with_sem(bins-unambiguousDurationSeconds, 100*squeeze(meanPerceptPrimingRedSubjects(3,:,:))');p.Color=cmap(3,:);p.LineWidth=S.line_width;errorarea.FaceColor = cmap(3,:);
set(gca, 'ylim', [0 100]);
plot([0 0], ylim, 'k--','LineWidth',S.reference_line_width); % End of unambiguous period
set(gca,'xlim',[-2 6])
xticks([-2 0 2 4 6])
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'human_reports_red_suppressed']);figure(f);

% Cyan suppressed trials
[f, ax, S] = make_standard_figure(mode,'FigureNumber',101, 'HeightInHalfColumnWidths', 0.75);
[p,errorarea]=plot_with_sem(bins-unambiguousDurationSeconds, 100*squeeze(meanPerceptPrimingCyanSubjects(1,:,:))');p.Color=cmap(1,:);p.LineWidth=S.line_width;errorarea.FaceColor = cmap(1,:);
[p,errorarea]=plot_with_sem(bins-unambiguousDurationSeconds, 100*squeeze(meanPerceptPrimingCyanSubjects(2,:,:))');p.Color=cmap(2,:);p.LineWidth=S.line_width;errorarea.FaceColor = cmap(2,:);
[p,errorarea]=plot_with_sem(bins-unambiguousDurationSeconds, 100*squeeze(meanPerceptPrimingCyanSubjects(3,:,:))');p.Color=cmap(3,:);p.LineWidth=S.line_width;errorarea.FaceColor = cmap(3,:);
set(gca, 'ylim', [0 100]);
plot([0 0], ylim, 'k--','LineWidth',S.reference_line_width); % Trial onset
set(gca,'xlim',[-2 6])
xticks([-2 0 2 4 6])
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'human_reports_cyan_suppressed']);figure(f);




% --- Report lag, measured on the priming stimulus (independent of the flash) ---
iC = 1; iR = 2; tol = 1e-9;   % perceptsOfInterest = {'Cyan','Red','Mixed'}
primed = squeeze( (meanPerceptPrimingRedSubjects(iR,:,:) + meanPerceptPrimingCyanSubjects(iC,:,:)) / 2 );
pre  = bins >= -1 & bins < 0;                                      % carry-over baseline
rise = bins >= -tol & bins <= unambiguousDurationSeconds + tol;    % priming period
lagPerSubject = nan(size(primed,2),1); t = bins(rise);
for s = 1:size(primed,2)
    y = primed(rise,s); base = mean(primed(pre,s));
    [amp,ip] = max(y);
    lagPerSubject(s) = t(find(y(1:ip) >= base + 0.5*(amp-base), 1, 'first'));
end
reportLag = mean(lagPerSubject);   % 0.86 s
fprintf('Report lag (half-rise to primed colour): %.2f ± %.2f s\n', reportLag, SEM(lagPerSubject,1));

% --- Does flash suppression work? 300-1000 ms after the flash, corrected for report lag ---
win = bins >= unambiguousDurationSeconds + reportLag + 0.3 - tol & ...
      bins <= unambiguousDurationSeconds + reportLag + 1.0 + tol;
supp = ( squeeze(mean(meanPerceptPrimingRedSubjects (iC,win,:) - meanPerceptPrimingRedSubjects (iR,win,:), 2)) + ...
         squeeze(mean(meanPerceptPrimingCyanSubjects(iR,win,:) - meanPerceptPrimingCyanSubjects(iC,win,:), 2)) ) / 2;
[~, p, ci, st] = ttest(supp);
fprintf(['Flash suppression %.0f%% (95%% CI [%.0f%%, %.0f%%]), %d/%d subjects, ' ...
         't(%d)=%.1f, p=%.2g, dz=%.2f\n'], 100*mean(supp), 100*ci(1), 100*ci(2), ...
        sum(supp>0), numel(supp), st.df, st.tstat, p, mean(supp)/std(supp));

proportionReportFlash = mean((squeeze(mean(meanPerceptPrimingRedSubjects (iC,win,:))) + squeeze(mean(meanPerceptPrimingCyanSubjects(iR,win,:))))/2)
win_priming = bins >= reportLag + 0.3 - tol & ...
      bins <= reportLag + 1.0 + tol;
proportionReportPriming = mean((squeeze(mean(meanPerceptPrimingRedSubjects (iR,win_priming,:))) + squeeze(mean(meanPerceptPrimingCyanSubjects(iC,win_priming,:))))/2)

end
function [bins,meanPercept,config,perceptsOfInterest] = computeDominanceCourse(outputFile, config, timestampsReports, percepts, trialStimulus, allTrialOnsets, timeSource)
% Filter out repeated percepts to ensure clean transitions
[filteredtimestampsReports, filteredpercepts] = filterRepeatedPercepts(timestampsReports, percepts);

% Define percepts of interest (e.g., Red, Cyan, Mixed)
perceptsOfInterest = {'Cyan','Red', 'Mixed'};

% Define time bins for alignment
binSize = 0.1; % Bin size in seconds
TimeWindow = [-1 config.unambiguousDurationSeconds + config.rivalryDurationSeconds]; % Time range
bins = TimeWindow(1):binSize:TimeWindow(2); % Create time bins

% Identify unambiguous trials
if ~strcmp(timeSource,'none')
    isUnambiguousTrial = cellfun(@(x) x(2) == config.cUnambiguous, trialStimulus); % Mask for unambiguous trials
    unAmbiguousTrialStimulus = trialStimulus(isUnambiguousTrial); % Filter unambiguous trials
    unambiguousTrialOnsets = allTrialOnsets(isUnambiguousTrial); % Onsets for unambiguous trials
else
    unAmbiguousTrialStimulus = [];
    unambiguousTrialOnsets = [];
end
% Initialize matrix to store percept dominance proportions
% Dimensions: (percepts, bins, trials)
isPercept = zeros(length(perceptsOfInterest), length(bins), length(unambiguousTrialOnsets));

stimulus_name = cell(length(unambiguousTrialOnsets),1);
% Loop through each unambiguous trial
for unambiguousTrialOnsetsIndex = 1:length(unambiguousTrialOnsets)
    trialOnset = unambiguousTrialOnsets(unambiguousTrialOnsetsIndex); % Trial onset time
    row_column = unAmbiguousTrialStimulus{unambiguousTrialOnsetsIndex}; % Trial stimulus
    stimulus_name{unambiguousTrialOnsetsIndex} = config.stimulusName{row_column(1), row_column(2)}; % Stimulus name
    binsAroundTrialOnset = bins + trialOnset; % Align bins to the current trial onset

    % Loop through percepts and their start and end times
    for perceptIndex = 1:length(percepts) - 1
        perceptStart = timestampsReports(perceptIndex); % Start time of percept
        perceptEnd = timestampsReports(perceptIndex + 1); % End time of percept
        percept = percepts{perceptIndex}; % Percept label
        perceptsOfInterestIndex = find(strcmp(perceptsOfInterest, percept), 1); % Index of current percept in list

        % If percept matches a percept of interest, assign it to bins
        if ~isempty(perceptsOfInterestIndex)
            isPerceptTrial = binsAroundTrialOnset >= perceptStart & binsAroundTrialOnset <= perceptEnd; % Find bins dominated by percept
            isPercept(perceptsOfInterestIndex, :, unambiguousTrialOnsetsIndex) = ...
                isPercept(perceptsOfInterestIndex, :, unambiguousTrialOnsetsIndex) + isPerceptTrial;
        end
    end
end

meanPercept.All = mean(isPercept, 3);
meanPercept.PrimingRed = mean(isPercept(:, :, contains(stimulus_name, 'priming_red')), 3);
meanPercept.PrimingCyan = mean(isPercept(:, :, contains(stimulus_name, 'priming_cyan')), 3);
end


function resultsTable = computeDominanceDurationsWithinRivalry(outputFile,timestampsReportsRivalry,perceptsRivalry,rivalryOnsets,rivalryOffsets,allTrialOnsets,timeSource)
% Augment restricted percepts with rivalry ON and OFF events
augmentedTimestamps = [timestampsReportsRivalry; rivalryOnsets; rivalryOffsets];
augmentedPercepts = [perceptsRivalry; ...
    repmat({'Delay from Rivalry ON'}, length(rivalryOnsets), 1); ...
    repmat({'Delay from Rivalry OFF'}, length(rivalryOffsets), 1)];

% Sort timestamps and align percepts
[augmentedTimestamps, sortIdx] = sort(augmentedTimestamps);
augmentedPercepts = augmentedPercepts(sortIdx);

% Filter repeated percepts (skip consecutive duplicates)
[filteredAugmentedTimestamps, filteredAugmentedPercepts] = filterRepeatedPercepts(augmentedTimestamps, augmentedPercepts);

% Initialize variables for analysis
uniqueAugmentedPercepts = {'Red', 'Cyan', 'Mixed', 'Delay from Rivalry ON'};
dominanceAugmentedDurations = zeros(1, numel(uniqueAugmentedPercepts));
allAugmentedDurations = cell(1, numel(uniqueAugmentedPercepts));
AugmentedPerceptTrialIndex = cell(1, numel(uniqueAugmentedPercepts));
totalAugmentedDuration = filteredAugmentedTimestamps(end) - filteredAugmentedTimestamps(1);

% Calculate dominance durations
for i = 1:length(filteredAugmentedPercepts) - 1
    perceptIndex = find(strcmp(uniqueAugmentedPercepts, filteredAugmentedPercepts{i}));
    if ~isempty(perceptIndex)
        augmentedDuration = filteredAugmentedTimestamps(i+1) - filteredAugmentedTimestamps(i);
        dominanceAugmentedDurations(perceptIndex) = dominanceAugmentedDurations(perceptIndex) + augmentedDuration;
        allAugmentedDurations{perceptIndex} = [allAugmentedDurations{perceptIndex}, augmentedDuration];
        AugmentedPerceptTrialIndex{perceptIndex}(i) = allTrialOnsets(find(allTrialOnsets<=filteredAugmentedTimestamps(i),1,'last'));
    end
end

% Handle empty durations gracefully
for i = 1:numel(allAugmentedDurations)
    if isempty(allAugmentedDurations{i})
        allAugmentedDurations{i} = NaN; % Assign NaN for empty durations
    end
end

% Calculate percentages, average, and median durations
percentageViewed = (dominanceAugmentedDurations / totalAugmentedDuration) * 100;
averageDurations = cellfun(@(x) mean(x, 'omitnan'), allAugmentedDurations, 'UniformOutput', true);
medianDurations = cellfun(@(x) median(x, 'omitnan'), allAugmentedDurations, 'UniformOutput', true);

% Display results
resultsTable = table(uniqueAugmentedPercepts', dominanceAugmentedDurations', percentageViewed', ...
    averageDurations', medianDurations', ...
    'VariableNames', {'Percept', 'TotalDominanceDuration', 'PercentageViewed', ...
    'AverageDominanceDuration', 'MedianDominanceDuration'});
end

function [filteredTimestamps, filteredPercepts] = filterRepeatedPercepts(allTimestamps, allPercepts)
isNewPercept = [true; ~strcmp(allPercepts(1:end-1), allPercepts(2:end))];
filteredTimestamps = allTimestamps(isNewPercept);
filteredPercepts = allPercepts(isNewPercept);
end
