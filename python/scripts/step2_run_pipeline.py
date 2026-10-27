"""Utility script for running pipelines.

Each pipeline writes its outputs to `data/<name>/`, with parameters from `config/<name>.yaml`.
Stages run in the order listed below. A stage runs its script once per recording in a recording list from
`config/recording_lists/fs_rivalry.yaml`, or once in total for stages that aggregate across
recordings. A job is skipped if all of its outputs already exist, so an interrupted run can be
resumed. Use `--force` to recompute outputs, e.g. after changing parameters.

Examples (from the repository root):

    uv run python python/scripts/step2_run_pipeline.py llr
    uv run python python/scripts/step2_run_pipeline.py llr --jobs 8
    uv run python python/scripts/step2_run_pipeline.py fixed_hmm --stages stats summary_stats --force
    uv run python python/scripts/step2_run_pipeline.py llr --sessions s133 s137 --dry-run
"""

import argparse
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path

import yaml

REPO_DIR = Path(__file__).resolve().parents[2]
DATA_DIR = REPO_DIR / 'data'
CONFIG_DIR = REPO_DIR / 'config'
RECORDING_LISTS = CONFIG_DIR / 'recording_lists' / 'fs_rivalry.yaml'


@dataclass(frozen=True)
class Stage:
    """One step of a pipeline.

    `script`, `ins` and `outs` are templates filled in with the `paths` section of the pipeline's
    config file and, for per-recording stages, `{session}`, `{paradigm}`, `{probes}` and `{rec}` (the
    recording filename stem `<session>_<paradigm>_<probes>`). Paths are relative to the repository
    root, which is where scripts are run from.
    """

    name: str
    script: str
    recs: str | None = None  # Recording list key; None means the stage runs once
    ins: tuple[str, ...] = ()
    outs: tuple[str, ...] = ()


# Inputs and outputs shared by most stages
H5 = '{data_dir}/{session}/session.h5'
EXTRACT = '{extract_data_dir}/{rec}.joblib'
PRED_ALL = '{pred_all_units_dir}/{rec}.joblib'
PRED_RANDOM_STIM = '{pred_random_stim_dir}/{rec}.joblib'
PRED_UNIT_SUBSET = '{pred_unit_subset_dir}/{rec}.joblib'

