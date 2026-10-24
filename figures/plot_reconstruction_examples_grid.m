function [ax, S] = plot_reconstruction_examples_grid( ...
    fig, S, config, xml_folder, xml_filename, stimulus_list, priming_stimuli, ...
    folder_name, features, predicted_features_state1, predicted_features_state2, ...
    unique_stimuli, unique_stimulus_index_other_list, ...
    unique_stimuli_is_high_repeat, red_cyan_pair_indices)
%PLOT_RECONSTRUCTION_EXAMPLES_GRID_EDGEFILLED
% Plot a 5 x 4 reconstruction grid as a special case inside a figure made
% by make_standard_figure. The standard make/finish functions are unchanged.
%
% Rows, in order:
%   38, 39, 36, 51, 59
%
% Columns, in order:
%   1. Ground-truth conscious face
%   2. State-1 reconstruction
%   3. Ground-truth suppressed face
%   4. State-2 reconstruction
%
% Call as:
%   [fig,~,S] = make_standard_figure(mode, ...
%       'PanelSpan',[2 2], 'GridSize',[5 4]);
%   [ax,S] = plot_reconstruction_examples_grid(fig,S,...);
%   finish_standard_figure(fig,ax,S,...);
%
% The function preserves the vertical content rectangle created by
% make_standard_figure, but deliberately uses the full figure width.
% It does not resize the figure.
%
% The following inputs are retained for compatibility with the previous
% function interface, although some are not used directly here:
% xml_folder, stimulus_list, priming_stimuli, folder_name,
% unique_stimuli, unique_stimuli_is_high_repeat, red_cyan_pair_indices.

%#ok<*INUSD>

example_indices = [38 39 36 51 59];
b_make_images_gray = true;
b_use_control_1_stimuli = false;
output_res = [300 300];

assert(size(predicted_features_state1,1) == size(features,1), ...
    'predicted_features_state1 must have one row per stimulus.');
assert(size(predicted_features_state2,1) == size(features,1), ...
    'predicted_features_state2 must have one row per stimulus.');
assert(all(example_indices <= size(features,1)), ...
    'At least one requested example index exceeds the number of stimuli.');

other_indices = unique_stimulus_index_other_list(example_indices);
assert(all(~isnan(other_indices)), ...
    'Every selected conscious face must have a valid suppressed-face partner.');

% Map ground-truth indices through control-stimulus remapping when needed.
ground_truth_conscious_indices = example_indices;
ground_truth_suppressed_indices = other_indices;

if b_use_control_1_stimuli && isfield(config,'stim_index_abcd')
    for row_index = 1:numel(example_indices)
        conscious_index = example_indices(row_index);
        suppressed_index = other_indices(row_index);

        map_row = find(config.stim_index_abcd(:,1) == conscious_index & ...
                       config.stim_index_abcd(:,2) == suppressed_index, 1);

        if ~isempty(map_row)
            ground_truth_conscious_indices(row_index) = config.stim_index_abcd(map_row,3);
            ground_truth_suppressed_indices(row_index) = config.stim_index_abcd(map_row,4);
        else
            map_row = find(config.stim_index_abcd(:,2) == conscious_index & ...
                           config.stim_index_abcd(:,1) == suppressed_index, 1);
            assert(~isempty(map_row), ...
                'Could not find the selected face pair in config.stim_index_abcd.');
            ground_truth_conscious_indices(row_index) = config.stim_index_abcd(map_row,4);
            ground_truth_suppressed_indices(row_index) = config.stim_index_abcd(map_row,3);
        end
    end
end

%% Generate only the images needed for this panel
is_liang = contains(xml_filename,'FlashSuppression_many_faces_Liang_2500_many_pairs') || ...
           contains(xml_filename,'FlashSuppression_many_faces_Liang_2000_many_pairs');
is_steven = contains(xml_filename,'FlashSuppression_many_faces_Steven_2000_many_pairs');

if is_liang
    % Face-generation code (AAM_Model) is shipped in helpers/; the model DATA and any Liang
    % deps live under the release data folder (paths.stimulus_model) -- ship them there.
    p_rel = set_paths; addpath(genpath(p_rel.stimulus_model));
    model_data = fullfile(p_rel.stimulus_model,'Monkey_Face_Model_Data.mat');
    model = AAM_Model(model_data);

    warning_state = warning('off','all');
    cleanup_warning = onCleanup(@() warning(warning_state)); %#ok<NASGU>

    [ground_truth_conscious,lm_gtc] = model.gen_image_param( ...
        features(ground_truth_conscious_indices,:), output_res);
    [ground_truth_suppressed,lm_gts] = model.gen_image_param( ...
        features(ground_truth_suppressed_indices,:), output_res);
    [reconstruction_state1,lm_r1] = model.gen_image_param( ...
        predicted_features_state1(example_indices,:), output_res);
    [reconstruction_state2,lm_r2] = model.gen_image_param( ...
        predicted_features_state2(example_indices,:), output_res);

    ground_truth_conscious = image_array_to_cell(ground_truth_conscious);
    ground_truth_suppressed = image_array_to_cell(ground_truth_suppressed);
    reconstruction_state1 = image_array_to_cell(reconstruction_state1);
    reconstruction_state2 = image_array_to_cell(reconstruction_state2);

