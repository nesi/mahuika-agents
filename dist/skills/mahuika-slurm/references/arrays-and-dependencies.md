# Job arrays and dependency chains

Use an array for many independent tasks with the same resource needs (parameter sweeps, many input files),
instead of submitting jobs one by one. Use a dependency chain when jobs must run in order.

## Arrays

```bash
#!/bin/bash -e
#SBATCH --job-name   sweep
#SBATCH --time       00:10:00
#SBATCH --mem        1G
#SBATCH --array      0-99%10          # tasks 0..99, at most 10 running at once
#SBATCH --output     log/%x_%a.out    # %a is the array index; env vars don't work in #SBATCH lines

files=( inputs/*.dat )                # 100 files -> --array 0-99
input=${files[$SLURM_ARRAY_TASK_ID]}
mkdir -p run_${SLURM_ARRAY_TASK_ID} && cd run_${SLURM_ARRAY_TASK_ID}
my_program "../$input"
```

- `$SLURM_ARRAY_TASK_ID` selects the input: an index into a bash array, a file name, a function argument,
  or a random seed (always seed from it, or tasks may draw the same random numbers).
- Tasks may run at the same time, so give each its own output files and working or temporary directory.
- An array counts towards the 1000 queued-job limit, so it can have at most 1000 tasks; above that, ask support.
- Several dimensions: index with `SLURM_ARRAY_TASK_ID % n` and `SLURM_ARRAY_TASK_ID / n`.
- `scancel <jobid>` cancels the whole array; `scancel <jobid>_<index>` one task.

## Dependencies

```bash
first=$(sbatch --parsable prepare.sl)
sbatch --dependency=afterok:$first analyse.sl
```

- `afterok` runs the next job only if the earlier one succeeded.
- The next job joins the queue before the earlier one finishes, which saves queue time between them.
