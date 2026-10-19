from pathlib import Path
import json,subprocess,hashlib
r=Path('/Users/oubiwann/lab/lfe/xrepl/xrepl');sl=r/'.worktrees/planning/project10-shared-repl-architecture/arc01-integrated-native-agent/slice02-lfe-agent-implementation';d=json.loads((sl/'artifacts/source-baseline.json').read_text());entries=[]
for row in d['native_export_inventory']:
 module=row['module'];target=('test' if module.endswith('_tests') else 'ebin');parts=r/'apps/cayrn_lfe/_build/test/lib/cayrn_lfe';path=parts/target
 expr='M='+module+',C=M:module_info(compile),{ok,{_,[{abstract_code,{raw_abstract_v1,A}}]}}=beam_lib:chunks(code:which(M),[abstract_code]),io:format("~s",[json:encode(#{source=>unicode:characters_to_binary(proplists:get_value(source,C)),exports=>[#{name=>atom_to_binary(F),arity=>N}||{F,N}<-M:module_info(exports)],spec_count=>length([S||{attribute,_,spec,S}<-A])})]),halt().'
 value=json.loads(subprocess.check_output(['erl','-noshell','-pa',str(parts/'ebin'),str(parts/'test'),'-eval',expr],text=True))
 assert value['source'].endswith(module+'.lfe'),value
 old={(e['name'],e['arity']) for e in row['exports']}-{('module_info',0),('module_info',1),('test',0)}
 new={(e['name'],e['arity']) for e in value['exports']};assert old <= new
 assert new-old <= {('module_info',0),('module_info',1),('test',0),('__info__',1),('LFE-EXPAND-EXPORTED-MACRO',3),('native_agent_companions_test_',0)}
 name=('test/' if module.endswith('_tests') else 'src/')+module
 oldbytes=subprocess.check_output(['git','show','ea844f5:apps/cayrn_lfe/'+name+'.erl'],cwd=r);newpath=r/'apps/cayrn_lfe'/(name+'.lfe');assert value['spec_count']==oldbytes.count(b'-spec '),(module,value['spec_count'])
 entries.append({'module':module,'old_path':'apps/cayrn_lfe/'+name+'.erl','new_path':'apps/cayrn_lfe/'+name+'.lfe','old_sha256':hashlib.sha256(oldbytes).hexdigest(),'new_sha256':hashlib.sha256(newpath.read_bytes()).hexdigest(),'mode':'100644','old_declared_exports':sorted([list(x) for x in old]),'actual_exports':value['exports'],'actual_compile_source':value['source'],'spec_count':value['spec_count'],'extra_export_classification':'LFE compiler/EUnit generated; I/O native_agent_companions_test_/0 is authored test discovery only'})
 print(module,'LFE source verified;',len(old),'declared exports retained;',value['spec_count'],'specs')
unchanged=[p for p in d['xrepl']['files'] if p.endswith(('rebar.lock','rebar.config','cayrn_lfe.app.src','xrepl.app.src','bin/cayrn-lfe','Makefile','mk/lfe.mk','Cargo.lock','src/cayrn-lfe-eval.lfe','LICENSE'))]
for p in unchanged:assert hashlib.sha256((r/p).read_bytes()).hexdigest()==d['xrepl']['files'][p],p
print('Unchanged protected inputs:',len(unchanged))
(sl/'artifacts/conversion-map.json').write_text(json.dumps({'source_base':d['xrepl']['commit'],'state':'uncommitted LFE candidate','entries':entries,'preserved_inputs':unchanged,'test_cases':['persistent_bindings_test','errors_preserve_committed_environment_test','functions_and_macro_context_test','ordinary_error_atom_is_a_value_test','capture_requires_owner_ack_test','seal_orders_prior_capture_and_rejects_late_writes_test','independent_application_start_test_'],'discovery_refinement':'I/O companion native_agent_companions_test_/0 includes evaluator/application modules so component Rebar discovery runs all seven cases; no Make/config/dependency change'},indent=2)+'\n')
