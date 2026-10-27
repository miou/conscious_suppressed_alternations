# Release notes — data distribution

Code for Hesse et al., "Rapid alternation of conscious and suppressed stimulus representations
in the primate brain" (2026, bioRxiv). The code lives in this repository; the data is
distributed separately (see below) because of its size.

**Zenodo:** https://doi.org/10.5281/zenodo.23604908 (concept DOI — always resolves to the latest
version)

## What's in the data release

The data is in two parts on Zenodo, both within its size limits:

- **The 19 recording sessions** — individual `session_<date>_<monkey>.mat` files
  (e.g. `session_250225_Alfie.mat`), roughly 0.2–2.7 GB each, gzip-compressed (v7.3). Each holds
  the per-trial spike raster, the concatenated spike timecourse, per-probe LFP, eye traces,
  stimulus indices, and inferred-state fields. Download them into `data/sessions/`.
- **The data bundle** — `data.zip` (~2.1 GB). Unzip it at the repository root; it fills in the
  pooled summaries the figures load (`data/results/`) plus the inputs that cannot be regenerated:
  `data/python_summaries/` (dynamics summaries), `data/stimuli/` (stimulus feature maps),
  `data/monkey_face_model/` (the face-feature model, which also regenerates the stimulus face
  images from the feature maps), and `data/human/` (the human psychophysics, Fig. 1).

The derivable intermediates — `sessions_h5/` (step 1), `python_states/` (step 2), and
`data/results/per_session_*/` (step 3) — are not in the bundle; the pipeline regenerates them
from the session `.mat` files.

## Not included (available on request)

These are omitted to stay within the repository/archive size limits; none are needed to
reproduce the figures:

- **Channel-resolved LFP.** Each session also has a per-channel LFP (768 channels, ~14 GB/session,
  ~1.16 TB total; still ~0.5–0.6 TB even compressed, since LFP is broadband and compresses only
  ~2×), which exceeds Zenodo's 200 GB cap. The **per-probe LFP is included**; the channel-resolved
  LFP is available on request.
- **HDF5 exports (`sessions_h5/`).** These are the input to the Python state-inference pipeline
  and are **regenerable** from the sessions via step 1 (`step1_export/step1_export_sessions.m`).
- **Non-compressed sessions.** The full uncompressed session files are available on request.

## Reproducing

- **Figures only:** unzip `data.zip` at the repository root, then run any
  `step5_figures/generate_fig_*.m`. The shipped summaries already contain the state-conditioned
  responses, so steps 1–4 can be skipped entirely.
- **Full pipeline:** sessions → step 1 (export HDF5) → step 2 (Python state inference) →
  step 3 (per-session state-conditioned responses; states attached in memory on load) →
  step 4 (pool across sessions) → step 5 (figures). See the README for the step-by-step.

## Notes on exact reproduction

All deterministic statistics reproduce the paper exactly (e.g. the reconstruction dissociation,
t(29)=48.5; modulation r=0.45). The single-trial decoding panels (Fig. 2l, 3i) use a
cross-validated decoder whose random fold assignment makes the exact t-values vary slightly
between runs while the effect and significance are unchanged.
