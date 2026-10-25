function [fig, ax, S] = make_standard_figure(mode, varargin)
%MAKE_STANDARD_FIGURE_WIDTH_UNITS_V5 Create a consistently styled scientific figure.
%
%   [fig, ax, S] = make_standard_figure(mode)
%
% MODES
%   'nature'  Publication figure intended for a Nature manuscript.
%   'poster'  Half-column figure for a four-column, 48 x 36 inch poster.
%
% EXAMPLES
%
%   [fig, ax, S] = make_standard_figure('nature');
%
%   plot(ax, x, y, ...
%       'Color', S.colors.conscious);
%
%   xlabel(ax, 'Time (ms)');
%   ylabel(ax, 'Decoding accuracy');
%
%   finish_standard_figure(fig, ax, S);
%
%
% OPTIONAL NAME-VALUE ARGUMENTS
%
%   'FigureShape'
%       'square'  default
%       'wide'
%       'tall'
%
%   'WidthInHalfColumns'
%       Width measured in standard half-column panel units.
%       Default: 1. Use 2 for the same width previously produced by
%       PanelSpan [2 1]. This changes width only; height remains standard.
%
%   'PanelGap'
%       Gap between adjacent standard panels, in inches.
%       Default is mode-specific.
%
%   'HeightInHalfColumnWidths'
%       Optional explicit figure height measured in half-column widths.
%       For ordinary single plots, the default is 1, making a standard
%       half-column figure square. Changing this value scales the axes and
%       all vertical margins together, so the axes cannot overflow the
%       resized figure. For grids, omitting this option preserves the
%       automatically tuned grid height.
%
%   'GridSize'
%       Optional [rows columns] for compact image/grid figures. When
%       supplied, the width still comes from mode and PanelSpan, while
%       the height is adjusted so square grid cells fill the canvas.
%       Default: [].
%
%   'GridGapFraction'
%       Gap between grid cells as a fraction of one cell width.
%       Default: 0.035.
%
%   'FigureNumber'
%       Existing or desired MATLAB figure number.
%
%   'PosterFontSize'
%       Default: 32 pt.
%
%   'TitleSpace'
%       Reserve additional space above the axes.
%       Default: false.
%
%   'Visible'
%       'on' or 'off'.
%       Default: 'on'.
%
%   'Position'
%       Explicit on-screen position:
%
%           [left bottom width height]
%
%       Units are inches.
%
%
% DESIGN
%
% Nature mode:
%   Arial
%   6-point text
%   2-point principal lines
%   Approximately two panels per Nature column
%
% Poster mode:
%   Calibri
%   32-point text by default
%   5-point principal lines
%   Approximately half of one poster column
%
% The inner plotting region is reduced by 10%, while the total canvas size
% remains unchanged. The released space is added to the margins for axis
% labels, tick labels, titles, and annotations.
%
% The MATLAB preview uses a white background so figures remain visible in
% MATLAB dark mode. Transparent export should be handled by
% finish_standard_figure using:
%
%   exportgraphics(..., 'BackgroundColor', 'none')
%
% Ordinary Line objects created after calling this function inherit the
% mode-specific line width.
%
% Helper functions available in S:
%
%   S.plot
%   S.plot_thick
%   S.plot_reference
%   S.scatter
%   S.errorbar
%   S.xline
%   S.yline
%   S.identity_line
%   S.chance_line
%   S.bar
%   S.histogram

%% Parse inputs

p = inputParser;

addRequired( ...
    p, ...
    'mode', ...
    @(x) ischar(x) || isstring(x));

addParameter( ...
    p, ...
    'FigureShape', ...
    'square', ...
    @(x) any(strcmpi(x, {'square', 'wide', 'tall'})));

addParameter( ...
    p, ...
    'WidthInHalfColumns', ...
    1, ...
    @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0);

addParameter( ...
    p, ...
    'PanelGap', ...
    [], ...
    @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 0));

addParameter( ...
    p, ...
    'HeightInHalfColumnWidths', ...
    [], ...
    @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x) && x > 0));

addParameter( ...
    p, ...
    'GridSize', ...
    [], ...
    @(x) isempty(x) || (isnumeric(x) && numel(x) == 2 && ...
    all(isfinite(x)) && all(x >= 1) && all(mod(x,1) == 0)));

