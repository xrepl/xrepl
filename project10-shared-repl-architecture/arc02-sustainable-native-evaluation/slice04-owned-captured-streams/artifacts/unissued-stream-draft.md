# Unissued X04 responsive captured streams and ownership — CDC draft2026-10-19

Source-led design/review within approved nativeArc02. NOT implementation authority,
not an experiment or a frozen open set. Native38338d6 source basis; X03 preview
currently editing only its exact15paths, no IO changes. Actual accepted X03 pin
precedes final prompt. Existing NR02 and prior rejected ownership draft retained.
Root /root owns decisions, reviewer seeks concrete blocking contradictions.

## Promised increment and unchanged boundary

Complete supported inherited-group-leader output, UTF8 chunks<=8192, explicit
ordinary I/O errors/capacity without context loss merely for a large write.
Original io_reply ok only when ALL chunks durably acknowledged. Context and
collector stay responsive while socket/MFA/conversion blocks. Foreground root
and formatter workers cannot outlive a SINGLE owner failure, even if callback
sets trap_exit true. Preserve original strict per-origin producer born/exit/
delivered/sent==observed/pendingACK proof, origin64 bound, native4/publicRPC1,
context64/authority16 budgets/authority-loss fence. No arbitrary user-heap/process/
mailbox sandbox, remote IO, disabletracing/global-device capture or simultaneous
multi-owner-kill promise. Native app and source versions unchanged.

## Two responsive lifetime owners, no new per-origin guardian

Keep existing context and per-origin collector. Add one dedicated nontrapping
network writer per context, disposable formatter workers only for admitted IO.
Context performs NO gen_tcp:send, apply/user evaluation or full conversion in
callbacks; collector performs NO network/apply/full conversion/blocking owner
call. Thus either surviving owner can untrappably kill root/formatter after the
other fails. Prior P2 collector-only kill while context blocked is removed by
this combined responsiveness change, not excluded from the promise.

Move root creation INTO collector init after trap_exit set once and ownership
established. Third start arg becomes paused EvalFun (closure from context), not
an already-created root. Collector spawns linked root which waits evaluate;
installs trace/session/producers/group leader before activation. Acquisition
try cleans every acquired root/trace on failure. No source code before explicit
activation. Paused root has no usercode/trap_exit yet, so collector death before
context learns identity ends root via link. Context death reaches collector's
actual gen_server parent-exit lifecycle and terminate kills root/workers then
trace, regardless of context terminate being skipped.

Recommended asynchronous metadata handshake avoids context->collector call:
start_link/init completes with root paused and sends exact origin_ready(io,root,
trace) to context. Context already stores provisional io/monitor in returned
state; it validates ready ownership, monitors root, stores identities/active,
then posts activate_origin selfmessage. Handle that selfmessage only on the
registered state, send collector activation grant; collector checks owner/ref
and releases root. Collector still has root record. No callback between source
activation and state publication holds unregistered resources. Context on
unexpected collector DOWN explicitly kills known root AND all registered worker
PIDs before trace destruction/context termination. Collector terminate explicitly
kills root AND workers before trace destroy. Context terminate does NOT brutally
kill collector first; it kills known root/workers, signals collector shutdown,
destroys known trace and kills its writer. Responsive collector parent exit runs
own deterministic cleanup. Exact monitor/ref checks, not anonymous pidscan.
No graceful parent/child callcycle during shutdown.

Root normal link EXIT is not quiescence proof; existing trace exit+delivered
root-accounted remains. Root monitor/foreground result preserve cancellation/
completion-wins semantics. Quiet results still await physical collector DOWN;
background descendants retain immutable origin. No root/worker active before
both lifetime owners possess its identity; unregistered workers remain paused,
nontrapping and linked to collector.

## Dedicated writer and bounded frames

Writer is a separate focused module/worker, linked and monitored by context,
NEVER runs evaluated code and NEVER traps exits. Blocking send is its one role;
it cannot strand a root. Context remains socket controlling_process (registry
still holds exactport); writer borrows it. Parent abnormal death/kill stops
nontrapping writer; orderly context terminate explicitly exit(writer,kill).
Writer failure/forged completion is context loss. Only context issues writes.
FIFO jobs carry exact writerPID/ref plus already-bounded event. Completion
writer_sent(writer,ref) sent after actual gen_tcp:send returnsok; error loses
context, no success completion. Network ACK alone never manufactures sentproof.
Encoding is bounded privateframe, no nativewire change.

