function [spikeRaster,b_TriggerTimes_valid] = computeRaster(TriggerTimes,spikeTimecourses,RasterTimeBeforeMS,RasterTimeAfterMS,pad_out_of_range)
% spikeTimecourses needs to be n_cells x n_time_points
% pad_out_of_range (optional, default false): false (default) EXCLUDES trials whose window runs
%   past the recording. true keeps ALL trials and zero-pads out-of-range samples -- this
%   reproduces a precomputed raster_all_units (built over all trials), so raster_all_units can
%   be dropped and rebuilt from timecourse_all_units without losing the first/last trial.
if nargin < 5 || isempty(pad_out_of_range); pad_out_of_range = false; end
if ~iscell(spikeTimecourses)
    if size(spikeTimecourses,2)==1
        spikeTimecourses = spikeTimecourses';
    end
    spikeTimecourses = num2cell(spikeTimecourses,2);
end
L = length(spikeTimecourses{1});
if pad_out_of_range
    b_TriggerTimes_valid = true(size(TriggerTimes));                 % keep ALL trials
else
    b_TriggerTimes_valid = and(TriggerTimes-RasterTimeBeforeMS>0,TriggerTimes+RasterTimeAfterMS<=L);
end
TriggerTimes = TriggerTimes(b_TriggerTimes_valid); %Exclude out-of-range (default) or keep all (padded).

if all(cellfun(@islogical,spikeTimecourses))
    spikeRaster = false(length(TriggerTimes),length(-RasterTimeBeforeMS:RasterTimeAfterMS),length(spikeTimecourses));
else
    spikeRaster = nan(length(TriggerTimes),length(-RasterTimeBeforeMS:RasterTimeAfterMS),length(spikeTimecourses));
end
TriggerTimesIntervals = zeros(length(TriggerTimes),length((-RasterTimeBeforeMS):RasterTimeAfterMS));
for TriggerTimesIndex=1:length(TriggerTimes)
    TriggerTimesIntervals(TriggerTimesIndex,:) = (TriggerTimes(TriggerTimesIndex)-RasterTimeBeforeMS):(TriggerTimes(TriggerTimesIndex)+RasterTimeAfterMS);
end
idx = round(TriggerTimesIntervals);
if pad_out_of_range
    b_oob = idx < 1 | idx > L;            % samples outside the recording
    idx_clamped = min(max(idx,1),L);
    for cellIndex = 1:length(spikeTimecourses)
        vals = spikeTimecourses{cellIndex}(idx_clamped);
        vals(b_oob) = 0;                  % zero-pad out-of-range (no spikes outside recording)
        spikeRaster(:,:,cellIndex) = vals;
    end
else
    for cellIndex = 1:length(spikeTimecourses)
        spikeRaster(:,:,cellIndex) = spikeTimecourses{cellIndex}(idx);
    end
end
end
