function out_fpath = extract_session_to_hdf5(session, session_index, out_fpath)
% Extracts subset of data from session object and saves in HDF5 file
%
% Args:
%     session: Struct containing session data
%     out_fpath: Path to write HDF5 file to

% If output path isn't specified, use default analysis path from session object
if nargin < 3
    out_fpath = [session.analysis_path filesep 'session_' session.session_name '.h5'];
end

session.session_index = session_index;

fprintf('Session: %s\n', session.session_name);

% Add standardized variables to session object
fprintf('Adding standardized variables...\n');
session = add_standardized_vars(session);
fprintf('Done.\n');

% Save results to HDF5 file
fprintf('Saving results to %s...\n', out_fpath)
save_session_h5(session, out_fpath);
fprintf('Done.\n');

end