PIPELINES = {
    'fixed_hmm': [
        Stage(
            'extract_data',
            '{fs_script_dir}/extract_data.py',
            'rec_plot_it',
            ins=(H5,),
            outs=(EXTRACT,),
        ),
        Stage(
            'pred_all_units',
            '{script_dir}/pred_all_units.py',
            'rec_plot_it',
            ins=(EXTRACT,),
            outs=(PRED_ALL,),
        ),
        Stage(
            'pred_random_stim',
            '{script_dir}/pred_random_stim.py',
            'rec_it',
            ins=(EXTRACT,),
            outs=(PRED_RANDOM_STIM,),
        ),
        Stage(
            'pred_unit_subset',
            '{script_dir}/pred_unit_subset.py',
            'rec_it',
            ins=(EXTRACT,),
            outs=(PRED_UNIT_SUBSET,),
        ),
        Stage(
            'unit_subset_coherence',
            '{script_dir}/unit_subset_coherence.py',
            'rec_it',
            ins=(EXTRACT,),
            outs=(
                '{unit_subset_coherence_dir}/{rec}.json',
                '{unit_subset_coherence_dir}/data_{rec}.csv',
            ),
        ),
        # Also reads the single-probe files for each probe in the pair
        Stage(
            'probe_coherence',
            '{fs_script_dir}/probe_coherence.py',
            'rec_ml_am',
            ins=(EXTRACT, PRED_ALL),
            outs=('{probe_coherence_dir}/{rec}.json',),
        ),
        Stage(
            'fso_decoding',
            '{fs_script_dir}/fso_decoding.py',
            'rec_fso',
            ins=(EXTRACT, PRED_ALL),
            outs=('{fso_decoding_dir}/{rec}.json',),
        ),
        Stage(
            'stats',
            '{script_dir}/stats.py',
            'rec_it',
            ins=(EXTRACT, PRED_ALL),
            outs=('{stats_dir}/{rec}.json',),
        ),
        Stage(
            'dwell_time',
            '{script_dir}/dwell_time.py',
            'rec_it',
            ins=(EXTRACT, PRED_ALL),
            outs=('{dwell_time_dir}/{rec}.json',),
        ),
        Stage(
            'states_loglik',
            '{script_dir}/states_loglik.py',
            'rec_it',
            ins=(EXTRACT,),
            outs=('{states_loglik_dir}/{rec}.json',),
        ),
        Stage(
            'summary_stats',
            '{script_dir}/summary_stats.py',
            outs=('{summary_stats_dir}/summary_stats.json',),
        ),
        Stage(
            'compile_data',
            '{script_dir}/compile_data.py',
            'rec_it',
            ins=(H5, PRED_ALL, PRED_RANDOM_STIM, PRED_UNIT_SUBSET),
            outs=('{compile_data_dir}/{rec}.mat',),
        ),
    ],
    'llr': [
        Stage(
            'extract_data',
            '{fs_script_dir}/extract_data.py',
            'rec_all',
            ins=(H5,),
            outs=(EXTRACT,),
        ),
        Stage(
            'pred_unit_subset',
            '{script_dir}/pred_unit_subset.py',
            'rec_all',
            ins=(EXTRACT,),
            outs=(PRED_UNIT_SUBSET,),
        ),
        Stage(
            'pred_all_units',
            '{script_dir}/pred_all_units.py',
            'rec_all',
            ins=(EXTRACT,),
            outs=(PRED_ALL,),
        ),
        Stage(
            'pred_random_stim',
            '{script_dir}/pred_random_stim.py',
            'rec_all',
            ins=(EXTRACT,),
            outs=(PRED_RANDOM_STIM,),
        ),
        Stage(
            'pred_shuffle',
            '{script_dir}/pred_shuffle.py',
            'rec_all',
            ins=(EXTRACT,),
            outs=('{pred_shuffle_dir}/{rec}.joblib',),
        ),
        # Also reads the single-probe files for each probe in the pair
        Stage(
            'probe_coherence',
            '{fs_script_dir}/probe_coherence.py',
            'rec_ml_am',
            ins=(EXTRACT, PRED_ALL),
            outs=('{probe_coherence_dir}/{rec}.json',),
        ),
        Stage(
            'fso_decoding',
            '{fs_script_dir}/fso_decoding.py',
            'rec_fso',
            ins=(EXTRACT, PRED_ALL),
            outs=('{fso_decoding_dir}/{rec}.json',),
        ),
        Stage(
            'acorr',
            '{script_dir}/acorr.py',
            'rec_all',
            ins=(EXTRACT, PRED_ALL, '{pred_shuffle_dir}/{rec}.joblib'),
            outs=('{acorr_dir}/{rec}.joblib',),
        ),
        Stage(
            'states_loglik',
            '{script_dir}/states_loglik.py',
            'rec_plot_it',
            ins=(EXTRACT,),
            outs=('{states_loglik_dir}/{rec}.json',),
        ),
        Stage(
            'marg_loglik',
            '{script_dir}/marg_loglik.py',
            'rec_plot_it',
            ins=(EXTRACT,),
            outs=('{marg_loglik_dir}/{rec}.json',),
        ),
        Stage(
            'stats',
            '{script_dir}/stats.py',
            'rec_all',
            ins=(EXTRACT, PRED_ALL),
            outs=('{stats_dir}/{rec}.json',),
        ),
        Stage(
            'summary_stats',
            '{script_dir}/summary_stats.py',
            outs=('{summary_stats_dir}/summary_stats.json',),
        ),
        Stage(
            'compile_data',
            '{script_dir}/compile_data.py',
            'rec_all',
            ins=(H5, PRED_ALL, PRED_RANDOM_STIM, PRED_UNIT_SUBSET),
            outs=('{compile_data_dir}/{rec}.mat',),
        ),
    ],
    # Median dwell times and HMM vs. static model log-likelihood across a range of HMM bin sizes
    'dwell_time_loglik': [
        Stage(
            'extract_data',
            '{fs_script_dir}/extract_data.py',
            'rec_plot_it',
            ins=(H5,),
            outs=(EXTRACT,),
        ),
        Stage(
            'dt_loglik',
            '{script_dir}/dt_loglik.py',
            'rec_plot_it',
            ins=(EXTRACT,),
            outs=('{dt_loglik_dir}/{rec}.joblib',),
        ),
        Stage(
            'results',
            '{script_dir}/results.py',
            outs=('{results_dir}/dwell_time_loglik.mat',),
        ),
    ],
    # Summaries across recordings of outputs from the `llr` pipeline, which must be run first
    'python_summaries': [
        Stage(
            'acorr',
            '{script_dir}/acorr.py',
            outs=('{python_summaries_dir}/acorr.mat',),
        ),
        Stage(
            'marg_loglik',
            '{script_dir}/marg_loglik.py',
            outs=('{python_summaries_dir}/marg_loglik.mat',),
        ),
    ],
}


@dataclass
class Job:
    """A single script invocation within a stage."""

    stage: Stage
    label: str
    cmd: list[str]
    ins: list[Path]
    outs: list[Path]
    log: Path