Context maximum64 output chunks pending, at mostone per admitted formattingjob.
Reserve2 outstanding Outcome jobs (serial real host can receive a result before
local writer_sent is handled, then send next Dispatch, so one reserve is unsafe).
One Ready job and one terminal Closed/Lost job =>max68queued/inflightframes.
Context refuses invalid adversarial excess rather than unbounded queue; realhost
has one foreground dispatch percontext and waits its nativeoutcome, so cannot
need3unconfirmedOutcomes (writer emits priorcompletion before sending another).
Track exact outstanding jobs/refs, no historical map. Root active can clear on
Outcome enqueue asbeforepublish; FIFO retains control/eventorder. Capacity does
not silently shed output. All direct Ready/Output/Outcome/Closed/Lost sends route
through writer, not a missed old path.

When capture chunk assigned position, store pending BEFORE enqueue. Record
writer_sent and ACK as independent bits because ACK may arrive before context
processes completion; release/notify collector only after BOTH aretrue. Unknown/
repeatedACK or mismatchedworker/io/job/chunk/ref is invariantfault, nofalseACK.
Positions remain canonical global incrementingstrings, oldorigin operationtoken.
Writer_completed alone does NOT mean durableACK and cannot grant io_reply.
Ordinary noACK backpressure blocks formatter, not owner/cancellation callbacks.

Normal Close emits Closed only after foreground disposition, ALL preseal admitted
IO/chunks finish/error (no falsely successful abort), normal retiringcollector
DOWNs and forcedlivecollector seal/physicalDOWNs. Then enqueueClosed and wait
writer_sent terminal before orderlystop; no killwriter immediately afterenqueue.
TerminalLost/cancel may discard live state asalready advertised, but still no
false io_reply/Closed. Existing5sclose timeout retains honest Lost/EOF if capture/
formatter/socket cannot complete; it is NOT a success/barrier/drain witness.
Cancellation rootkill staysdestructive; best-effort Cancelled/Lost inFIFO then
bounded terminalflush, finalcleanup kills formatterworkers. Administrative fault
can end context/socket immediately; committedprefix/uncertainty belongs toRust.

## Global admitted job credit and formatter registration

Collector validates supported request constructor, increments observed for each
unsealed io_request exactlyasbefore, keyed by(From,Ref). Local pendingproposals
cap64, excess ordinaryio_reply{error,enobufs}; no context loss or fakeok. Store
opaque payload locally, send owner ONLY admissionproposal(io,jobref), not input.
Context globally caps admitted formattingjobs at64 acrossall64origins. Validate
origin/live/token/ref then grant or ordinaryenobufs/terminated. No wholehistory.
Jobcredit covers startup, formatting, outstandingchunk and physicalworkerDOWN.
No worker before admission. Distinct sourceIO saturation explicit; arbitrary
user fire-and-forget fanout remains outside mailbox sandbox ascurrentcontract.

On grant collector spawns linked paused formatter, records pid/monitor, manually
seeds traceproducerborn and installs procs/send/set_on_spawn (collector itself
nottraced, so explicit seed needed). Set group_leader tothiscollector. Send
formatter_ready(io,job,worker) to context. Context validates grant, monitors and
storesWorkerPID, then grants activation via collector. Only THEN worker invokes
MFA or conversion. CollectorKill before registration stops paused nontrapping
worker; after activation context independently knows workerPID and kills it even
if userMFA setstrap_exittrue. ContextKill always has collector asresponsiveowner.
Keep exactworkerDOWN+collectorjobdone before global creditreturns, no logical
release while physicalworker remains. Clearcollectorpayload afterworkerownsit.

Concurrentformatters (up to64contextjobs), NOT one-per-origin serialized worker:
MFA callback can do supported nested IO tosamecollector and wait. Its nestedjob
must run whileparentworkerwaits; exact same globalcreditcap, explicitenobufs at
nesting saturation avoidsdeadlock. Workers and their descendants are explicit
trace producers under immutableorigin, so nested/asynchronous IO counts in
sent/observed proof, never unaccounted helperIO or serverglobalGL escape.
Perjobchunks staysequential; differentproducerrequests may interleave ascurrent
arrival/hosttotalorder permits. No promise of cross-writer request-atomic output.

