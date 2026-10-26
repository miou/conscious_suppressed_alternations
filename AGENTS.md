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
paper. These pipelines are coordinated and run using 
[Data Version Control](https://dvc.org/), and the DVC files are stored with the
data in `pipelines/`. 

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

- `data/`: Directory where downloaded data is placed
- `pipelines/`: Directory where pipelines are run and intermediate steps are
   stored
- `matlab/`: MATLAB code
- `python/src/tsao_lab_data/`: First installed Pyton package: Classes and 
   functions for loading data from extracted HDF5 files.
- `python/src/percept_hmm/`: Second installed Python package: reusable helpers 
   for pipelines, stats, and model fitting
- `python/scripts/`: Code for pipelines
- `python/tests/` — pytest tests for Python code mirroring package modules

## DVC pipelines

- Mature analyses that we want to be able to reproduce are implemented as data
  version control (DVC) pipelines 
- Each pipeline is stored in a subdirectory in `pipelines/` (e.g.
  `data/fixed_hmm_fs`), along with the `params.yaml` and `dvc.yaml` files that
  specify it
- The scripts for a given pipeline are typically stored in a subdirectory of
  `scripts/` with the same name as the DVC pipeline directory (e.g. the scripts
  for the `data/fixed_hmm_fs` pipeline are stored in `scripts/fixed_hmm_fs`). 
  Sometimes, scripts used by multiple pipelines are stored in a separate 
  subdirectory of `scripts/pipeline/` (e.g. `scripts/pipeline/fs_rivalry`)

## Conventions

- **`# %%` and `# %cd` comments are VSCode Interactive Mode cell markers, not
  dead code.** Do not delete or "clean them up." They let scripts run cell-by-cell
  like a notebook.
- Formatting is `ruff`: Line length **100**, **single quotes**, 4-space indent
  (see `[tool.ruff]` in `pyproject.toml`). Match existing style.
- **Data & tracking infra:** Data versioning and experiment tracking is done
  with **DVC** (remote `tsao_lab_cluster`, see `.dvc/config`) — don't commit
  large data files to git.