elseif is_steven
    p_rel = set_paths; addpath(genpath(p_rel.stimulus_model));   % ship Steven's face_generator_50d under paths.stimulus_model

    ground_truth_conscious = face_generator_50d( ...
        features(ground_truth_conscious_indices,:), 0);
    ground_truth_suppressed = face_generator_50d( ...
        features(ground_truth_suppressed_indices,:), 0);
    reconstruction_state1 = face_generator_50d( ...
        predicted_features_state1(example_indices,:), 0);
    reconstruction_state2 = face_generator_50d( ...
        predicted_features_state2(example_indices,:), 0);
else
    error('Unrecognized face-generation stimulus set: %s', xml_filename);
end

%% Convert images to display-ready uint8 RGB
number_of_examples = numel(example_indices);
images_to_plot = cell(number_of_examples,4);

for row_index = 1:number_of_examples
    % Required column order:
    % GT conscious | reconstruction state 1 | GT suppressed | reconstruction state 2
    images_to_plot{row_index,1} = prepare_face_image( ...
        ground_truth_conscious{row_index}, b_make_images_gray);
    images_to_plot{row_index,2} = prepare_face_image( ...
        reconstruction_state1{row_index}, b_make_images_gray);
    images_to_plot{row_index,3} = prepare_face_image( ...
        ground_truth_suppressed{row_index}, b_make_images_gray);
    images_to_plot{row_index,4} = prepare_face_image( ...
        reconstruction_state2{row_index}, b_make_images_gray);
end

% Display-only: normalize each reconstruction's face region to a common mean luminance and contrast
% (target = pooled ground-truth face statistics; identical operation for every reconstruction, no pairwise
% matching), blended over the original inside a landmark mask so the grey background and natural face edge
% are untouched (no halo). Only for the landmark-based (Liang) model.
if b_make_images_gray && is_liang
    gt_face_values = [];
    for row_index = 1:number_of_examples
        gt_face_values = [gt_face_values; ...
            face_hull_values(images_to_plot{row_index,1}, lm_gtc(:,:,row_index), output_res); ...
            face_hull_values(images_to_plot{row_index,3}, lm_gts(:,:,row_index), output_res)]; %#ok<AGROW>
    end
    target_mean = mean(gt_face_values); target_std = std(gt_face_values);
    for row_index = 1:number_of_examples
        images_to_plot{row_index,2} = normalize_face(images_to_plot{row_index,2}, lm_r1(:,:,row_index), output_res, target_mean, target_std);
        images_to_plot{row_index,4} = normalize_face(images_to_plot{row_index,4}, lm_r2(:,:,row_index), output_res, target_mean, target_std);
    end
end

%% Plot into the content rectangle supplied by make_standard_figure
assert(isgraphics(fig,'figure'), 'fig must be a valid figure handle.');

number_of_rows = 5;
number_of_columns = 4;

% Remove the placeholder axes created by make_standard_figure.
old_axes = findall(fig, 'Type', 'axes');
delete(old_axes);

% Use the mode- and PanelSpan-dependent content rectangle. Do not resize
% the figure here; make_standard_figure owns all physical dimensions.
if isfield(S, 'content_position')
    content_position = S.content_position;
else
    content_position = S.axes_position;
end

if isfield(S, 'grid_horizontal_gap_fraction')
    horizontal_gap_fraction = S.grid_horizontal_gap_fraction;
else
    horizontal_gap_fraction = 0.055;
end

if isfield(S, 'grid_vertical_gap_fraction')
    vertical_gap_fraction = S.grid_vertical_gap_fraction;
else
    vertical_gap_fraction = 0.035;
end

% Keep each face square and preserve the existing vertical geometry.
% The face size is therefore determined by the available height.
vertical_gap = vertical_gap_fraction * ...
    content_position(4) / ...
    (number_of_rows + (number_of_rows - 1) * vertical_gap_fraction);

cell_size = ...
    (content_position(4) - (number_of_rows - 1) * vertical_gap) / ...
    number_of_rows;

% Use the full physical figure width. The first face touches the left edge,
% the last face touches the right edge, and all additional width is placed
% only into the three horizontal gaps between columns.
horizontal_left = 0;
horizontal_width = S.figure_width;
minimum_faces_width = number_of_columns * cell_size;

if horizontal_width < minimum_faces_width
    error( ...
        'plot_reconstruction_examples_v3:FigureTooNarrow', ...
        ['The figure is too narrow for four square faces at the current ', ...
         'height. Increase GridWidthScale or reduce GridHeightScale.']);