Worker pushes one chunk then waits exactcommitcontinue before emitting next.
Collector validates worker/job/chunkindex, forwards capture/io/job/chunk tocontext;
context positions/enqueuesboundedframe. Only dualsent+ACK confirmation returns
capture_committed tocollector, which releasesworker's chunk. Lastchunk must be
committed before worker reports done. Worker exits normally; collector waits
exactDOWN PLUSdone result before originalio_reply ok/error and jobdone tocontext.
NormalDOWNwithoutdone or unexpectedworkerdeath failscontext, notsuccess. Ordinary
MFA exception/invaliddata => explicitbadarg done, preserving anycommittedprefix.
No io_reply ok for partiallycaptured/failedrequest. EmptyvalidIO sends exactlyone
emptyOutput chunk and waitsACK, preserving old durable request observation.

## Incremental chardata conversion, including external encodings

Keep existing put_chars forms (chars;encoding/chars;MFA;encoding/MFA), unicode
asdefault. MFA apply ONLYinownedworker, catch expected callback class/reason as
ordinarybadarg asoldadapter; no unbounded recursiveprinter incollector.
Support actual unicode:encoding() inputs:latin1,unicode/utf8,utf16/{utf16,big|little},
utf32/{utf32,big|little}; invalidencoding ordinarybadarg. Never normalize text.

Worker walks possiblydeep mixed chardata with explicit stack/tailrecursion.
Separate root/list-tail/element frames: root andtail permitbinary,nil,cons;
onlyELEMENT permitsintegercodepoint. Thus improperinteger tail/rootinteger are
badarg, not silentlyflattened into validcharacters. Binarytail valid, bitstring
nonbyteinvalid. Eachprefix gathers<=1024sourceunits (onebyte perbinarybyte,
oneunit perintegercodepoint), stopping without fullinputscan. Push conshead as
element andconsTail astail, preserveorder/nesting. Collect only boundedprefix;
never length/flatten/fullconversion. Emptylists maytakework butonlyinsideworker,
no inputdepth/heapsandboxclaim. Scalarcodepointvalidation doesnot decimalprint.

For each prefix call unicode:characters_to_binary([Carry,Prefix],Encoding,utf8).
Existing OTP doc/source confirms incomplete UTFchar can span consecutivebinaries;
{incomplete,Good,Rest} Restbinary is pendingpart ofonechar, <=3bytes foraccepted
encodings. Keep boundedcarry, continueprefix. Integersremaincodepoints forany
encoding (latin1 rejects>255), so usingOTPconverter preserves mixedsemantics.
Fullbinary Good or incompleteGood hasvalidUTF8; convert boundedprefix only,
max4*1024+4bytes<8192. Copybounded Good ifnonempty into onechunk, waitdurableACK
before nextprefix. {error,Good,Rest} orbadarg: retain/optionallyemitvalidGoodprefix
under explicitpolicy, thenreportbadarg; no successfulwholewrite. EOFwithcarry
=>badarg. NoUTFbytecut, nofullbinaryUnicodeconvert inownercallback, no guessed
success onconversionerror. Anyvalidprefixalreadycommitted remains transcript;
streaming invalidtail cannot rollback earlieroutput. Choose final policy before
issue: proposed emit Goodprefix thenerror; finalcontract mustnotleave optional.

Owned boundedchunkcopy avoids retaininghuge parentbinary incontextpendingframes;
worker mayretainoriginal input whiletraversing asuserheap scopeallows. Prefix
subbinary refs neverescape aslong-lived unboundedtrace/record state. Finaldata
is UTF8text, no previewmetadata/truncation onOutput, no originalsize estimate.

## Controls and proof obligations before issue

