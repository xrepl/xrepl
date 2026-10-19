# Actual independent design review —2026-10-19

Reviewer/root/native_design_review, read-only, no edits/builds/experiments.
Initial exact draft SHAaa2d70dea72905938e84f72849d89879b0f0b6b711df470ee5fd83574529d62a;
with CDC correction f1247bfbe0411f3d603c3726fdf5bac41b1b83087fc9e1fbfb811b675fbbf402.
Preserved draft here includes both states' text plus dated disposition.

P2: unconditional remainder reserve makes4095one-digititems truncate even though
whole text fits8191bytes. At penultimate item4remain, reserve4 leaves0 childbudget.
CDC explicitly retained conservative/no-maximal-utilization algorithm, changed
oracle4094complete/4095earlyomission/4096overbudget, exact8192scalar separate.
Finding resolved before issue, not erased or attributed to implementer.

Pinned LFE2.2 has no lfe_lib:format_float; actual float branch uses exported
io_lib_format:fwrite_g/1, installed stdlib7.3 implements float_to_list([short]).
PID '#Pid'+pid_to_list, native port_to_list/ref_to_list. Bigint threshold safely
bounds decimal allocation; significantbits4R+1. Default maps iterator bounded;
ordered iterator collects/sortskeys. Short256 probes bounded. Reviewer requested
explicit insufficient-reservation guard and emptylist-before-string precedence;
CDC added both to binding contract. No other concrete blocker found. This is
feasibility review, not product acceptance or a complexity/performance proof.