end

horizontal_gap = ...
    (horizontal_width - minimum_faces_width) / ...
    (number_of_columns - 1);

grid_width = horizontal_width;
grid_height = number_of_rows * cell_size + ...
    (number_of_rows - 1) * vertical_gap;

grid_left = horizontal_left;
grid_bottom = content_position(2) + ...
    0.5 * (content_position(4) - grid_height);

ax = gobjects(number_of_rows,number_of_columns);
axes_positions = zeros(number_of_rows * number_of_columns,4);
axes_counter = 0;

for row_index = 1:number_of_rows
    for column_index = 1:number_of_columns
        left = grid_left + ...
            (column_index-1) * (cell_size + horizontal_gap);
        bottom = grid_bottom + ...
            (number_of_rows-row_index) * (cell_size + vertical_gap);

        axes_counter = axes_counter + 1;
        axes_positions(axes_counter,:) = ...
            [left bottom cell_size cell_size];

        ax(row_index,column_index) = axes(fig, ...
            'Units','inches', ...
            'Position',axes_positions(axes_counter,:), ...
            'PositionConstraint','innerposition', ...
            'Color','none', ...
            'Visible','off');

        image(images_to_plot{row_index,column_index}, ...
            'Parent',ax(row_index,column_index));
        axis(ax(row_index,column_index),'image');
        axis(ax(row_index,column_index),'off');
        set(ax(row_index,column_index), ...
            'XLim',[0.5 size(images_to_plot{row_index,column_index},2)+0.5], ...
            'YLim',[0.5 size(images_to_plot{row_index,column_index},1)+0.5], ...
            'YDir','reverse', ...
            'LooseInset',[0 0 0 0], ...
            'PositionConstraint','innerposition');
    end
end

% finish_standard_figure restores positions from this field. Store them in
% the same column-major order produced by ax(:).
ax = ax(:);
S.axes_position = zeros(numel(ax),4);
for axes_index = 1:numel(ax)
    S.axes_position(axes_index,:) = get(ax(axes_index), 'Position');
end

S.grid_size = [number_of_rows number_of_columns];
S.grid_content_position = content_position;

end

function images_cell = image_array_to_cell(images_array)
% Convert H x W x C x N output into a 1 x N cell array.
number_of_images = size(images_array,4);
images_cell = cell(1,number_of_images);
for image_index = 1:number_of_images
    images_cell{image_index} = images_array(:,:,:,image_index);
end
end

function image_out = prepare_face_image(image_in, make_gray)
% Convert either [0,1] floating-point or integer images to uint8 RGB.
if isfloat(image_in)
    finite_values = image_in(isfinite(image_in));
    if isempty(finite_values)
        error('Encountered an image containing no finite pixel values.');
    end
    if max(finite_values) <= 1.5
        image_in = 255 * image_in;
    end
end

image_in = uint8(max(0,min(255,double(image_in))));

if size(image_in,3) == 1
    image_in = repmat(image_in,[1 1 3]);
elseif size(image_in,3) > 3
    image_in = image_in(:,:,1:3);
end

if make_gray
    % Preserve the original script's max-channel conversion, which avoids
    % darkening pixels that were encoded primarily in one anaglyph channel.
    gray_image = max(image_in,[],3);
    image_out = repmat(gray_image,[1 1 3]);
else
    image_out = image_in;
end
end

function v = face_hull_values(rgb, lm, res)
% Face-region pixel values (max-channel grey) within the landmark interior mask.
gray = double(rgb(:,:,1));
v = gray(face_hull_mask(lm, res, 10));
end

function out = normalize_face(rec_rgb, lm_rec, res, target_mean, target_std)
% Normalize the reconstruction's face region (mean+std within a landmark interior mask) to a common
% target, then blend over the ORIGINAL reconstruction with a feathered alpha kept inside the face ->
% grey background and natural edge preserved (no halo). Same operation for every reconstruction.
gray = double(rec_rgb(:,:,1));
mask_stats = face_hull_mask(lm_rec, res, 10);
f = gray(mask_stats);
if numel(f) < 10 || std(f) < 1e-6
    out = rec_rgb; return
end
bright = (gray - mean(f)) / std(f) * target_std + target_mean;   % normalize interior to common mean+std
alpha = imgaussfilt(double(face_hull_mask(lm_rec, res, 15)), 6);  % feather stays inside the face
o = alpha .* bright + (1 - alpha) .* gray;                        % composite over original recon
out = repmat(uint8(max(0, min(255, o))), [1 1 3]);
end

function m = face_hull_mask(lm, res, erode_px)
x = lm(:,1); y = lm(:,2); k = convhull(x, y);
m = imerode(poly2mask(x(k), y(k), res(1), res(2)), strel('disk', erode_px));
end
