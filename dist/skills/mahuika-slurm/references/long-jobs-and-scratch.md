# Long jobs, recurring jobs and temporary files

## Checkpointing

Checkpoint any job longer than a day: save state regularly so it can restart after a timeout or failure.
Check the application's own docs first (ANSYS, MATLAB, GROMACS and ORCA have built-in options). Checkpointing
adds runtime, especially for jobs with large memory, so weigh it against job length.

Checkpointing also lets you split work into shorter jobs, which queue faster and can exceed the walltime
limit in total. A job can queue its own successor before it starts working:

```bash
#!/bin/bash -e
#SBATCH --time 06:00:00
if [ -f done.flag ]; then exit 0; fi                    # stop the chain when the work is finished
sbatch --dependency=afterok:${SLURM_JOB_ID} "$0"        # next chunk waits for this one to succeed
my_program --resume-from checkpoint.dat                 # load state, work, save state
```

Without a stop condition this resubmits forever. Make the program exit non-zero, or check a flag as above,
once the work is done.
Chaining checkpointed jobs like this is good practice in the normal QOS, and abuse in the debug QOS.

## Holds

`scontrol hold <jobid>` stops a pending job from starting; `scontrol release <jobid>` lets it start again.

## Recurring jobs with scrontab

`scrontab -l` lists the user's entries; `scrontab -e` edits them (cron syntax, in the Slurm controller's
time zone). `#SCRON` lines before an entry set `sbatch` options for it (most, not all, are supported):

```text
#SCRON --time 00:05:00
#SCRON --job-name nightly-sync
0 3 * * * $HOME/bin/sync.sh
```

- The schedule sets when a run becomes eligible; it then waits in the queue like any other job.
- The next run isn't submitted until the previous one finishes; runs that fall due meanwhile are skipped.
- Your session's environment isn't passed on: load modules and set variables in the command or script it runs.
- Entries keep running until removed, and appear in `squeue --me`. `scancel` on one cancels all its future runs.

Only add one when the user wants genuinely periodic work, never to keep jobs permanently queued.
Never use it (or `cron`) to run an agent: a scheduled agent is unsupervised and needs a service account (AUP).

## Temporary files

| Where | How | Notes |
| --- | --- | --- |
| Job `/tmp` (default `$TMPDIR`) | automatic | In RAM: include its size in `--mem`. Deleted when the job ends. |
| Node SSD | `#SBATCH --gres=ssd` | 1.5 TB NVMe, sets `$TMPDIR` and `$JOB_SCRATCH_DIR`; not counted in `--mem`; one such job per node. |
| `/nesi/nobackup/<project>` | `export TMPDIR=/nesi/nobackup/$SLURM_ACCOUNT/tmp/$SLURM_JOB_ID` | Slowest, survives the job: delete it afterwards. |

- `/tmp` and the SSD are per node, not shared across the nodes of a multi-node job.
- Some programs ignore `$TMPDIR` and need their own option or variable.
- For data read repeatedly (e.g. a reference database), copy it to the SSD at the start of the job.
- On the login node `$TMPDIR` isn't set: use `TMPDIR=${TMPDIR:-/tmp}` in scripts that need it.
