# Conscious / suppressed alternations

This repository contains the code for the preprint "Rapid alternation of conscious and
suppressed stimulus representations in the primate brain" (Hesse et al., 2026, bioRxiv).

It reproduces the main paper figures from the per-session recordings. The state inference
(LLR / HMM) runs in Python (step 2) and is part of this repository (added separately by
C. McGrory). The MATLAB code exports what that pipeline needs, attaches its output, computes
state-conditioned responses, pools across sessions, and draws the figures.

## Pipeline

```
 session_01.mat … session_19.mat
        │  step 1   export each session to HDF5
        ▼
   data/h5_for_conor/*.h5
        │  step 2   Python LLR/HMM state inference  (in this repo; C. McGrory)
        ▼
   data/conor_states/        per-bin conscious/suppressed state partition
        │  step 3   attach the inferred states to each session
        ▼
   sessions with states
        │  step 4   per-session state-conditioned responses
        ▼
   data/results/per_session_*/
        │  step 5   pool across sessions
        ▼
   data/results/{axes,modulation,trial_decoding_full}/   (pooled summaries)
        │  step 6   generate figure panels
        ▼
     figures_output/
```

## What to run

The MATLAB code is in `matlab/`. In MATLAB, `cd matlab` then `paths = set_paths;` first (adds the
code folders to the path, returns data locations).
Steps are MATLAB unless noted; each `run_and_save_*` / `combine_*` loops all sessions (set the
variable `session_list` beforehand to restrict).

1. **Export** — `step1_export/step1_export_sessions.m`
   Writes one `data/h5_for_conor/session_<name>.h5` per session (spikes, stimulus indices, eye
   traces) for the state-inference pipeline.

2. **State inference (Python)** — C. McGrory's LLR/HMM pipeline (in this repository; directory
   added separately). Reads the `.h5` files and writes the per-bin conscious (state 1) /
   suppressed (state 2) partition to `data/conor_states/` that step 3 expects.

3. **Attach states** — `step3_attach_states/step3_attach_states_sessions.m`
   Loads the state files and attaches the inferred states to each session.

4. **Per-session state-conditioned responses** — run all three:
   - `run_and_save_results.m` — responses averaged *within each state* over the 300–1000 ms
     binocular window (the inputs to reconstruction / explained-variance / decoding)
     → `data/results/per_session_responses/`.
   - `run_and_save_modulation.m` — state-conditioned modulation indices and single-trial
     decoding, using the half-neuron (cross-neuron) control (states inferred from one neuron
     half, measured on the other) → `data/results/per_session_modulation/`.
   - `run_and_save_trial_decoding_full.m` — full-population IT single-trial decoding (Fig. 2l)
     → `data/results/per_session_trialdec_full/`.

5. **Pool across sessions** — in `across_sessions/`:
   `combine_responses.m`, `combine_modulation.m`, `combine_trial_decoding_full.m`
   → pooled per-state summaries in `data/results/{axes,modulation,trial_decoding_full}/`.

6. **Figures** — `figures/generate_fig_*.m` (one panel each). Each loads the pooled summaries,
   pools / reconstructs across sessions via `across_sessions_analysis_axes_aux`, and writes to
   `figures_output/`. Independently runnable once steps 1–5 are done.

## Reproducibility

The shipped summaries contain the exact single-trial decoding values used for the paper
(Fig. 2l and Fig. 3i). Note that the single-trial decoding is **not seeded**: before decoding,
`flash_suppression_get_variables` balances stimuli shown at different frequencies by randomly
subsampling trials, so **regenerating the session summaries (steps 4–5) yields slightly
different single-trial decoding values each time**. The effect sizes and significance are
unchanged — only the exact numbers move within the range reported in the paper. To reproduce
the paper's figures exactly, use the shipped summaries rather than regenerating them. Everything
else (reconstruction, explained variance, modulation) is unaffected by this.

## Setup

Keep this folder together (code + data + outputs in one place); `matlab/set_paths.m` finds
everything relative to itself (data/ and figures_output/ at the repo root), so the bundle can be
moved freely. Large data (`data/`) and generated
panels (`figures_output/`) are distributed separately and are gitignored. Data layout:

```
data/
  sessions/            session_01.mat … session_19.mat
  h5_for_conor/        step-1 HDF5 export (input to the Python pipeline)
  conor_states/        state files from the Python pipeline (step 2)
  results/             per-session results and pooled summaries (steps 4–5)
  monkey_face_model/   face-feature model (reconstruction figures)
  stimuli/             stimulus images
  human/               human psychophysics (figure 1)
  misc/                other precomputed inputs
```

## Layout

```
matlab/                   MATLAB figure-generation code
  set_paths.m             path configuration (project root auto-detected)
  config/                 session list and summary configurations
  step1_export/           session → HDF5 export (step 1)
  step3_attach_states/    load Python state files, attach to sessions (step 3)
  run_and_save_*.m        per-session state-conditioned responses (step 4)
  per_session/            per-session analysis (reconstruction, tuning, decoding, modulation)
  across_sessions/        combine_*.m pool per-session results (step 5); pooling helpers
  figures/                generate_fig_*.m — one panel each (step 6)
  helpers/                plotting and utility functions
python/, pipelines/       LLR/HMM state-inference pipeline (step 2; C. McGrory)
data/                     recordings, states, summaries (gitignored; distributed separately)
figures_output/           generated panels
```

## Sessions

Sessions are numbered `01`–`19`; each `session_NN.mat` is one recording session (two monkeys).