Need actual acceptedX03pin and fullfile/caller/API map. Existing native44+X03new
cases remain meaningful, adapting privateinterfaces/stronger seal wait explicitly.
No synthetic count substitute. Newroot IOtests should gate actual64jobs/backpressure,
ordinaryoverload recovery, largeUnicodebinary/list/mixedlatin1/UTF16/32 splits,
MFAerror/blocked/nested/trappingformatter, invalidtail/emptyrequest/ACKfailure,
orderedchunks/fullbyteequality/replay. PositivelywithholdACK and show nooriginal
reply until finalACK; writer_sent alone notenough; finalpartialerror nofalseok.
Roottrap_exit true andformattertrap_exit true before collector-onlykill.
Actualpositive send_pend onnativeport then listenerkill/registrykill/appstop:
exactcontext/root/collector/formatter/writerDOWN andexplicittracedisposition,
no readclient/drain/releaseroot tohelp, nofalseClosed. Contextkill independent
ofterminate tests responsivecollector cleanup; collectorKill responsivecontext
kills registeredroot/workers. Livepeer isolation scopedasnativefaultdomainallows.

Pausedstartup tests use ownedpeer sys:install DEBUG FUN togate exactinmessage
origin_ready beforecontextregistration andactivate_origin afterregistration,
with rootalivebut source marker absent. Killcontext/collector there andassert
rootdies/noeffect. Normaltrace/acquisition failure cleanup receivescomplete source
review; resourcefailure injection mustnotclaim inaccessible artificialAPIcoverage.
Do not add productdebugexports/testonlybudget or infinitewait; tests owns cleanup,
positiveprecondition required (timerwait alone no proof). Preserve all failed
attempts, root/component/fresh/currentbeam and matching14native+3consumer gate.
C06 still fullmixed sustained/churn/size/twoobserver/restart/control/storageproof;
all original arcrows/NR02remainopen until actual independentcomposition.

## Independent review feedback and CDC revision —2026-10-19

Reviewer/root/native_design_review correctly rejects original two-Outcome proof:
writercompletions andTCP deliveries differentsenders, sendsalone do not prove
localcontext processingorder. Supersede that boundargument with explicitstate:
- publish retains active=publishing(operation,writerRef) until exactwriter_sent.
- Whilepublishing accept ONE correctlyscoped/tokenvalid Dispatch intobounded
  deferredslot, consumeits token ONCE, butcreate/evaluate NOTHING yet. Continue
  TCP/ACK/control handling. SeconddeferredDispatch is invalidpipeline; serialreal
  Rusthost waitsits nextOutcome so cannotneedtwo deferredcalls.
- Writer_sent clears publishing; ifnotclosing start prepared deferredattempt
  WITHOUT rechecking tokenagainstalreadyadvancedhighwater. Check liveorigin64
  capacityatthatmoment, ordinaryFailed iffull. Envstableuntilthen. Newoutcome
  again publishing, no unboundedoutcomepipeline.
- Close/matchingcancel whiledeferred clears it, produces explicitCancelled(false)
  for deferredoperation withoutsourceexecution; oldcompletedopcancel remainsno-op.
  Laterpriorcompletion mustnotactivatecanceleddeferredsource. NormalClose drains
  thenarchives; Cancelretiresthecontext asalreadydestructivecapability. Exact
  canceled-before-evaluation diagnostic differsfrom killed-root diagnostic.
- Boundatmost2Outcome jobs is NOW existingpublishing+one canceleddeferred during
  closing, not inferred cross-sender scheduling. Ready1+terminal1+Output64=>68.
  All otherdispatch/pending/closing protocol cases specified beforeissue; no
  receivepause that couldhideClose whilewriterblocked. Addwritercompletion/
  Dispatch/Cancel/Close permutation tests and negativequeued-sourcefileeffect.

Post-seal policy keeps oldboundary: ALL newlyreceived io_requests, INCLUDING
nestedrequests frompresealMFA, getordinaryerror terminated; neveradmit them.
Alreadyadmittedpreseal jobs may still emitremainingchunks andcomplete/error;
sealconfirmation waits thosejobs plusphysicalworkerDOWNs, pendingACKs androot
exit/delivery accounting. A callback canpropagatenestederror (normalbadarg), or
explicitlyignoreit andreturnits ownvalidtext; parentrequest's success thenonly
claims its returnedtextfullycommitted, never nestedrequestsuccess. No deadlock
bywaitingfornestedjobadmissionwhichsealforbids. Infinitecallback hits existing
closeTimeoutLost, neverClosed. Rework oldsealtest intentionally: previously it
announcedsealbeforepriorACK whilecontextguardwaited; now strongercollectorbarrier
waits actualpresealACK/rootexit beforesealed, retaining original nofalseACKand
latewrite-rejection intent. Do notsilently weaken eitheroldcriterion.

