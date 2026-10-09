# Limits, priority and pending jobs

## Hard limits

Per job: 10 nodes, 21 days walltime, 21 node-days (walltime x nodes).

Per user, across running jobs:

- 2688 CPU cores occupied, 3528 core-days booked
- 6 TB of memory occupied, 30 TB-days booked
- 6 GPUs and 14 GPU-days booked at once
- 1000 queued jobs, which also caps a job array at 1000 tasks

Jobs over a limit wait (or are rejected) rather than run. Respect the limits; if the work truly needs more,
the user should ask support.

## Priority

`sprio -u $USER` shows the priority factors of your pending jobs. Priority comes from:

- **Fair share** (up to 1000 points): falls when the project has used more core-hours than expected recently,
  across all partitions, and recovers over a few days. Scores belong to projects, not users.
  `sshare` shows it; `nn_corehour_usage <project>` shows monthly usage (CPU, memory and GPU time).
- **Job age:** 1 point per hour pending, for up to 3 weeks.
- **Job size:** larger and whole-node jobs get a small boost.
- **QOS:** `--qos=debug` adds 5000 points for short tests: one small job per user at a time, at most 120 minutes and 2 nodes.
  Using it for more than one short job counts as abuse: never chain, resubmit or split work to stay in it.
- **Nice:** `sbatch --nice` lowers a job's priority; `scontrol top <jobid>` moves one of your jobs ahead of your
  others in the same partition.

Backfill starts short jobs early when they won't delay higher-priority ones, so accurate time limits help.

If the project's fair share is low because it has more work than its allocation, the user can apply to support
for an allocation increase. Project usage in compute units is also on <https://my.nesi.org.nz>.

## Why is my job pending?

1. Check <https://status.nesi.org.nz/> for maintenance.
2. Run `nn_my_queued_jobs` and read the `REASON` column (only one reason is shown even when several apply):
   - `Priority`: other jobs are ahead. Wait, or shorten and shrink the request.
   - `Resources`: not enough free nodes yet.
   - `Dependency`: waiting for another job.
   - `ReqNodeNotAvail`: a requested node is busy, down or doesn't exist.
   - `QOS...Limit` or `...PerUser...`: a limit above applies.
3. A priority of 0 means the job is held: `scontrol release <jobid>` (jobs requeued after a node failure can be held too).
