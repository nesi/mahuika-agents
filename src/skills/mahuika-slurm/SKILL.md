---
name: mahuika-slurm
description: Write, size, submit and manage Slurm batch jobs on REANNZ's Mahuika HPC cluster. Covers the batch script template, sbatch, squeue, sacct, scancel and seff, choosing CPUs, memory and walltime, partitions (milan, genoa, hugemem), job limits, priority, Fairshare, the debug QoS and pending reasons, job arrays, dependencies, checkpointing, scrontab and temporary directories. Use when writing or submitting a job script on Mahuika, deciding how many resources to request, or working out why a job is pending, failed or slow to start.
license: GPL-3.0-only
---

# Slurm batch jobs on Mahuika
<!-- sources: Batch_Computing/Batch_Computing_Guide.md, Software/AI_Agents/AI_Agent_Guidelines.md -->

Follow the REANNZ agent rules (`AGENTS.md`). If they aren't loaded, read
<https://docs.nesi.org.nz/Software/AI_Agents/AI_Agent_Guidelines/> before submitting anything.
In short: scope every query to your own jobs, leave tens of seconds or more between polls, and submit
arrays or dependency chains, never loops of `sbatch`.

## Batch script template
<!-- sources: Batch_Computing/Batch_Computing_Guide.md, Batch_Computing/SLURM-Best_Practice.md -->

```bash
#!/bin/bash -e
#SBATCH --account       <projectcode>   # the project the work belongs to; optional if only one
#SBATCH --job-name      myjob
#SBATCH --time          01:00:00        # walltime, minutes or HH:MM:SS
#SBATCH --mem           2G              # memory per node
#SBATCH --cpus-per-task 1               # >1 only if the program is multithreaded
#SBATCH --output        log/%x.%j.out   # %x job name, %j job ID; create log/ first

module purge
module load <module>
<command>
```

- `-e` stops the job at the first failing command, so failures show as `FAILED` in `sacct`.
- Options can also go on the command line, overriding the script: `sbatch --time 00:30:00 job.sl`.
- `sbatch --wrap "COMMAND"` runs one command as a job without a script. With no file name, `sbatch` reads the
  script from standard input, so a submitting script can use a heredoc (`sbatch <<'EOF'`; with `'EOF'` quoted,
  variables expand when the job runs, unquoted when it is submitted).
- Ask the user which project to charge; `nesi99991` is only a docs example.

## Submit and monitor
<!-- sources: Batch_Computing/Batch_Computing_Guide.md, Software/AI_Agents/AI_Agent_Guidelines.md, Announcements/Slurm_Job_Email.md -->

| Task | Command |
| --- | --- |
| Submit | `sbatch job.sl` (prints the job ID) |
| Your queued and running jobs | `squeue --me` |
| One job | `squeue -j <jobid>`, `sacct -j <jobid>` |
| Your jobs since a date | `sacct -X -S YYYY-MM-DD` (`-X` hides job steps; `--state=FAILED` etc. filters) |
| Cancel one job | `scancel <jobid>` |
| Efficiency after it ends | `seff <jobid>` |

Rather than polling (also inside job scripts), block with `sbatch --wait job.sl`, chain work with `--dependency`,
or get email with `--mail-type=END,FAIL --mail-user=<address>`.
Never run plain `squeue` or `sacct -a`: they query the whole cluster.
`scancel --me` cancels every job the user has, including ones started by other tools or sessions, so confirm
with the user first.

## Sizing a job
<!-- sources: Batch_Computing/SLURM-Best_Practice.md, Getting_Started/FAQs/How_Do_I_Request_Memory.md, Batch_Computing/Hardware.md -->

- Request what the job needs plus a little headroom. Bigger requests queue longer and use the allocation faster.
  Size from earlier runs: `seff <jobid>` or `sacct -j <jobid> -o JobID,Elapsed,TotalCPU,MaxRSS,ReqMem`.
- **CPUs:** set `--cpus-per-task` only for multithreaded programs. Unsure? Benchmark 2 against 4 CPUs and check
  that elapsed time roughly halves. Only MPI programs set `--ntasks` above 1 or use `srun`.
- **Memory:** use `--mem` (per node). Use `--mem-per-cpu` only for MPI jobs whose tasks may be spread unevenly across nodes.
  Too little memory gets the job killed (OOM); too much makes it wait.
- **Time:** be as accurate as you can with some headroom. Shorter, accurate limits let backfill start jobs sooner.
  Aim for hours, not days; use checkpointing for longer work.
- Combine many jobs of under 5 minutes into one job with a loop, to amortise per-job overheads.

## Where jobs run
<!-- sources: Batch_Computing/Hardware.md -->

- Don't pick a partition by default: jobs land on `milan` or `genoa` nodes by their memory per CPU, and always get the memory asked for.
- `hugemem` (Intel, up to 6 TB per node) must be requested with `--partition hugemem`; software usually needs recompiling for it.
- Usable memory per node is a few percent below the installed figure: `sinfo -o '%n %m'` shows exact values.

## More detail
<!-- sources: Batch_Computing/Batch_Computing_Guide.md -->

- Limits, priority, Fairshare, the debug QoS, and why a job is pending: [references/limits-and-priority.md](references/limits-and-priority.md)
- Job arrays and dependency chains: [references/arrays-and-dependencies.md](references/arrays-and-dependencies.md)
- Checkpointing, self-resubmitting jobs, `scrontab`, holds, temporary directories:
  [references/long-jobs-and-scratch.md](references/long-jobs-and-scratch.md)