Conversion final proposedpolicy: emit every validGoodprefix fromerror/incomplete
results throughdurablechunkACK, THEN reportbadarg at invalidtail/EOFcarry.
No optional choice remains for finalcontract. Whole originalIOrequest nevergets
ok afteranyconversionerror; committedvalidprefixretained. Root/tail/element
walkercontext distinction preservesinvalidimproperinteger tail, binarytailvalid.

## Additional root clarifications before review completion

Formatter boundary catches arbitrary MFA user exceptions only aroundapply, as
existing ordinarybadarg behavior. Unicodeconverter catches its expectedbadarg;
internalstream state/ownership bugs must stillcrash/loss, notbe blankettranslated
into a fake ordinaryresult. Unsupported IO forms remainenotsup withoutjob; no
new batch/input/getopts surface. Preserve allactual unicode encodings, keepbinary
fragments asbinaries (notbytes-as-codepoints) inboundedprefix. Emptyvalidwrite
hasoneemptydurableOutput+ACK; invaliddata beforeanyvalidbytes hasnoemptyokevent.

Collectorjobdone andcontextworkerDOWN have different senders: holdcredituntil
BOTH, handleeithereventfirst, never allowretire_ready/sealed toimplicitlyfreeit.
NormalClose finalpredicate includescontextjobs0 andallpendingchunks0; collectorseal
waits ownworkerDOWNs/jobs0 ANDrootexit+delivery accounting. Onseal confirmation
context unlinks/grants forcedcollectorstop (distinctfromnaturaldrain retirement),
retains originentry/credituntilexactnormalDOWN; destroytracebeforestop. NoClosed
whileanyownedcollector/formatter/root remainsphysicallylive. Descendantusercode
outsideownedroot/workers mayremainwithdeadGL afterforcedclose ascurrentboundary.

CloseTimeout at5seconds is a FORCESTOP boundary, notanotherindefiniteterminalflush:
optionalLostenqueuebest-effort, thencontextstops/killswriter. EOF givesRustStateLost
ifLostcouldnotwrite. NormalCancelled/Lost awaitswritercompletiononlywithinexisting
bound. A confirmedrootkill mayhaveundeliveredCancelled underbroken/backpressured
wire; clientfinalUnknown/StateLostis honest, requestreceipt neverclaimedconfirmed
cancel. OrdinaryhealthyPTYcancel stilldeliversCancelled followedLost.

All contextsend-event calls migrate; authorityReady's singleboundedactivation
send remains authorityrole, no evaluatedroot or unboundedstream there. Root/source
metadata messages andnewinternalworkercontrolarenot newwireoperations.

Actualpressuretests should set smallnative sndbuf/peerrecbuf andstartadmitted
concurrentwriters (up toglobal64) soone-chunk-perjob stillfillswriter. Require
positiveinet:getstat(Socket,[send_pend]) BEFOREfault; holdclientbytes/ACKs through
fault/physicalDOWN observations. TrappingMFAworker can occupyonejobwhile63other
writersfillnetwork; root andMFA setstrap_exittrue, registered identities observed.
Collector-onlykill thenmustkillbothdespitewriterblocked. NormalClose cases can
resumeACKsafterpositivepressure andverifyfullpresealIO; withholdingforeverexpects
boundedLost/EOF, NEVERClosed. No sleep-alonepressurepredicate.

Startup debugFun runs inownedpeercontext; use sys:install arity3(State,Event,Extra)
with knownin-event origin_ready/activate_origin; stage message toOWNEDPEER test
controller (notassumeddistributed parentPID), inspect/controllerquery via peer:call.
Boundstagewait/testcleanup; gate isbeforehandler afteroldstatepublished, no product
hook/export. Before-registration gate seespausedroot+trace identities, after-
registration gate holdsbeforeexplicitactivate. Root source filemarker absent,
collector/root/worker monitorDOWN exact. Acquire-failure guard complete source
walk; inaccessible OSallocationfaults explicitlyunrun, no fakecoverageclaim.