addParameter( ...
    p, ...
    'GridGapFraction', ...
    0.035, ...
    @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0);

addParameter( ...
    p, ...
    'GridWidthScale', ...
    1.0, ...
    @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0);

addParameter( ...
    p, ...
    'GridHeightReferenceWidthScale', ...
    1.05, ...
    @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0);

addParameter( ...
    p, ...
    'GridHeightScale', ...
    0.92, ...
    @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0);

addParameter( ...
    p, ...
    'GridHorizontalGapFraction', ...
    0.055, ...
    @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0);

addParameter( ...
    p, ...
    'GridVerticalGapFraction', ...
    0.035, ...
    @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0);

addParameter( ...
    p, ...
    'FigureNumber', ...
    [], ...
    @(x) isempty(x) || ...
    (isnumeric(x) && isscalar(x)));

addParameter( ...
    p, ...
    'PosterFontSize', ...
    32, ...
    @(x) isnumeric(x) && isscalar(x) && x > 0);

addParameter( ...
    p, ...
    'TitleSpace', ...
    false, ...
    @(x) islogical(x) && isscalar(x));

addParameter( ...
    p, ...
    'Visible', ...
    'on', ...
    @(x) any(strcmpi(x, {'on', 'off'})));

addParameter( ...
    p, ...
    'Position', ...
    [], ...
    @(x) isempty(x) || ...
    (isnumeric(x) && numel(x) == 4));

parse(p, mode, varargin{:});

mode = lower(char(p.Results.mode));
figure_shape = lower(char(p.Results.FigureShape));
width_in_half_columns = double(p.Results.WidthInHalfColumns);
panel_span = [width_in_half_columns 1];
height_in_half_column_widths = p.Results.HeightInHalfColumnWidths;
if ~isempty(height_in_half_column_widths)
    height_in_half_column_widths = double(height_in_half_column_widths);
