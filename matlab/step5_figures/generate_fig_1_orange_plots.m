% Draws the Fig. 1 orange (face/object selectivity) plots for one example session.
% The orange matrix (per-unit face/object responses, baseline-subtracted and normalized across
% stimuli) is precomputed and stored on the session. The FOB paradigm's raster is dropped from
% the released sessions to save space, so use the stored matrix rather than recomputing it.
paths = set_paths;
rivalry_config = switches_config_release;
load(fullfile(paths.sessions,'session_250225_Alfie.mat'),'session');   % example session for the Fig. 1 orange plots
orange_matrix_minus_baseline_normalized = session.orange_matrix_minus_baseline_normalized{1};
b_selected = true(1,size(orange_matrix_minus_baseline_normalized,1));

probe_indices = unique(session.unit_probes_index);



%% only visually-responsive, sorted by FSI
mode='nature';
paths = set_paths; outputfolder = fullfile(paths.figures_out,'fig_1'); if ~exist(outputfolder,'dir'); mkdir(outputfolder); end
paradigm_index = find(strcmp(cat(1,{rivalry_config.paradigms.name}),'FOB'));
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