## Second independent review corrections —2026-10-19

Reviewer/root/native_design_review found preexisting unlink→retire-grant gap:
context can die afterunlinkbeforestopcast, leavingcollector/trace (roots/workers
alreadydeadthere). Rootaccepts. Add exactowner processmonitor INcollectorinit,
retainedthroughnatural/forcedunlink untilphysicalcollectorstop. ActualownerDOWN
terminates collector andkillsownedroot/workers FIRST, thendestroys trace, even
whenparentlinkremoved. Normalterminate demonitorflush. RecordownerPid/refexact;
wrong/forgedDOWN cannottriggercleanup orcreditreturn. Addownedwrapper fixture
thatunlinkscollector thenparentkill WITHOUTstopgrant, pausedrootknown/tracehandle
externallyretained: collector/rootDOWN andtraceexplicitlydestroyed. Thisrequires
actualmonitor, old link-onlyleak cannotpass. Existinglink-onlyoriginalreview
claimsremainhistorical andnotbindingfinalmechanism.

Reviewer also found sealed-request accounting: oldsealedbranchreplyterminated
skipsobserved whiletracedrequestincrements sent. New strongerseal canthenfalse
Lost onnormalMFA nestedIO afterseal. Rootbinds observed++ forEVERY io_request,
includingsealedrejections; no requestevades accounting. Forcedseal waits root
exit+deliveryaccounted, jobs/formatter/pendingchunks0, sent==observed, thenreports
sealed. It doesNOTwaitalluserdescendantsdead; postsealadmissionclosed andlaterIO
explicitlyterminated. NeveruseemptyMailbox/timer/quiescenceguess. Infiniteuser
messagefanout mayhonestlytimeoutLost, noabsoluteheap/mailboxsandboxpromise.
Test nestedpostseal rejection withsent/request arrivalinversions andordinary
error/ignorednestederrorreturn, nofalseio_replyok or5sfalseLoss fromcounterbug.

Publishing/deferredcancel cornercases for finalrecipe: whileexecuting/startup,
futurecancelofotherop remainsno-op perexistingcontract. Whilefinishing/publishing
withNOdeferred, matching/stale/futureother cancels arecompletion-wins/no-op; no
stronger queued-cancellationpromise. Withonevalidateddeferredop, exactmatching
cancel orClose removesit, emitsCancelledfalse beforeterminal, neversourceeffect.
Tokenconsumedonce; statepublication/closing guard preventspriorwritercompletion
fromreactivatingit. Extra deferredDispatch isprotocolfault; oldsource/tokensnever
reexecute. HoldingTCPreadarmedisrequired, cannotpauseawayClose behindwriter.

Terminalwriter job can be stop-after-send: sends exactcompletion then exitsnormal;
context retains terminalflushstate until BOTH exactwriter_sent andnormalmonitor
DOWN before orderlycontextstop. Handleeitherorder explicitly. Thus normalclose
physicalwritercredit cannotlagbehind releasedcontextcredit. Timeoutforcekill
remainsbest-effortLost/EOF withnoClosedclaim. OutputSent/ACK dualbitsunchanged.

## Root identities retained beyond foreground publication

Context originrecords MUST retain exactrootPID/rootmonitor until originphysical
DOWN, not onlycurrentactive tuple: evaluated/finishing/publishing can clear active
while rootprocess hasnotyetexited. Unexpectedcollectorloss/terminate kills ALL
knownoriginroots plusallregisteredformatters first, neveronlyactive. Retainroot
monitor andresult-seen/down flags or anequivalent exactmapping; normalrootDOWN
AFTERevaluated isallowed, abnormal/normalwithoutresultremainsruntimeLoss unless
expecteddestructivecancel. Thismonitor isNOTthe trace-drainproof; root-accounted
stillrequirescollector exit+deliveredwitness. Handlematchingroot/worker/writer/
collectorDOWNs byexactref+PIDbeforeunknownfault, no forgedcreditrelease. Retiring
origins keepidentityuntiltheir exactnormalDOWN. Old demonitor-on-evaluated pattern
mustnotleave a root unowned/unidentified acrossnewasyncpublication.
