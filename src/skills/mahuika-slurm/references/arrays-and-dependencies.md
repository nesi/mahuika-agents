# Job arrays and dependency chains
<!-- sources: Batch_Computing/Job_Arrays.md, Batch_Computing/Job_Dependencies.md, Batch_Computing/SLURM-Best_Practice.md, Software/AI_Agents/AI_Agent_Guidelines.md -->

Use an array for many independent tasks with the same resource needs (parameter sweeps, many input files),
instead of submitting jobs one by one. Use a dependency chain when jobs must run in order.

## Arrays
<!-- sources: Batch_Computing/Job_Arrays.md -->

```bash
#!/bin/bash -e
#SBATCH --job-name   sweep
#SBATCH --time       00:10:00
#SBATCH --mem        1G
#SBATCH --array      0-99%10          # tasks 0..99, at most 10 running at once
#SBATCH --output     log/%x_%A_%a.out # %A array job ID, %a index; env vars don't work in #SBATCH lines

files=( inputs/*.dat )                # 100 files -> --array 0-99
input=${files[$SLURM_ARRAY_TASK_ID]}
mkdir -p run_${SLURM_ARRAY_TASK_ID} && cd run_${SLURM_ARRAY_TASK_ID}
my_program "../$input"
```

- `$SLURM_ARRAY_TASK_ID` selects the input: an index into a bash array, a file name, a function argument,
  or a random seed (always seed from it, or tasks may draw the same random numbers).
- Tasks may run at the same time, so give each its own output files and working or temporary directory.
- Create output directories named in `#SBATCH` lines before submitting: Slurm doesn't create them.
- An array counts towards the 1000 queued-job limit, so it can have at most 1000 tasks; above that, ask support.
- Several dimensions: index with `SLURM_ARRAY_TASK_ID % n` and `SLURM_ARRAY_TASK_ID / n`.
- `scancel <jobid>` cancels the whole array; `scancel <jobid>_<index>` one task.

## Dependencies
<!-- sources: Batch_Computing/Job_Dependencies.md, Software/AI_Agents/AI_Agent_Guidelines.md, Batch_Computing/Job_Checkpointing.md -->

```bash
first=$(sbatch --parsable prepare.sl)                   # --parsable prints only the job ID
sbatch --dependency=afterok:$first analyse.sl
```

| Condition | Starts when the listed jobs have |
| --- | --- |
| `afterok:ID` | finished successfully |
| `afternotok:ID` | failed (non-zero exit, timeout, node failure...) |
| `afterany:ID` | finished, in any state |
| `aftercorr:ID` | (arrays) each task starts when the same index in the listed array succeeds |
| `singleton` | finished, for all your earlier jobs with the same `--job-name` |

- Several jobs: `afterok:ID1:ID2`. All of several conditions: separate with `,`; any one: separate with `?`.
  Use only one kind of separator in a dependency.
- The next job joins the queue straight away, which saves queue time between stages. A script on the login node can
  queue a whole workflow at once and exit; inside a job, queue the successor near the start of the script.
- If a dependency can never be met (e.g. `afterok` on a job that failed), the job stays pending with reason
  `DependencyNeverSatisfied` until cancelled, even if the failed job is rerun. `--kill-on-invalid-dep=yes` cancels it.
- Submit while the earlier job is queued or running, or soon after: Slurm forgets finished jobs after a short time.
- `afterok` on an array waits for every task. For an array, `afternotok` is met once all tasks have finished and at
  least one failed: a small follow-up job can find the failed indices with
  `sacct --jobs <id> --array --allocations --noheader --parsable2 --format JobID,State` and resubmit only those
  with `sbatch --array <list> --mem <more> process.sl` (command-line options override the script's header).
