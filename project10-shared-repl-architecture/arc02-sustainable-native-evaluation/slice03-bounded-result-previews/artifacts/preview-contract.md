# Native4 bounded result renderer — binding v1.0,2026-10-19

CDC Sofie /root owns this source-led design under the authorized Arc02.
Actual native source38338d6; Cayrn C05 independently accepted34af63e,
planning149ae8c. Supersedes the preserved unissued draft; reviewed algorithm
correction is explicit below. Binding behaviors and budgets; private helper names
and decomposition remain local discretion. No experiment or benchmark assigned.
Native3 authority/ownership/capture stays unchanged. X03 delivers native4 bounded
previews and consumer compile compatibility; X04 combines responsive context/IO
workers, root ownership, chunking and NR02. No ownership acceptance in X03.

## Public policy and native seam

New module cayrn-lfe-preview exports render1 returning #(UTF8binary truncatedBool).
Fixed8192 byte budget; structural nesting depth32. Internal functions private;
no custom-budget API just for tests. Render native values, parse errors and
exceptions with this same policy. Evaluator run2 changes internal tuple from
#(status text environment) to #(status text truncated environment), updated in
context and four eval tests; finishing tuple and direct resource fixture update.
Every native4 Outcome supplies preview:{truncated:bool}, including resource/cancel
fixed messages(false). Wire/public string text remains unchanged. Existing full
saved environment/value remains; no oversized-result session loss merely due to
printing. UTF8 valid and byte_size<=8192 for every renderer return. No lossless
value codec, original size, fetch-more, general heap sandbox or maximal-budget
utilization promise. Literal text '...' does not mean true; only actual policy
omission sets true. Small scalar and known list result formatting preserved;
quote/struct pretty sugar may use structural syntax. No blanket byte identity.

## Internal result and byte accounting

attempt(Value,RemainingBytes,Depth) returns #(fit BinaryOrBoundedIodata Used Omitted)
or no_fit if neither complete representation nor permitted omission fits.
Remaining0=>no_fit. Every text fragment converted to UTF8 binary before counting;
final iodata contains UTF8 binaries/ASCII bytes only. No slicing encoded scalar
text or cutting codepoints. Root8192 always fits at least marker '...' (3 bytes).
Scalar helper exact text if fits, else #(fit <<"...">> 3 true) if Remaining>=3,
else no_fit. Child no_fit permits parent to omit a whole remaining sequence.
No failure silently produces empty text. Total assembled fragments bounded by
bytes; one bounded iolist_to_binary at final output.

Empty list/tuple/map are complete ()/#()/#M() if fit. A nonempty compound with
Depth0 emits marker true if3 fit, otherwise no_fit; every recursive value child
of a compound uses Depth-1. Sequence siblings do not decrease nesting depth.
Small bounded string/binary atomlike cases may be recognized before structural
Depth0 rule. No recursive quote sugar bypasses the depth bound.

Compound prefixes/closer: list '(' and ')'; tuple '#(' and ')'; map '#M(' and ')';
raw bitstring '#B(' and ')'. Reserve closer at entry. Nonempty compound needs
prefix+3marker+closer capacity to start; otherwise no_fit. This can omit a tiny
compound whose exact representation would fit less space; permitted conservative
policy, true honestly reports actual omission.

Sequence iterator holds original cons tail, tuple+index, default map iterator or
bitstring cursor. NEVER maps:to_list, tuple_to_list, list length/full scan,
ordered map iterator, full binary Unicode conversion or arbitrary term printer.
Before rendering an item, inspect only enough iterator state to know whether a
remainder exists. Reserve separator-to-remainder plus3marker bytes when there is
one. Render item under residual budget. no_fit => append '...' to represent this
item and all remainder, stop. fit => append item, propagate its Omitted, continue
under exact residual budget. With a remainder, its reserved marker always fits.
Do not advance across omitted remainder. Every item/marker consumes positive
bytes so work is output-bounded apart from fixed probes/scalars below.

List uses single-space between heads; improper non-list tail uses ' . ' before
rendering tail (Depth-1). The reservation for unknown improper tail is3separator
+3marker; for a nonempty proper cons tail1separator+3marker. Emptytail needs0.
An already-rendered child may itself be a marker; rest can still fit reserved
marker. A final scalar child may be1/2bytes (no universal3byte child minimum).
Tuple uses element(index,Tuple), tuple_size constant metadata, single spaces.
Map uses maps:iterator(Map) DEFAULT only, maps:next; no sorting. Each map entry
is rendered as key +space+value. To attempt a pair, reserve one space+3value
marker bytes before key; if key no_fit return pair no_fit; then attempt value
in residual. If value no_fit return pair no_fit. This local pair result has no
external IO and can be discarded. Parent can replace entire pair/remainder with
marker. When there are more pairs, parent separately reserves space+3marker.
Map ordering is native default, not stable/sorted serialization guarantee.
Raw bitstring uses byte-by-byte iteration #B(1 2 ...); remaining <8bits renders
'(B (size N))' with B integer0..127, N1..7, same bounded scalar text procedure.
All sequence delimiters and omission markers fit reserved space.

## Bounded scalar/probe branches

Atoms: pinned lfe_io_write:symbol ONLY on atoms, then Unicode binary; actual
BEAM bound255characters makes allocation bounded. LFE quote escaping preserved.
Floats: io_lib_format:fwrite_g/1 (actual pinned LFE2.2 branch, installed OTP
implements float_to_list(Float,[short])), then unicode:characters_to_binary.
PID: '#Pid' prefix plus pid_to_list. Ports/ref: port_to_list/ref_to_list, preserving
old fallback spelling. External function: fun_info module/name/arity, construct
fixed '(function M F A)' with bounded symbol printers and integer arity. Internal
function: lists:droplast(fun_to_list(Fun)) + '/' + decimalarity + '>', matching
pinned printer; never fun_info env. Native scalar identities may be opaque, but
are bounded representation branches. No recursive arbitrary-term printer.

