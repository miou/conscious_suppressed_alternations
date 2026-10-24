function [responses_priming_stimuli, responses_priming_stimuli_minus_baseline,responses_baseline] = flash_suppression_get_priming_responses(raster_to_use,peri_stimulus_range,time_window,priming_stimuli_list,priming_stimuli,stimulus_index_in_range)
start_index=find(peri_stimulus_range==time_window(1));
end_index=find(peri_stimulus_range==time_window(end));
responses_priming_stimuli = nan(length(priming_stimuli_list),size(raster_to_use,3));
responses_priming_stimuli_minus_baseline = nan(length(priming_stimuli_list),size(raster_to_use,3));
responses_baseline =  shiftdim(mean(mean(raster_to_use(:,start_index:end_index,:),2),1),1);

for priming_stimulus_index = 1:length(priming_stimuli_list)
    stimulus_index=find(cellfun(@(x)~isempty(x) && contains(x,priming_stimuli_list{priming_stimulus_index}),priming_stimuli));
    responses_priming_stimuli(priming_stimulus_index,:)=mean(mean(raster_to_use(ismember(stimulus_index_in_range,stimulus_index),start_index:end_index,:),2),1);
    responses_priming_stimuli_minus_baseline(priming_stimulus_index,:)=responses_priming_stimuli(priming_stimulus_index,:) - responses_baseline;
end