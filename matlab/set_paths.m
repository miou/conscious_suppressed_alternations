function paths = set_paths()
%SET_PATHS  Central path configuration for the conscious/suppressed figure release.
%
%  The MATLAB code lives in <repo>/matlab; data/ and figures_output/ sit at the
%  repo root. Both roots are derived from this file's location, so the whole
%  bundle can be moved anywhere without editing any path.
%
%  Call once at the top of any figure script:
%       paths = set_paths;
%       load(fullfile(paths.sessions,'session_01.mat'));

PROJECT_ROOT = fileparts(mfilename('fullpath'));   % <repo>/matlab — the MATLAB code
REPO_ROOT    = fileparts(PROJECT_ROOT);            % repo root — holds data/ and figures_output/

% ---- change only if the data lives outside the bundle --------------------
DATA_ROOT = fullfile(REPO_ROOT,'data');
% --------------------------------------------------------------------------

paths = struct();
paths.project_root   = PROJECT_ROOT;
paths.data_root      = DATA_ROOT;
paths.sessions       = fullfile(DATA_ROOT,'sessions');          % session_01.mat ... session_19.mat
paths.conor_states   = fullfile(DATA_ROOT,'conor_states');      % LLR/HMM outputs from the Python pipeline (step 2)
paths.stimulus_model = fullfile(DATA_ROOT,'monkey_face_model'); % face-feature model used for reconstruction
paths.stimuli        = fullfile(DATA_ROOT,'stimuli');           % stimulus images (for step-1 export)
paths.human          = fullfile(DATA_ROOT,'human');             % human psychophysics
paths.misc           = fullfile(DATA_ROOT,'misc');              % other precomputed inputs (e.g. acorr_projection.mat)
paths.results        = fullfile(DATA_ROOT,'results');           % saved flash_suppression_results (step 3), loaded by figures
paths.conor_summaries = fullfile(DATA_ROOT,'conor_summaries');  % Conor's dynamics data products (psth/acorr/loglik), shipped
paths.h5_export      = fullfile(DATA_ROOT,'h5_for_conor');      % step-1 HDF5 export, input to the Python pipeline
paths.figures_out    = fullfile(REPO_ROOT,'figures_output');    % all generated panels go here (repo root)

if ~exist(paths.figures_out,'dir'); mkdir(paths.figures_out); end

addpath( ...
    PROJECT_ROOT, ...
    fullfile(PROJECT_ROOT,'config'), ...
    fullfile(PROJECT_ROOT,'step1_export'), ...
    fullfile(PROJECT_ROOT,'attach_states'), ...
    fullfile(PROJECT_ROOT,'per_session'), ...
    fullfile(PROJECT_ROOT,'across_sessions'), ...
    fullfile(PROJECT_ROOT,'figures'), ...
    fullfile(PROJECT_ROOT,'helpers'));
end
