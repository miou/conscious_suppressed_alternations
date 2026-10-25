function data = define_analysis_rivalry(data);

data.analysis_name = 'Analysis_Rivalry';

data.paradigms = struct();
data.paradigms(1).name = 'FOB';
data.paradigms(1).suffix = '_Passive_Fixation_New_FOB.mat';
data.paradigms(1).special_analyses = {'face_vs_object','orange_plot','compute_average_responses'};


data.paradigms(19).name = 'face_syn_2000';
data.paradigms(19).suffix = '_Passive_Fixation_New_face_syn_2000.mat';
data.paradigms(19).special_analyses = {'plot_time_courses'};


data.paradigms(21).name = 'flash_suppression_optimized';
data.paradigms(21).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces250117.mat';
data.paradigms(21).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(22).name = 'flash_suppression_optimized';
data.paradigms(22).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces250122.mat';
data.paradigms(22).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(23).name = 'flash_suppression_optimized';
data.paradigms(23).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces250211.mat';
data.paradigms(23).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(26).name = 'flash_suppression_optimized_0.8';
data.paradigms(26).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces250217_0.8.mat';
data.paradigms(26).special_analyses = {'plot_time_courses'};

data.paradigms(28).name = 'flash_suppression_optimized_repeat_subset';
data.paradigms(28).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces250225.mat';
data.paradigms(28).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(29).name = 'flash_suppression_optimized_repeat_subset';
data.paradigms(29).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces250312.mat';
data.paradigms(29).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(30).name = 'flash_suppression_optimized_repeat_subset';
data.paradigms(30).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces250317.mat';
data.paradigms(30).special_analyses = {'plot_time_courses'};

data.paradigms(31).name = 'flash_suppression_optimized';
data.paradigms(31).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces250320Dasheng.mat';
data.paradigms(31).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(32).name = 'flash_suppression_optimized';
data.paradigms(32).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces250321_0.7.mat';
data.paradigms(32).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(33).name = 'flash_suppression_optimized_repeat_subset';
data.paradigms(33).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces250321.mat';
data.paradigms(33).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(34).name = 'flash_suppression_optimized';
data.paradigms(34).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces250415_-0.1.mat';
data.paradigms(34).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(35).name = 'flash_suppression_optimized';
data.paradigms(35).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces250427.mat';
data.paradigms(35).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(36).name = 'flash_suppression_optimized';
data.paradigms(36).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces250504.mat';
data.paradigms(36).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(37).name = 'flash_suppression_optimized';
data.paradigms(37).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces_250905_SC.mat';
data.paradigms(37).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(38).name = 'flash_suppression_optimized';
data.paradigms(38).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces_250513_SC.mat';
data.paradigms(38).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(39).name = 'flash_suppression_optimized';
data.paradigms(39).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces_250518.mat';
data.paradigms(39).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(40).name = 'flash_suppression_optimized';
data.paradigms(40).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces_250604Screening_0.6.mat';
data.paradigms(40).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(41).name = 'flash_suppression_optimized';
data.paradigms(41).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces_250604_SC_0.63.mat';
data.paradigms(41).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(42).name = 'flash_suppression_optimized';
data.paradigms(42).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces_250612_Pulv_0.63_Screening.mat';
data.paradigms(42).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(43).name = 'flash_suppression_optimized';
data.paradigms(43).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces_250612_Pulv_0.57.mat';
data.paradigms(43).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(44).name = 'flash_suppression_optimized';
data.paradigms(44).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces_250614_PO_0.57_Screening.mat';
data.paradigms(44).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(45).name = 'flash_suppression_optimized';
data.paradigms(45).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces_250614_PO_0.58.mat';
data.paradigms(45).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(46).name = 'flash_suppression_optimized';
data.paradigms(46).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces_251102_0.58.mat';
data.paradigms(46).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(47).name = 'flash_suppression_optimized';
data.paradigms(47).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces_251106_0.58.mat';
data.paradigms(47).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(48).name = 'flash_suppression_optimized';
data.paradigms(48).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces_251110_0.58.mat';
data.paradigms(48).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(49).name = 'flash_suppression_optimized';
data.paradigms(49).suffix = '_Passive_Fixation_New_FlashSuppressionLiangMonkeyFaces_260210_-0.10.mat';
data.paradigms(49).special_analyses = {'plot_time_courses','compute_average_responses'};


data.paradigms(50).name = 'flash_suppression_many_stimuli';
data.paradigms(50).suffix = '_Passive_Fixation_New_FlashSuppression_many_faces_Liang_2500_many_pairs_0.58.mat';
data.paradigms(50).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(51).name = 'flash_suppression_many_stimuli';
data.paradigms(51).suffix = '_Passive_Fixation_New_FlashSuppression_many_faces_Liang_2500_many_pairs_priming_reconstructed_0.58.mat';
data.paradigms(51).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(52).name = 'flash_suppression_many_stimuli';
data.paradigms(52).suffix = '_Passive_Fixation_New_FlashSuppression_many_faces_Steven_2000_many_pairs_0.58.mat';
data.paradigms(52).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(53).name = 'flash_suppression_many_stimuli';
data.paradigms(53).suffix = '_Passive_Fixation_New_FlashSuppression_many_faces_Liang_2500_many_pairs_priming_reconstructed_-0.10.mat';
data.paradigms(53).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(54).name = 'flash_suppression_many_stimuli';
data.paradigms(54).suffix = '_Passive_Fixation_New_FlashSuppression_many_faces_Liang_2500_many_pairs_0.00.mat';
data.paradigms(54).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(55).name = 'flash_suppression_many_stimuli';
data.paradigms(55).suffix = '_Passive_Fixation_New_FlashSuppression_many_faces_Liang_2000_many_pairs_priming_reconstructed_-0.20.mat';
data.paradigms(55).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(56).name = 'flash_suppression_many_stimuli_transparent';
data.paradigms(56).suffix = '_Passive_Fixation_New_FlashSuppression_many_faces_Liang_2500_many_pairs_priming_reconstructed_0.00_transparent.mat';
data.paradigms(56).special_analyses = {'plot_time_courses','compute_average_responses'};

data.paradigms(57).name = 'flash_suppression_many_stimuli';
data.paradigms(57).suffix = '_Passive_Fixation_New_FlashSuppression_many_faces_Liang_2500_many_pairs_0.76.mat'; %This one is actually priming reconstructed
data.paradigms(57).special_analyses = {'plot_time_courses','compute_average_responses'};



data.paradigms(58).name = 'monkey_face_1500';
data.paradigms(58).suffix = '_Passive_Fixation_New_monkey_face_1500.mat';
data.paradigms(58).special_analyses = {};


data.state_colors = {'#FCAE34','#543379','#1C0F29','#2E4B23'};


data.keep_rasters = false;
data.keep_all_lfp_rasters = false;
data.keep_lfp = true;
data.lfp_single_resolution = true; %Use single instead of double to save space.
data.time_course_snippet_time = 5*1001; %Plot 10 second snippets
