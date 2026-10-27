# AGENTS.md

Guidance for AI coding agents working in `conscious_suppressed_alternations`.

## Project

Data analysis code for the preprint "Rapid alternation of conscious and 
suppressed stimulus representations in the primate brain" (Janis K. Hesse, 
Frank F. Lafranchi, Conor McGrory, Yuelin Shi, Tatiana A. Engel, Doris Y. Tsao,
2026), which can be found online 
[here](https://doi.org/10.64898/2026.10.15.759299) or in this repository at
`docs/Hesse_et_al_conscious_suppressed_alternations_submission_bioarxiv.pdf`.
The experimental data is stored in MATLAB files, which can be downloaded from
**TODO: INSERT ZENODO LINK**. Once these files are downloaded, a series of 
Python and MATLAB scripts can be used to reproduce the main figures of the 
paper. The Python pipelines are run with `python/scripts/step2_run_pipeline.py`,
their parameters are in
`config/<pipeline>.yaml`, and they write their outputs to `data/<pipeline>/`. 

## Environment & commands

- Project code is written in Python (requires Python >=3.11) and MATLAB
- Project uses `uv` for python depedency management:
  - `uv sync`: install deps + the local packages `percept_hmm` and 
    `tsao_lab_data` into `.venv`
  - `uv run python python/scripts/...`: run a script in the environment
  - `uv run pytest`: run the test suite (tests live in `python/tests/`)
- Python environment managed by `uv` is installed in directory `.venv`
- One dependency installs from git source, so installs can fail on network or
  upstream breakage: `hmmlearn` (hmmlearn/hmmlearn). See `[tool.uv.sources]` 
  in `pyproject.toml`.

## Layout

- `data/`: Directory where downloaded data is placed, and where pipelines are
   run and intermediate steps are stored. Gitignored apart from `.gitkeep` files
   that preserve the pipeline directory layout (see `.gitignore`)
- `config/`: Parameter files for the Python pipelines (`<pipeline>.yaml`) and
   the recording lists they run over (`recording_lists/`)
- `matlab/`: MATLAB code
- `python/src/tsao_lab_data/`: First installed Pyton package: Classes and 
   functions for loading data from extracted HDF5 files.
- `python/src/percept_hmm/`: Second installed Python package: reusable helpers 
   for pipelines, stats, and model fitting
- `python/scripts/`: Code for pipelines
- `python/tests/` — pytest tests for Python code mirroring package modules

## Pipelines

- Mature analyses that we want to be able to reproduce are implemented as
  pipelines, defined in `python/scripts/step2_run_pipeline.py` (stage order, scripts,
  recording lists, and input/output files for each stage)
- Each pipeline runs in a subdirectory of `data/` (e.g. `data/fixed_hmm`),
  where each stage writes its outputs to its own subdirectory. Parameters are in
  `config/<pipeline>.yaml`, and recording lists shared by pipelines are in
  `config/recording_lists/`
- The scripts for a given pipeline are stored in a subdirectory of
  `python/scripts/` with the same name (e.g. `python/scripts/fixed_hmm`), and
  pipeline-specific helper functions are in `percept_hmm.pipelines.<pipeline>`.
  Scripts used by multiple pipelines are stored in `python/scripts/fs_rivalry`

## Conventions

- **`# %%` comments are VSCode Interactive Mode cell markers, not dead code.**
  Do not delete or "clean them up." They let scripts run cell-by-cell like a
  notebook.
- **All scripts run from the repository root.** Paths in `config/*.yaml` are
  relative to the root, and pipeline scripts default `--params` to
  `config/<pipeline>.yaml` (scripts shared between pipelines in
  `python/scripts/fs_rivalry` require `--params`). Don't add `%cd` or `chdir`.
- Formatting is `ruff`: Line length **100**, **single quotes**, 4-space indent
  (see `[tool.ruff]` in `pyproject.toml`). Match existing style.
- **Data:** Data is distributed separately (see `.gitignore`) — don't commit
  large data files to git.
