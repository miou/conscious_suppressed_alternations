mode = 'nature';
paths = set_paths;
rivalry_config = switches_config_release;
load(fullfile(paths.sessions,'session_251218_Alfie.mat'),'session');   % session used for the paper Fig. 1 example raster (trial 57)

paradigm_index = find(cellfun(@(x)~isempty(x) && contains(x,'flash_suppression'),session.paradigm_names));
paradigm_data = session.paradigms_data{paradigm_index};

flash_suppression_get_variables;
if strcmp(mode,'poster')
    spike_line_width = 5;
elseif strcmp(mode,'nature')
    spike_line_width = 1;
end

%--------------------------LLR-----------------------------
%Used for paper figure 1
trial_index = 57; %251218_142027_Alfie
si_index = 1; %LLR IT (see switches_infer_states)

session.b_use_fixed_trial_duration_for_timecourse = false;
timecourse_raster = paradigm_data.timecourse_all_units';


paradigm_index = find(cellfun(@(x)~isempty(x)  && contains(x,'flash_suppression'),session.paradigm_names))
paradigm_data = session.paradigms_data{paradigm_index};

selected_probes = find(ismember(session.regions,{'ML','AM'}));

time_before = 0;

on_time = on_times_in_range(trial_index);

paradigm_data.stimulus_list(stimulus_index_in_range(trial_index))
snippet_start_times = on_time-time_before% 14020
time_course_snippet_time = on_durations_in_range(trial_index)+1000;
snippet_index = 1 ;
b_only_significant = true;

on_time_next = on_times_in_range(trial_index) + on_durations_in_range(trial_index);



line_styles = {'-','--'};
plotstyles_raster = {'r','b'};

[fsi_sorted,sort_indices_fsi] = sort(session.face_vs_object(paradigm_data.paradigm_index_for_selectivity).fsi,'desc');
if b_only_significant
    b_face_selective = and(session.face_vs_object(paradigm_data.paradigm_index_for_selectivity).fsi>=0, or(session.face_vs_object(paradigm_data.paradigm_index_for_selectivity).p_value_face_vs_object<0.05,session.face_vs_object(paradigm_data.paradigm_index_for_selectivity).p_value_visual_response<0.05));
    b_object_selective = and(session.face_vs_object(paradigm_data.paradigm_index_for_selectivity).fsi<0, or(session.face_vs_object(paradigm_data.paradigm_index_for_selectivity).p_value_face_vs_object<0.05,session.face_vs_object(paradigm_data.paradigm_index_for_selectivity).p_value_visual_response<0.05));
else
    b_face_selective = session.face_vs_object(paradigm_data.paradigm_index_for_selectivity).fsi>=0;
    b_object_selective = ~b_face_selective;
end

%Make figure-------------->
[f, ax, S] = make_standard_figure(mode,'FigureNumber',200,'HeightInHalfColumnWidths',1,  'WidthInHalfColumns', 2.2);


start_index = snippet_start_times(snippet_index);
end_index = min(snippet_start_times(snippet_index)+time_course_snippet_time,size(timecourse_raster,2));
number_of_units_plotted = 0;
for probe_index = selected_probes
    b_probe = session.unit_probes_index==probe_index;
    if b_only_significant
        b_selected_face_selective = and(b_probe,b_face_selective);
        selected_face_selective_sortindices = sort_indices_fsi(b_selected_face_selective(sort_indices_fsi));
        b_selected_object_selective = and(b_probe,b_object_selective);
        selected_object_selective_sortindices = sort_indices_fsi(b_selected_object_selective(sort_indices_fsi));
        LineFormat.Color = 'k';
        LineFormat.LineWidth = spike_line_width;
        plotSpikeRaster(timecourse_raster(selected_face_selective_sortindices,start_index:end_index),'PlotType','horzline','RasterWindowOffset',start_index*1e-3,'LineFormat',LineFormat,'VertSpikePosition',number_of_units_plotted);
        number_of_units_plotted = number_of_units_plotted + length(selected_face_selective_sortindices);
    else
        LineFormat.Color = 'k';
        LineFormat.LineWidth = spike_line_width;

        plotSpikeRaster(timecourse_raster(b_probe,start_index:end_index),'PlotType','horzline','RasterWindowOffset',start_index*1e-3,'LineFormat',LineFormat,'VertSpikePosition',number_of_units_plotted);
        number_of_units_plotted = number_of_units_plotted + sum(b_probe);

    end
    if probe_index <selected_probes(end)
        plot([start_index end_index],[number_of_units_plotted+.5 number_of_units_plotted+.5],'k','LineWidth',S.reference_line_width/2)
    end

end

set(gca,'YTicklabel','')
xticks([-1000 -500 0 500 1000]+on_times_in_range(trial_index+1))
yticks([0 number_of_units_plotted])
set(gca,'XTicklabel',{'-1','-0.5','0','0.5','1'})
set(gca,'ylim',[0 number_of_units_plotted+5])

p=plotTimes(on_times_in_range(trial_is_binocular),start_index,end_index,'LineWidth',S.reference_line_width);p.Color='k';p.LineStyle='--';

paths = set_paths; figure_folder_name = fullfile(paths.figures_out,'fig_1'); if ~exist(figure_folder_name,'dir'); mkdir(figure_folder_name); end
finish_standard_figure(f, ax, S, 'ExportEMF',true,'OutputBase',[figure_folder_name filesep 'example_raster'])

