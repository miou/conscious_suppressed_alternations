
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

% Plot overall probability time course
figure(3); clf; hold on;
plot(bins, mean(isPercept, 3), 'LineWidth', 2); % Mean probability across trials
set(gca, 'ylim', [0 1]);
plot([0 0], ylim, 'k--'); % Line marking trial onset
plot([config.unambiguousDurationSeconds config.unambiguousDurationSeconds], ylim, 'k--'); % Line marking end of unambiguous period
legend(perceptsOfInterest);
xlabel('Time from unambiguous stimulus onset');
ylabel('Proportion percept');

% Separate plots for Red and Cyan suppressed trials
[f, ax, S] = make_standard_figure(mode,'FigureNumber',100, 'HeightInHalfColumnWidths', 1);

% Red suppressed trials
subplot(2, 1, 1); hold on;
title('Red suppressed');
plot(bins, mean(isPercept(:, :, contains(stimulus_name, 'priming_red')), 3), 'LineWidth', 2);
set(gca, 'ylim', [0 1]);
plot([0 0], ylim, 'k--'); % Trial onset
plot([config.unambiguousDurationSeconds config.unambiguousDurationSeconds], ylim, 'k--'); % End of unambiguous period
legend(perceptsOfInterest);
xlabel('Time from unambiguous stimulus onset');
ylabel('Proportion percept');

% Cyan suppressed trials
subplot(2, 1, 2); hold on;
title('Cyan suppressed');
plot(bins, mean(isPercept(:, :, contains(stimulus_name, 'priming_cyan')), 3), 'LineWidth', 2);
set(gca, 'ylim', [0 1]);
plot([0 0], ylim, 'k--'); % Trial onset
plot([config.unambiguousDurationSeconds config.unambiguousDurationSeconds], ylim, 'k--'); % End of unambiguous period
legend(perceptsOfInterest);
xlabel('Time from unambiguous stimulus onset');
ylabel('Proportion percept');

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
disp('Analysis Results:');
disp(resultsTable);

figure(1);clf;
bar(uniqueAugmentedPercepts, percentageViewed);
xlabel('Percept');
ylabel('Percentage of Time Viewed');
title('Dominance Percentages');
grid on;

figure(2);clf;
numConditions = length(uniqueAugmentedPercepts); % Number of percepts

for i = 1:numConditions
    subplot(ceil(numConditions / 2), 2, i); % Create subplot grid (2 columns)

    % Check if the condition has valid durations
    if ~isempty(allAugmentedDurations{i}) && ~all(isnan(allAugmentedDurations{i}))
        histogram(allAugmentedDurations{i}, 'BinWidth', 0.5); % Adjust bin width as needed
    else
        text(0.5, 0.5, 'No Data', 'HorizontalAlignment', 'center');
        xlim([0, 1]); % Adjust limits for visual consistency
    end

    title(['Duration Distribution for ' uniqueAugmentedPercepts{i}]);
    xlabel('Duration (s)');
    ylabel('Frequency');
    grid on;
end

% Add an overall title to the figure
sgtitle('Duration Distributions for All Conditions');

% Save results to a .mat file
[~, outputName, ~] = fileparts(outputFile);
analysisFilename = [outputName '_analysis.mat'];

end

function [filteredTimestamps, filteredPercepts] = filterRepeatedPercepts(allTimestamps, allPercepts)
isNewPercept = [true; ~strcmp(allPercepts(1:end-1), allPercepts(2:end))];
filteredTimestamps = allTimestamps(isNewPercept);
filteredPercepts = allPercepts(isNewPercept);
end