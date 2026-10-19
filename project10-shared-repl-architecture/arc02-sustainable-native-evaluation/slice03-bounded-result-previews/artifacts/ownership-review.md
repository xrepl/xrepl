# Independent read-only ownership design review —2026-10-19

/root/native_design_review, no edits/builds/experiments. Source baseline7228183.
Original sketch SHA256a694db516da2bd1759c0c457a80e893c1671186e1b46fb9448e092f1d3ffdf59;
with finding/CDC disposition7a77db56b5e9e8a9b229c2e19e90a3bc07213348b36ca1bfda9cf2e988ceb93f.

P2 BLOCKING: original sketch31–32 assumes collector loss forces context cleanup
after activation. Context traps exits(context18) and can block in socket send
(51–63/318–320). Killing ONLY collector leaves a root trapping linked exits alive,
while context cannot consume collector EXIT/DOWN to terminate338–350. Collector
is not a supervisor child, so no automatic one_for_all follows. OTP changes killed
collector's propagated exit into trappable reason killed. This is a single failure
under ordinary blocked output, not simultaneous owner failures.

Root retained finding, rejected separate ownership acceptance before context
responsiveness, and combined ownership with stream/pressure writer/formatter
work in provisional X04. No final exact recipe or implementation acceptance yet.

CDC disposition: retain P2 and NR02 serious/open. Rootownership plus responsive
context/formatter/writer/chunkpressure becomes unissued X04 inside existingArc02;
X03 delivers native4 preview first. No ownership guarantee narrowed or dropped.
