# Limits, priority and pending jobs
<!-- sources: Batch_Computing/Job_Limits.md, Batch_Computing/Job_Prioritisation.md, Batch_Computing/Fairshare.md, Batch_Computing/Debug_QoS.md, Batch_Computing/Checking_Resource_Usage.md, Getting_Started/FAQs/Why_Is_My_Job_Taking_a_Long_Time_to_Start.md -->

## Hard limits
<!-- sources: Batch_Computing/Job_Limits.md, Batch_Computing/Job_Arrays.md -->

Per job: 10 nodes, 21 days walltime, 21 node-days (walltime x nodes).

Per user, across running jobs:

- 2688 CPU cores occupied, 3528 core-days booked
- 6 TB of memory occupied, 31.5 TB-days booked
- 6 GPUs and 14 GPU-days booked at once
- 1000 queued jobs, which also caps a job array at 1000 tasks

Jobs over a limit wait (or are rejected) rather than run. Respect the limits; if the work truly needs more,
the user should ask support.

## Priority
<!-- sources: Batch_Computing/Job_Prioritisation.md, Batch_Computing/Fairshare.md, Batch_Computing/Debug_QoS.md -->

`sprio -u $USER` shows the priority factors of your pending jobs. Priority comes from:

- **Fairshare** (up to 1000 points, the largest part): compares the project's recent use with its expected share,
  set by its allocation. Usage has a half-life of 14 days, so the score recovers by itself after a burst of work.
  Priority can't be saved up by not running jobs: submit work at a steady rate through the allocation period.
  Scores belong to projects, not users. `sshare -U` shows it (`FairShare` column);
  `nn_corehour_usage <project>` shows monthly usage (CPU, memory and GPU time).
- **Job age:** 1 point per hour pending, for up to 3 weeks.
- **Job size:** larger and whole-node jobs get a small boost.
- **QOS:** `--qos=debug` adds 5000 points, for one-off tests and debugging only (see the agent rules for what
  counts as misuse). One small job per user at a time, at most 120 minutes and 2 nodes, 168 CPU cores, 512 GB of
  memory and 2 GPUs. Never chain, resubmit or split work to stay in it. If debug submissions fail with
  `Invalid qos specification`, REANNZ has removed the user's debug access: tell the user, don't work around it.
- **Nice:** `sbatch --nice=<points>`, or `scontrol update JobId=<jobid> Nice=<points>` on a pending job, lowers its
  priority (it can't raise it). `scontrol top <jobid>` moves one of your pending jobs ahead of your others in the
  same partition, account and QOS.

Backfill starts short jobs early when they won't delay higher-priority ones, so accurate time limits help.

If the project's Fairshare is low because it has more work than its allocation, the user can apply to support
for an allocation increase. Project usage in compute units is also on <https://my.nesi.org.nz>.

## Why is my job pending?
<!-- sources: Getting_Started/FAQs/Why_Is_My_Job_Taking_a_Long_Time_to_Start.md -->

1. Check <https://status.nesi.org.nz/> for maintenance.
2. Run `nn_my_queued_jobs` and read the `REASON` column (only one reason is shown even when several apply):
   - `Priority`: other jobs are ahead. Wait, or shorten and shrink the request.
   - `Resources`: not enough free nodes yet.
   - `Dependency`: waiting for another job.
   - `ReqNodeNotAvail`: a requested node is busy, down or doesn't exist.
   - `QOS...Limit` or `...PerUser...`: a limit above applies.
3. A priority of 0 means the job is held: `scontrol release <jobid>` (jobs requeued after a node failure can be held too).
