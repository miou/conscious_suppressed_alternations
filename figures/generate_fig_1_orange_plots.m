%Load 250225_184612_Alfie
paradigm_data = session.paradigms_data{1};
time_window_response = [50, paradigm_data.on_duration + 100];
time_window_baseline = [0, 50];

peri_stimulus_range = [0:time_window_response(2)];
[raster, b_in_range] = computeRaster(paradigm_data.timecourse_on_times,paradigm_data.timecourse_all_units',-peri_stimulus_range(1), peri_stimulus_range(end));

start_index_response = find(peri_stimulus_range==time_window_response(1));
end_index_response = find(peri_stimulus_range==time_window_response(2));
start_index_baseline = find(peri_stimulus_range==time_window_baseline(1));
end_index_baseline = find(peri_stimulus_range==time_window_baseline(2));


responses_avg_across_time = squeeze(mean(raster(:,start_index_response:end_index_response,:),2)); %n_trials x n_units
baselines_avg_across_time = squeeze(mean(raster(:,start_index_baseline:end_index_baseline,:),2)); %n_trials x n_units
unit_baselines = mean(baselines_avg_across_time,1); %n_trials x n_units
nstimuli = max(paradigm_data.stimulus_index_valid);
orange_matrix = nan(size(responses_avg_across_time,2),nstimuli);
for stimulus_index = 1:nstimuli
    orange_matrix(:,stimulus_index)= mean(responses_avg_across_time(paradigm_data.stimulus_index_valid == stimulus_index,:),1);
end

orange_matrix_minus_baseline = orange_matrix - repmat(unit_baselines',[1,size(orange_matrix,2)]);
orange_matrix_minus_baseline_normalized = orange_matrix_minus_baseline./repmat((max(abs(orange_matrix_minus_baseline),[],2)),[1,size(orange_matrix,2)]);
b_selected = true(1,size(orange_matrix,1));

probe_indices = unique(session.unit_probes_index);



%% only visually-responsive, sorted by FSI
mode='nature';
paths = set_paths; outputfolder = fullfile(paths.figures_out,'fig_1'); if ~exist(outputfolder,'dir'); mkdir(outputfolder); end
paradigm_index = find(strcmp(cat(1,{data.paradigms.name}),'FOB'));
b_selected_visually_responsive = and(b_selected, session.face_vs_object(paradigm_index).p_value_visual_response<0.05);
[~,sort_indices_fsi] = sort(session.face_vs_object(paradigm_index).fsi);
for probe_index = 1:length(probe_indices)
    [f, ax, S] = make_standard_figure(mode,'FigureNumber',400+2*(probe_index-1)+1, 'HeightInHalfColumnWidths', 0.75, 'WidthInHalfColumns', 1);

    b_selected_probe = and(b_selected_visually_responsive, session.unit_probes_index == probe_index);
    sort_indices_selected_probe = sort_indices_fsi(b_selected_probe(sort_indices_fsi));
    orange_matrix_minus_baseline_normalized_selected = orange_matrix_minus_baseline_normalized(sort_indices_selected_probe,:);
    orange_image = plot_orange_plot(orange_matrix_minus_baseline_normalized_selected);
    drawnow;
    xticks([1:16:size(orange_matrix_minus_baseline_normalized_selected,2)]);xticklabels('');yticks([]);
    xlim([1 size(orange_matrix_minus_baseline_normalized_selected,2)])
    ylim([1 size(orange_matrix_minus_baseline_normalized_selected,1)])
    finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'orange_plot_' session.regions{probe_index} '_' session.session_name]);figure(f);
end

[f, ax, S] = make_standard_figure(mode,'FigureNumber',400, 'HeightInHalfColumnWidths', 0.75, 'WidthInHalfColumns', 1);
orangemap = esa(300);
[white_color, white_pos] = max(sum(orangemap,2));
orangemap = orangemap([1:white_pos round(linspace(white_pos+1,size(orangemap,1)-2,white_pos-1))],:);
colormap(orangemap)
cb = colorbar;
cb.Ticks = [-1 0 1];          % Removes tick labels and marks
cb.TickLength = 0;      % Removes any residual tick extension
cb.Color = 'none';      % Hides the outline border
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[outputfolder filesep 'orange_colorbar']);figure(f);