Integer: before decimal conversion, form bounded threshold T=1 bsl(4*Remaining).
If N>=T or N<=-T then decimal size exceeds Remaining, return marker/no_fit WITHOUT
abs or integer_to_binary on N. (16^Remaining>10^Remaining.) Otherwise magnitude
<16^Remaining<100^Remaining, so integer_to_binary allocates at most2*Remaining+1
bytes including sign. Check exact byte_size afterward; exact-fit scalars remain
complete. Threshold max32769significantbits, temporary text<=16385bytes at root; value
comparison may depend on native integer representation but never materializes
its full decimal digits. No arbitrary smaller integer display cap.

List string probe: read at most256chars then one tail check. If a proper list
ends within256integer characters, run printable_unicode_list and lfe_io_write:
string on ONLY that bounded list, preserving small string escapes; otherwise
structural original list. Improper/noninteger/notprintable=>structural. Never
finish a long list probe. Invalid Unicode/surrogates structural numeric values.
Binary: byte_size<=256 permits bounded unicode:characters_to_list and printable
check; valid printable => preserve #"..." form. Conversion error/incomplete or
nonprintable=>rawbytes. Larger binaries=>rawbytes without Unicode scan. Nonbyte
bitstrings use rawbytes plus exact tail. Emptybinary preserved #"".
Long printable lists/binaries become structural rather than scan-all strings;
this is explicit rendering policy, no promise of pretty syntax/roundtrip type.

## Discriminating test requirements

Small integer/sign/float/atom/escapedUnicode/string/improper/tuple/map/binary/bits,
PID/port/ref/external+internalfun, emptyvalues; literalellipsis false. Fixed8192
budget tests include4094one-digit listitems=8189bytes completefalse;4095items
may truncate early despite exact8191representation (true);4096overbudgettrue.
Exact8192-digit rootinteger false vs8193digits true, multibyte atomnear
boundary, nesting32/33, wide100klist/map/tuple/binary, million-bit signed integer,
near-budget decimal guards and exact byte counts. Every generated result checks
validUTF8 and<=8192; structural review checks bounded APIs, tests alone do not
prove arbitrary-term complexity. Avoid test-only budget knobs.
Native4 actual wire tests large boundvalue => succeeded true; subsequent small
query uses retained binding. Failed huge exception => failed true and prior env
retained; parser errors bounded; small and resource/cancel outcomes validfalse. Fixed messages also reportfalse.
All native1/2/3 authority handshakes reject, current4 scopeecho still exact.
Consumer drain Outcome match tolerates added field; JSON still serializes report,
human text UX unchanged. Full previous native/EUnit/authority/launcher/freshsource
and actual Cayrn14native+3consumer run immediately on X03 landing at matchingpins.
C05 already tests twoattachments/inspect/read/follow/spool/retry/restart metadata;
C06 still owns actual LFEhugevalue combined with twoobserverfullcomposition.


## Review resolutions and syntax precision

Independent reviewer/root/native_design_review found initial4095false oracle
contradicted conservative remainder reservation; CDC accepted, kept algorithm,
corrected tests4094false/4095earlytrue/4096true and exact scalar boundary. No
maximal-utilization promise. Remaining review: no lfe_lib:format_float API; bind
actual io_lib_format:fwrite_g/1 above. Threshold has4R+1significantbits. Emptylist
'()' must dispatch BEFORE printable-string probing, preserving its representation.
If reservation exceeds remaining budget, return no_fit BEFORE subtraction or
recursive attempt; no negative-budget path. Review evidence in preview-design-review.md.

LFE bit pattern for byte cursor uses (binary (byte (size 8)) (tail bitstring));
final0<bit_size<8 binds N then matches (binary (value (size N))). Known pinned
LFE binary syntax and native raw tail spelling #B(... (B (size N))) apply. This
is a pseudocode recipe, not claimed compiled code. Implement with small guarded
functions and ordinary term/category patterns. Any critical source contradiction
returns to CDC before dependent work; do not guess a new observable policy.

## Guideline application

Actual interim LFE style guide sections4–6: one focused pure renderer module,
explicit render1 export/doc/spec, small private helper functions with pattern
heads; no exportall or test-only helper export. Existing context message/map
style retained for this bounded seam, no process/state-representation rewrite.
Erlang DT01 SHOULD tagged results: internal fit/no_fit; native evaluated tuple
already status-tagged, now adds report boolean. DT10/11 SHOULD binary/iodata:
account UTF8 bytes before assembly, one bounded final binary, no growing-left++.
DT12/FP11 SHOULD binary patterns for bit cursor. FP01/12 SHOULD dispatch and
specific-empty-before-general order, guard budgets BEFORE recursive work. FP08
SHOULD/FP09 CONSIDER/PF08 CONSIDER: tail-recursive sibling accumulators over
potentially large input, bounded depth descent; no O(n)list length or nth scan
(PF09 SHOULD). Tuple element indexing is constant-access and fits this type;
AP19 AVOID indexed *list* iteration does not require tuple_to_list materialization.
PF07 SHOULD: final owned bounded binary, no long-lived slice retaining hugeinput.
DT16 SHOULD exported render1 spec. User exception boundary stays in evaluator;
no catchall rendering fallback that hides a missing branch or fakes false.
No new OTP lifecycle/process design in this slice: stream/root owners X04.
Rust actual drain Outcome adds '..' only to retain existing humantext, serialized
JSON event retains metadata; no UI or unrelated API refactor. Existing Rust API
validation/equality/concurrency policy remains shared Cayrn source34af63e.
