# Conscious / suppressed alternations

This repository contains the code for the preprint "Rapid alternation of conscious and
suppressed stimulus representations in the primate brain" (Hesse et al., 2026, bioRxiv).

It reproduces the main paper figures from the per-session recordings. The state inference
(LLR / HMM) runs in Python (step 2) and is part of this repository (added separately by
C. McGrory). The MATLAB code exports what that pipeline needs, attaches its output, computes
state-conditioned responses, pools across sessions, and draws the figures.

**Scope of this release.** To make the data and code available promptly alongside the bioRxiv
preprint, this is an initial release covering the **main figures** only, and the code is not yet
fully polished. A later release will add the extended data figures, a cleaned-up version of the
code, and reduced memory and compute requirements so the analysis is accessible on a wider range
of machines.

## Pipeline

```
 session_01.mat … session_19.mat
        │  step 1   export each session to HDF5
        ▼
   data/h5_for_conor/*.h5
        │  step 2   Python LLR/HMM state inference  (in this repo; C. McGrory)
        ▼
   data/conor_states/        per-bin conscious/suppressed state partition
        │  step 3   per-session state-conditioned responses  (states attached in memory on load)
        ▼
   data/results/per_session_*/
        │  step 4   pool across sessions
        ▼
   data/results/{axes,modulation,trial_decoding_full}/   (pooled summaries)
        │  step 5   generate figure panels
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
   suppressed (state 2) partition to `data/conor_states/` that step 3 loads.

3. **Per-session state-conditioned responses** — run all three. Each loads one session and
   attaches the Python states in memory (via `switches_infer_states`), so there is no separate
   attach-and-save step.
   - `step3_run_and_save_results.m` — responses averaged *within each state* over the 300–1000 ms
     binocular window (the inputs to reconstruction / explained-variance / decoding)
     → `data/results/per_session_responses/`.
   - `step3_run_and_save_modulation.m` — state-conditioned modulation indices and single-trial
     decoding, using the half-neuron (cross-neuron) control (states inferred from one neuron
     half, measured on the other) → `data/results/per_session_modulation/`.
   - `step3_run_and_save_trial_decoding_full.m` — full-population IT single-trial decoding (Fig. 2l)
     → `data/results/per_session_trialdec_full/`.

4. **Pool across sessions** — in `across_sessions/`:
   `step4_combine_responses.m`, `step4_combine_modulation.m`, `step4_combine_trial_decoding_full.m`
   → pooled per-state summaries in `data/results/{axes,modulation,trial_decoding_full}/`.

5. **Figures** — `figures/generate_fig_*.m` (one panel each). Each loads the pooled summaries,
   pools / reconstructs across sessions via `across_sessions_analysis_axes_aux`, and writes to
   `figures_output/`. Independently runnable once steps 1–4 are done.

## Reproducibility

The shipped summaries contain the exact single-trial decoding values used for the paper
(Fig. 2l and Fig. 3i). Note that the single-trial decoding is **not seeded**: before decoding,
`flash_suppression_get_variables` balances stimuli shown at different frequencies by randomly
subsampling trials, so **regenerating the session summaries (steps 3–4) yields slightly
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
  results/             per-session results and pooled summaries (steps 3–4)
  monkey_face_model/   face-feature model (reconstruction figures)
  stimuli/             stimulus images
  human/               human psychophysics (figure 1)
  misc/                other precomputed inputs
```

## Requirements and run times

**To reproduce the figures** from the shipped summaries (step 5 only):
- RAM: ~4 GB (8 GB comfortable).
- Storage: ~4 GB (the pooled summaries in `data/results/` plus `monkey_face_model/`), or the full
  ~32 GB package if you also want to regenerate.
- Time: under a minute for most panels; the reconstruction / decoding figures (2, 3, 6) take
  ~7–14 min each because they fit the population model across sessions at figure time.
  The full set of main figures is ~1 hour.

**To regenerate the summaries from the recordings** (steps 1–4):
- RAM: the recording sessions decompress fully into memory. The reconstruction (`many_faces`)
  sessions are the largest at ~40 GB to load (measured), so budget ~48–64 GB with the per-session
  compute on top; the single-trial / modulation (`many_combinations`) sessions need ~16–24 GB.
  Sessions are processed one at a time.
- Storage: ~32 GB (compressed sessions + state files + summaries).
- Time: ~3–6 min to load each session, plus ~15–40 min per session for the response / decoding
  compute (compute-bound). The full 19-session regeneration is several hours.

These timings and the load-RAM figure were measured on a 32-core AMD Ryzen Threadripper PRO
7975WX workstation (4.0 GHz base, 5.3 GHz boost), MATLAB R2023b; expect longer run times on
machines with fewer or slower cores.

The channel-resolved LFP is not included (it exceeds the distribution size limit; the per-probe
LFP is included, the channel-resolved LFP is available on request). The HDF5 export in step 1 is
regenerated from the sessions, not shipped.

## Layout

```
matlab/                   MATLAB figure-generation code
  set_paths.m             path configuration (project root auto-detected)
  config/                 session list and summary configurations
  step1_export/           session → HDF5 export (step 1)
  attach_states/          state-inference machinery (switches_infer_states, state_method_hmm)
  run_and_save_*.m        per-session state-conditioned responses (step 3; attaches states on load)
  per_session/            per-session analysis (reconstruction, tuning, decoding, modulation)
  across_sessions/        combine_*.m pool per-session results (step 4); pooling helpers
  figures/                generate_fig_*.m — one panel each (step 5)
  helpers/                plotting and utility functions
python/, pipelines/       LLR/HMM state-inference pipeline (step 2; C. McGrory)
data/                     recordings, states, summaries (gitignored; distributed separately)
figures_output/           generated panels
```

## Sessions

Sessions are numbered `01`–`19`; each `session_NN.mat` is one recording session (two monkeys).
