# Release notes — data distribution

Code for Hesse et al., "Rapid alternation of conscious and suppressed stimulus representations
in the primate brain" (2026, bioRxiv). The code lives in this repository; the data is
distributed separately (see below) because of its size.

## What's in the data release

The data archive (~31 GB, 25 files — within Zenodo's 200 GB / 100-file limits) contains:

- **`sessions/`** — 19 recording sessions (`session_<date>_<monkey>.mat`), gzip-compressed
  (v7.3). Each holds the per-trial spike raster, the concatenated spike timecourse, per-probe
  LFP, eye traces, stimulus indices, and inferred-state fields. ~50–80× smaller than the raw
  files with no loss to these fields.
- **`results.tar.gz`** — pooled per-session and across-session summaries (reconstruction axes,
  explained variance, decoding, modulation) that the figure scripts load.
- **`conor_states.tar.gz`** — the per-bin conscious/suppressed state partitions from the
  Python LLR/HMM pipeline (step 2).
- **`conor_summaries.tar.gz`**, **`human.tar.gz`** — auxiliary summaries and the human
  psychophysics (Fig. 1).
- **`monkey_face_model`** — the face-feature model used for reconstruction.
- **`misc`** — other small precomputed inputs.

Unpack the `.tar.gz` archives into `data/` so the layout matches `set_paths.m`.

## Not included (available on request)

These are omitted to stay within the repository/archive size limits; none are needed to
reproduce the figures:

- **Channel-resolved LFP.** Each session also has a per-channel LFP (768 channels, ~14 GB/session,
  ~1.16 TB total; still ~0.5–0.6 TB even compressed, since LFP is broadband and compresses only
  ~2×), which exceeds Zenodo's 200 GB cap. The **per-probe LFP is included**; the channel-resolved
  LFP is available on request.
- **Raw stimulus images.** The pipeline uses stimulus *indices* plus the included face-feature
  model, not the raw images, so they are not shipped. Available on request.
- **HDF5 exports (`h5_for_conor/`).** These are the input to the Python state-inference pipeline
  and are **regenerable** from the sessions via step 1 (`step1_export/step1_export_sessions.m`).
- **Non-compressed sessions.** The full uncompressed session files are available on request.

## Reproducing

- **Figures only:** unpack `results.tar.gz` (and `conor_states.tar.gz`, `human.tar.gz`,
  `monkey_face_model`), then run any `figures/generate_fig_*.m`.
- **Full pipeline:** sessions → step 1 (export HDF5) → step 2 (Python state inference) →
  step 3 (attach states) → step 4 (per-session state-conditioned responses) → step 5 (combine) →
  step 6 (figures). See the README for the step-by-step.

## Notes on exact reproduction

All deterministic statistics reproduce the paper exactly (e.g. the reconstruction dissociation,
t(29)=48.5; modulation r=0.45). The single-trial decoding panels (Fig. 2l, 3i) use a
cross-validated decoder whose random fold assignment makes the exact t-values vary slightly
between runs while the effect and significance are unchanged.