def make_jobs(
    stage: Stage, paths: dict, recordings: dict, pipeline_dir: Path, params_file: Path
) -> list[Job]:
    """Expand a stage into one job per recording (or a single job for aggregate stages)."""

    if stage.recs is None:
        items = [None]
    else:
        items = recordings[stage.recs]

    params_args = ['--params', str(params_file.relative_to(REPO_DIR))]

    jobs = []
    for item in items:
        if item is None:
            fields = dict(paths)
            label = stage.name
            args = []
        else:
            rec = f'{item["session"]}_{item["paradigm"]}_{item["probes"]}'
            fields = {**paths, **item, 'rec': rec}
            label = f'{stage.name}:{rec}'
            args = ['--session', item['session'], '--paradigm', item['paradigm']]
            args += ['--probes', item['probes']]

        script = stage.script.format(**fields)
        jobs.append(
            Job(
                stage=stage,
                label=label,
                cmd=[sys.executable, script, *params_args, *args],
                ins=[REPO_DIR / t.format(**fields) for t in stage.ins],
                outs=[REPO_DIR / t.format(**fields) for t in stage.outs],
                log=pipeline_dir / 'logs' / stage.name / f'{fields.get("rec", stage.name)}.log',
            )
        )
    return jobs


def run_job(job: Job) -> bool:
    """Run a job from the repository root, writing its output to a log file."""

    for out in job.outs:
        out.parent.mkdir(parents=True, exist_ok=True)
    job.log.parent.mkdir(parents=True, exist_ok=True)

    with open(job.log, 'w') as f:
        result = subprocess.run(
            job.cmd, cwd=REPO_DIR, stdout=f, stderr=subprocess.STDOUT, check=False
        )

    if result.returncode != 0:
        tail = job.log.read_text().splitlines()[-20:]
        print(f'  FAILED {job.label} (log: {job.log.relative_to(REPO_DIR)})')
        print('\n'.join(f'    | {line}' for line in tail))
        return False

    print(f'  done   {job.label}')
    return True


def main():
    parser = argparse.ArgumentParser(description='Run an analysis pipeline')
    parser.add_argument('pipeline', choices=sorted(PIPELINES))
    parser.add_argument('--stages', nargs='+', help='Only run these stages (in pipeline order)')
    parser.add_argument('--sessions', nargs='+', help='Only run recordings from these sessions')
    parser.add_argument('-j', '--jobs', type=int, default=1, help='Number of parallel jobs')
    parser.add_argument('-f', '--force', action='store_true', help='Rerun even if outputs exist')
    parser.add_argument('-n', '--dry-run', action='store_true', help='Show plan without running')
    args = parser.parse_args()

    pipeline_dir = DATA_DIR / args.pipeline
    params_file = CONFIG_DIR / f'{args.pipeline}.yaml'
    with open(params_file, 'r') as f:
        paths = yaml.safe_load(f)['paths']
    with open(RECORDING_LISTS, 'r') as f:
        recordings = yaml.safe_load(f)

    if args.sessions:
        recordings = {
            key: [item for item in val if item['session'] in args.sessions]
            for key, val in recordings.items()
            if key.startswith('rec_')
        }

    stages = PIPELINES[args.pipeline]
    if args.stages:
        unknown = set(args.stages) - {s.name for s in stages}
        if unknown:
            parser.error(f'unknown stages for {args.pipeline}: {", ".join(sorted(unknown))}')
        stages = [s for s in stages if s.name in args.stages]

    # Plan which jobs need to run, and check that each one's inputs will exist by the time it
    # runs (either already on disk or produced by an earlier stage in this run)
    plan = []
    will_exist = set()
    missing = []
    for stage in stages:
        jobs = make_jobs(stage, paths, recordings, pipeline_dir, params_file)
        todo = [j for j in jobs if args.force or not all(p.exists() for p in j.outs)]
        for job in todo:
            missing += [(job.label, p) for p in job.ins if p not in will_exist and not p.exists()]
        will_exist.update(p for j in todo for p in j.outs)
        plan.append((stage, jobs, todo))

    for stage, jobs, todo in plan:
        print(f'{stage.name}: {len(todo)} to run, {len(jobs) - len(todo)} up to date')

    if missing:
        needed_by = {}
        for label, path in missing:
            needed_by.setdefault(path.resolve().relative_to(REPO_DIR), []).append(label)
        print(f'\nMissing inputs ({len(needed_by)}):')
        for path, labels in needed_by.items():
            print(f'  {path} (needed by {", ".join(labels)})')
        sys.exit(1)

    if args.dry_run:
        return

    # Run stages in order; jobs within a stage are independent and can run in parallel
    for stage, _, todo in plan:
        if not todo:
            continue
        print(f'\n[{stage.name}] {stage.script.format(**paths)} ({len(todo)} jobs)')
        with ThreadPoolExecutor(max_workers=args.jobs) as pool:
            ok = list(pool.map(run_job, todo))
        if not all(ok):
            print(f'\n{ok.count(False)} job(s) failed in stage {stage.name}; stopping.')
            sys.exit(1)

    print('\nPipeline complete.')


if __name__ == '__main__':
    main()