end
grid_size = double(p.Results.GridSize(:).');
grid_gap_fraction = double(p.Results.GridGapFraction);
grid_width_scale = double(p.Results.GridWidthScale);
grid_height_reference_width_scale = double(p.Results.GridHeightReferenceWidthScale);
grid_height_scale = double(p.Results.GridHeightScale);
grid_horizontal_gap_fraction = double(p.Results.GridHorizontalGapFraction);
grid_vertical_gap_fraction = double(p.Results.GridVerticalGapFraction);

%% Color palette

% Main binocular-rivalry colors
S.colors.conscious = hex2rgb_local('#FCAE34');
S.colors.suppressed = hex2rgb_local('#543379');

% Additional restrained colors
S.colors.blue = hex2rgb_local('#3B6FB6');
S.colors.sky = hex2rgb_local('#56B4E9');
S.colors.green = hex2rgb_local('#3A923A');
S.colors.vermilion = hex2rgb_local('#D55E00');
S.colors.red = hex2rgb_local('#C44E52');
S.colors.purple = hex2rgb_local('#8172B2');
S.colors.teal = hex2rgb_local('#2A9D8F');

% Neutral colors
S.colors.black = [0 0 0];
S.colors.dark = hex2rgb_local('#222222');
S.colors.axis_gray = hex2rgb_local('#333333');
S.colors.gray = hex2rgb_local('#7A7A7A');
S.colors.reference = hex2rgb_local('#A6A6A6');
S.colors.light_gray = hex2rgb_local('#D9D9D9');
S.colors.fill_gray = hex2rgb_local('#E8E8E8');
S.colors.near_white = hex2rgb_local('#F6F6F6');
S.colors.white = [1 1 1];

%% Mode-specific defaults

switch mode

    case 'nature'

        S.mode = 'nature';

        %% Typography

        S.font_name = 'Arial';

        S.font_size = 6;
        S.label_font_size = 6;
        S.title_font_size = 7;

        %% Original plotting allocation

        original_plot_width = 1.45;
        original_plot_height = 1.45;
        default_panel_gap = 0.12;

        %% Main plotted objects

        S.line_width = 1.0;
        S.thick_line_width = 2;
        S.reference_line_width = 0.5;

        %% Axes

        S.axes_line_width = 0.5;
        S.tick_length = [0.025 0.025];

        %% Markers

        S.marker_size = 5.5;
        S.large_marker_size = 7.5;
        S.scatter_size = 24;

        %% Error bars

        S.errorbar_line_width = 1.4;
        S.errorbar_cap_size = 5;

        %% Bars and histograms

        S.bar_line_width = 0.75;
        S.histogram_line_width = 0.75;

        %% Transparency

        S.shaded_alpha = 0.22;
        S.scatter_alpha = 0.75;
        S.face_alpha = 0.85;

        %% Margins

        S.margin_left = 0.50;
        S.margin_right = 0.16;
        S.margin_bottom = 0.43;
        S.margin_top = 0.18;

        if p.Results.TitleSpace
            S.margin_top = 0.32;
        end

        %% Legend

        S.legend_token_size = 10;

        %% Export

        S.png_resolution = 600;

        %% On-screen placement

        % Larger values move the figure farther downward from the top of
        % the monitor.
        S.screen_top_clearance = 0.65;
        S.screen_bottom_clearance = 0.20;

    case 'poster'

        S.mode = 'poster';

        %% Typography

        S.font_name = 'Calibri';

        S.font_size = p.Results.PosterFontSize;
        S.label_font_size = p.Results.PosterFontSize;

        S.title_font_size = ...
            round(1.15 * p.Results.PosterFontSize);

        %% Half-column poster plotting allocation

        % The earlier full-column plot was 8.7 inches wide.
        % This version is half that width.
        original_plot_width = 4.35;
        original_plot_height = 4.35;
        default_panel_gap = 0.35;

        %% Main plotted objects

        S.line_width           = 3.0;
        S.thick_line_width     = 5.0;
        S.reference_line_width = 2.0;

        S.axes_line_width      = 1.6;

        S.errorbar_line_width  = 3.2;
        S.bar_line_width       = 1.6;
        S.histogram_line_width = 1.6;
        %% Axes

        S.axes_line_width = 2.0;
        S.tick_length = [0.018 0.018];

        %% Markers

        S.marker_size = 13;
        S.large_marker_size = 17;
        S.scatter_size = 150;

        %% Error bars

        S.errorbar_line_width = 4.0;
        S.errorbar_cap_size = 13;

        %% Bars and histograms

        S.bar_line_width = 2.0;
        S.histogram_line_width = 2.0;

        %% Transparency

        S.shaded_alpha = 0.24;
        S.scatter_alpha = 0.80;
        S.face_alpha = 0.88;

        %% Half-column margins

        S.margin_left = 1.025;
        S.margin_right = 0.325;
        S.margin_bottom = 0.825;
        S.margin_top = 0.350;

        if p.Results.TitleSpace
            S.margin_top = 0.675;
        end

        %% Legend

        S.legend_token_size = 30;

        %% Export

        S.png_resolution = 300;

        %% On-screen placement

        S.screen_top_clearance = 0.85;
        S.screen_bottom_clearance = 0.25;

    otherwise

        error( ...
            'make_standard_figure_width_units_v5:InvalidMode', ...
            'Mode must be either "nature" or "poster".');
end

% Physical width of one standard half-column panel. This reference is
% defined before FigureShape or WidthInHalfColumns modifies the plotting allocation.
standard_half_column_width = ...
    S.margin_left + original_plot_width + S.margin_right;

%% Adjust plotting allocation for figure shape

switch figure_shape

    case 'square'

        % No change.

    case 'wide'

        original_plot_width = ...
            1.45 * original_plot_width;

    case 'tall'

        original_plot_height = ...
            1.45 * original_plot_height;

    otherwise

        error( ...
            'make_standard_figure_width_units_v5:InvalidShape', ...
            'FigureShape must be square, wide, or tall.');
end

S.figure_shape = figure_shape;
S.width_in_half_columns = width_in_half_columns;
S.panel_span = panel_span; % retained internally for compatibility

if isempty(p.Results.PanelGap)
    S.panel_gap = default_panel_gap;
else
    S.panel_gap = p.Results.PanelGap;
end

% One standard panel is a half-column panel. Its complete physical width,
% including the normal outer margins, is the unit used for figure height.
half_column_width = standard_half_column_width;
S.half_column_width = half_column_width;
S.height_in_half_column_widths = height_in_half_column_widths;

% WidthInHalfColumns combines standard panel plotting allocations but retains one set
% of outer margins. This makes [2 1] a full column when the standard panel
% is half-column, in both Nature and poster modes.
original_plot_width = ...
    panel_span(1) * original_plot_width + ...
    (panel_span(1) - 1) * S.panel_gap;

original_plot_height = ...
    panel_span(2) * original_plot_height + ...
    (panel_span(2) - 1) * S.panel_gap;

%% Determine canvas and content geometry

if isempty(grid_size)

    % Standard single-axes behavior. First calculate the complete reference
    % geometry, then scale the vertical geometry to the requested physical
    % height. This guarantees that axes and margins always remain inside
    % the figure when HeightInHalfColumnWidths is changed.

    reference_figure_width = ...
        S.margin_left + ...
        original_plot_width + ...
        S.margin_right;

    reference_figure_height = ...
        S.margin_bottom + ...
        original_plot_height + ...
        S.margin_top;

    S.plot_scale = 0.90;

    reference_plot_width = ...
        S.plot_scale * original_plot_width;

    reference_plot_height = ...
        S.plot_scale * original_plot_height;

    extra_width = ...
        original_plot_width - reference_plot_width;

    extra_height = ...
        original_plot_height - reference_plot_height;

    reference_margin_left = ...
        S.margin_left + 0.70 * extra_width;

    reference_margin_right = ...
        S.margin_right + 0.30 * extra_width;

    reference_margin_bottom = ...
        S.margin_bottom + 0.65 * extra_height;

    reference_margin_top = ...
        S.margin_top + 0.35 * extra_height;

    % The width is controlled by FigureShape and WidthInHalfColumns.
    S.figure_width = reference_figure_width;

    % One half-column width is the default height, so a standard [1 1]
    % figure is square. Explicit values such as 0.7 scale the complete
    % vertical layout, not just the outer figure window.
    if isempty(height_in_half_column_widths)
        effective_height_in_half_columns = 1;
    else
        effective_height_in_half_columns = height_in_half_column_widths;
    end

    S.figure_height = ...
        effective_height_in_half_columns * half_column_width;

    S.height_in_half_column_widths = ...
        effective_height_in_half_columns;

    % Scale all vertical dimensions together. Horizontal dimensions remain
    % unchanged, which is the intended behavior of a height-only option.
    vertical_scale = ...
        S.figure_height / reference_figure_height;

    S.margin_left = reference_margin_left;
    S.margin_right = reference_margin_right;
    S.margin_bottom = reference_margin_bottom * vertical_scale;
    S.margin_top = reference_margin_top * vertical_scale;

    S.plot_width = reference_plot_width;
    S.plot_height = reference_plot_height * vertical_scale;

    S.axes_position = [ ...
        S.margin_left, ...
        S.margin_bottom, ...
        S.plot_width, ...
        S.plot_height];

    S.content_position = S.axes_position;
    S.grid_size = [];
    S.grid_gap_fraction = [];

else

    % Compact grid behavior. Keep the mode- and PanelSpan-dependent width,
    % but derive the height from the requested grid so square cells occupy
    % nearly the full canvas rather than being centered in a square panel.
    number_of_rows = grid_size(1);
    number_of_columns = grid_size(2);

    switch mode
        case 'nature'
            compact_outer_margin = 0.055;
        case 'poster'
            compact_outer_margin = 0.18;
    end

    base_figure_width = ...
        S.margin_left + ...
        original_plot_width + ...
        S.margin_right;

    % Width and height are deliberately decoupled. GridWidthScale changes
    % only the canvas width. The height is computed from a fixed reference
    % width so increasing width adds horizontal breathing room rather than
    % making the figure taller.
    S.figure_width = grid_width_scale * base_figure_width;

    content_width = ...
        S.figure_width - 2 * compact_outer_margin;

    reference_content_width = ...
        grid_height_reference_width_scale * base_figure_width - ...
        2 * compact_outer_margin;

    % If c is cell width and g is a fraction of c, derive the fixed height
    % from the reference width, not from the final widened canvas.
    reference_cell_width = reference_content_width / ...
        (number_of_columns + ...
         (number_of_columns - 1) * grid_horizontal_gap_fraction);

    ideal_content_height = reference_cell_width * ...
        (number_of_rows + ...
         (number_of_rows - 1) * grid_vertical_gap_fraction);

    automatic_grid_height = grid_height_scale * ...
        (ideal_content_height + 2 * compact_outer_margin);

    if isempty(height_in_half_column_widths)
        % Preserve the tuned pre-height-option reconstruction geometry.
        S.figure_height = automatic_grid_height;
        S.height_in_half_column_widths = S.figure_height / half_column_width;
    else
        S.figure_height = height_in_half_column_widths * half_column_width;
        S.height_in_half_column_widths = height_in_half_column_widths;
    end

    content_height = S.figure_height - 2 * compact_outer_margin;

    S.margin_left = compact_outer_margin;
    S.margin_right = compact_outer_margin;
    S.margin_bottom = compact_outer_margin;
    S.margin_top = compact_outer_margin;

    S.plot_scale = 1;
    S.plot_width = content_width;
    S.plot_height = content_height;

    S.axes_position = [ ...
        compact_outer_margin, ...
        compact_outer_margin, ...
        content_width, ...
        content_height];

    S.content_position = S.axes_position;
    S.grid_size = grid_size;
    S.grid_gap_fraction = grid_gap_fraction;
    S.grid_horizontal_gap_fraction = grid_horizontal_gap_fraction;
    S.grid_vertical_gap_fraction = grid_vertical_gap_fraction;
    S.grid_width_scale = grid_width_scale;
    S.grid_height_reference_width_scale = grid_height_reference_width_scale;
    S.grid_height_scale = grid_height_scale;
end

%% Additional appearance settings

S.axis_color = S.colors.axis_gray;
S.text_color = S.colors.dark;

S.tick_direction = 'out';
S.interpreter = 'none';

S.default_colormap = parula(256);

S.grid_alpha = 0.12;
S.minor_grid_alpha = 0.07;

S.legend_location = 'best';
S.legend_box = 'off';

% Use white for the interactive MATLAB preview.
%
% Export transparency is controlled separately by exportgraphics.
S.preview_background_color = S.colors.white;

%% Create or reset figure

if isempty(p.Results.FigureNumber)

    fig = figure( ...
        'Color', S.preview_background_color, ...
        'Visible', p.Results.Visible, ...
        'Units', 'inches', ...
        'Renderer', 'painters', ...
        'InvertHardcopy', 'off', ...
        'WindowStyle', 'normal');

else

    fig = figure(p.Results.FigureNumber);

    clf(fig);

    set(fig, ...
        'Color', S.preview_background_color, ...
        'Visible', p.Results.Visible, ...
        'Units', 'inches', ...
        'Renderer', 'painters', ...
        'InvertHardcopy', 'off', ...
        'WindowStyle', 'normal');
end

%% Set the on-screen figure size and position

if isempty(p.Results.Position)

    current_position = get(fig, 'Position');

    % Preserve MATLAB's current horizontal location where possible.
    figure_left = current_position(1);

    % Read monitor dimensions in inches.
    original_root_units = get(groot, 'Units');

    cleanup_root_units = onCleanup( ...
        @() set(groot, 'Units', original_root_units));

    set(groot, 'Units', 'inches');

    screen_position = get(groot, 'ScreenSize');

    screen_left = screen_position(1);
    screen_bottom = screen_position(2);
    screen_width = screen_position(3);
    screen_height = screen_position(4);

    % Keep the figure horizontally visible.
    minimum_left = ...
        screen_left + 0.20;

    maximum_left = ...
        screen_left + ...
        screen_width - ...
        S.figure_width - ...
        0.20;

    figure_left = max(figure_left, minimum_left);
    figure_left = min(figure_left, maximum_left);

    % Anchor the top of the window below the top of the monitor.
    %
    % The physical figure dimensions remain unchanged.
    figure_bottom = ...
        screen_bottom + ...
        screen_height - ...
        S.figure_height - ...
        S.screen_top_clearance;

    minimum_bottom = ...
        screen_bottom + ...
        S.screen_bottom_clearance;

    % When the complete figure fits on the monitor, keep it above the
    % minimum bottom position.
    required_screen_height = ...
        S.figure_height + ...
        S.screen_top_clearance + ...
        S.screen_bottom_clearance;

    if required_screen_height <= screen_height

        figure_bottom = ...
            max(figure_bottom, minimum_bottom);
    end

    set(fig, ...
        'Units', 'inches', ...
        'Position', [ ...
            figure_left, ...
            figure_bottom, ...
            S.figure_width, ...
            S.figure_height]);

else

    set(fig, ...
        'Units', 'inches', ...
        'Position', p.Results.Position);
end

%% Configure physical output dimensions

set(fig, ...
    'PaperUnits', 'inches', ...
    'PaperPositionMode', 'manual', ...
    'PaperPosition', [ ...
        0, ...
        0, ...
        S.figure_width, ...
        S.figure_height], ...
    'PaperSize', [ ...
        S.figure_width, ...
        S.figure_height]);

%% Set figure-local graphics defaults

% These defaults apply to objects created after this point.

set(fig, ...
    'DefaultAxesFontName', S.font_name, ...
    'DefaultAxesFontSize', S.font_size, ...
    'DefaultAxesFontWeight', 'normal', ...
    'DefaultAxesLineWidth', S.axes_line_width, ...
    'DefaultAxesBox', 'off', ...
    'DefaultAxesTickDir', S.tick_direction, ...
    'DefaultAxesColor', 'none', ...
    'DefaultAxesXColor', S.axis_color, ...
    'DefaultAxesYColor', S.axis_color, ...
    'DefaultTextFontName', S.font_name, ...
    'DefaultTextFontSize', S.font_size, ...
    'DefaultTextFontWeight', 'normal', ...
    'DefaultTextColor', S.text_color, ...
    'DefaultTextInterpreter', S.interpreter, ...
    'DefaultLineLineWidth', S.line_width, ...
    'DefaultLineMarkerSize', S.marker_size, ...
    'DefaultLegendFontName', S.font_name, ...
    'DefaultLegendFontSize', S.font_size, ...
    'DefaultLegendBox', 'off', ...
    'DefaultLegendColor', 'none', ...
    'DefaultLegendTextColor', S.text_color);

%% Create axes

ax = axes( ...
    'Parent', fig, ...
    'Units', 'inches', ...
    'Position', S.axes_position, ...
    'PositionConstraint', 'innerposition', ...
    'Color', 'none', ...
    'FontName', S.font_name, ...
    'FontSize', S.font_size, ...
    'FontWeight', 'normal', ...
    'LineWidth', S.axes_line_width, ...
    'Box', 'off', ...
    'TickDir', S.tick_direction, ...
    'TickLength', S.tick_length, ...
    'Layer', 'top', ...
    'XColor', S.axis_color, ...
    'YColor', S.axis_color);

hold(ax, 'on');
grid(ax, 'off');

%% Configure labels and title

set(ax.XLabel, ...
    'FontName', S.font_name, ...
    'FontSize', S.label_font_size, ...
    'FontWeight', 'normal', ...
    'Color', S.text_color, ...
    'Interpreter', S.interpreter);

set(ax.YLabel, ...
    'FontName', S.font_name, ...
    'FontSize', S.label_font_size, ...
    'FontWeight', 'normal', ...
    'Color', S.text_color, ...
    'Interpreter', S.interpreter);

set(ax.ZLabel, ...
    'FontName', S.font_name, ...
    'FontSize', S.label_font_size, ...
    'FontWeight', 'normal', ...
    'Color', S.text_color, ...
    'Interpreter', S.interpreter);

set(ax.Title, ...
    'FontName', S.font_name, ...
    'FontSize', S.title_font_size, ...
    'FontWeight', 'bold', ...
    'Color', S.text_color, ...
    'Interpreter', S.interpreter);

%% Helper plotting functions

S.plot = @(varargin) plot_with_style( ...
    S.line_width, ...
    S.marker_size, ...
    varargin{:});

S.plot_thick = @(varargin) plot_with_style( ...
    S.thick_line_width, ...
    S.large_marker_size, ...
    varargin{:});

S.plot_reference = @(varargin) plot_reference_with_style( ...
    S.reference_line_width, ...
    S.colors.reference, ...
    varargin{:});

S.yline = @(varargin) yline_with_style( ...
    S.reference_line_width, ...
    S.colors.reference, ...
    varargin{:});

S.xline = @(varargin) xline_with_style( ...
    S.reference_line_width, ...
    S.colors.reference, ...
    varargin{:});

S.identity_line = @(varargin) identity_line_with_style( ...
    ax, ...
    S.reference_line_width, ...
    S.colors.reference, ...
    varargin{:});

S.chance_line = @(chance_level, varargin) chance_line_with_style( ...
    ax, ...
    chance_level, ...
    S.reference_line_width, ...
    S.colors.reference, ...
    varargin{:});

S.scatter = @(varargin) scatter_with_style( ...
    S.scatter_size, ...
    S.scatter_alpha, ...
    varargin{:});

S.errorbar = @(varargin) errorbar_with_style( ...
    S.errorbar_line_width, ...
    S.errorbar_cap_size, ...
    S.marker_size, ...
    varargin{:});

S.bar = @(varargin) bar_with_style( ...
    S.bar_line_width, ...
    S.face_alpha, ...
    varargin{:});

S.histogram = @(varargin) histogram_with_style( ...
    S.histogram_line_width, ...
    S.face_alpha, ...
    varargin{:});

%% Store convenience values

S.fig = fig;
S.ax = ax;

S.mm_to_inches = 1 / 25.4;
S.inches_to_mm = 25.4;

end


%% Local helper functions

function h = plot_with_style( ...
    line_width, ...
    marker_size, ...
    varargin)

h = plot(varargin{:});

set(h, ...
    'LineWidth', line_width, ...
    'MarkerSize', marker_size);

end


function h = plot_reference_with_style( ...
    line_width, ...
    reference_color, ...
    varargin)

h = plot(varargin{:});

set(h, ...
    'LineStyle', '--', ...
    'Color', reference_color, ...
    'LineWidth', line_width);

end


function h = yline_with_style( ...
    line_width, ...
    reference_color, ...
    varargin)

h = yline(varargin{:});

set(h, ...
    'LineStyle', '--', ...
    'Color', reference_color, ...
    'LineWidth', line_width);

end


function h = xline_with_style( ...
    line_width, ...
    reference_color, ...
    varargin)

h = xline(varargin{:});

set(h, ...
    'LineStyle', '--', ...
    'Color', reference_color, ...
    'LineWidth', line_width);

end


function h = identity_line_with_style( ...
    ax, ...
    line_width, ...
    reference_color, ...
    varargin)

axis_limits = [ ...
    max(ax.XLim(1), ax.YLim(1)), ...
    min(ax.XLim(2), ax.YLim(2))];

h = plot(ax, axis_limits, axis_limits, varargin{:});

set(h, ...
    'LineStyle', '--', ...
    'Color', reference_color, ...
    'LineWidth', line_width);

end


function h = chance_line_with_style( ...
    ax, ...
    chance_level, ...
    line_width, ...
    reference_color, ...
    varargin)

h = yline(ax, chance_level, varargin{:});

set(h, ...
    'LineStyle', '--', ...
    'Color', reference_color, ...
    'LineWidth', line_width);

end


function h = scatter_with_style( ...
    scatter_size, ...
    scatter_alpha, ...
    varargin)

h = scatter(varargin{:});

set(h, ...
    'SizeData', scatter_size);

if isprop(h, 'MarkerFaceAlpha')
    h.MarkerFaceAlpha = scatter_alpha;
end

if isprop(h, 'MarkerEdgeAlpha')
    h.MarkerEdgeAlpha = scatter_alpha;
end

end


function h = errorbar_with_style( ...
    line_width, ...
    cap_size, ...
    marker_size, ...
    varargin)

h = errorbar(varargin{:});

set(h, ...
    'LineWidth', line_width, ...
    'CapSize', cap_size, ...
    'MarkerSize', marker_size);

end


function h = bar_with_style( ...
    line_width, ...
    face_alpha, ...
    varargin)

h = bar(varargin{:});

set(h, ...
    'LineWidth', line_width, ...
    'FaceAlpha', face_alpha);

end


function h = histogram_with_style( ...
    line_width, ...
    face_alpha, ...
    varargin)

h = histogram(varargin{:});

set(h, ...
    'LineWidth', line_width, ...
    'FaceAlpha', face_alpha);

end


function rgb = hex2rgb_local(hex_string)

hex_string = char(hex_string);
hex_string = strrep(hex_string, '#', '');

if numel(hex_string) ~= 6

    error( ...
        'make_standard_figure_width_units_v5:InvalidHexColor', ...
        ['Hex color must contain exactly six hexadecimal ', ...
         'characters.']);
end

rgb = [ ...
    hex2dec(hex_string(1:2)), ...
    hex2dec(hex_string(3:4)), ...
    hex2dec(hex_string(5:6))] ./ 255;

end