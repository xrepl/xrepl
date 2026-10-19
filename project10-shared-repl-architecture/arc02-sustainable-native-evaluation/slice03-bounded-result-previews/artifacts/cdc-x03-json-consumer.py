from pathlib import Path
import tempfile,subprocess,time,json,shutil
x=Path('/Users/oubiwann/lab/lfe/xrepl/xrepl');c=Path('/Users/oubiwann/lab/oxur/cayrn');d=Path(tempfile.mkdtemp(prefix='cayrn-cdc-x03-json-',dir='/private/tmp'));agent_sock=d/'agent.sock';state=d/'host';processes=[];handles=[]
def start(args,name):
 f=(d/(name+'.log')).open('w');handles.append(f);p=subprocess.Popen(args,stdout=f,stderr=subprocess.STDOUT,cwd='/private/tmp');processes.append((name,p));print('START',name,args,flush=True);return p
def ready(path,p):
 end=time.monotonic()+10
 while not path.exists():
  assert p.poll() is None,('startup exited',p.returncode)
  if time.monotonic()>end:raise TimeoutError(str(path))
  time.sleep(.01)
try:
 agent=start([str(x/'bin/cayrn-lfe'),str(agent_sock)],'agent');ready(agent_sock,agent)
 host=start([str(c/'bin/cayrn'),'serve-agent','--state-dir',str(state),'--agent-socket',str(agent_sock)],'host');ready(state/'cayrn.sock',host)
 args=[str(x/'target/debug/xrepl'),'--cayrn',str(state),'--cayrn-json'];print('ARGV',args,flush=True)
 p=subprocess.run(args,input='(set saved-preview (lists:duplicate 100000 1))\n(length saved-preview)\n:quit\n',capture_output=True,text=True,timeout=20)
 print('XREPL STDOUT\n'+p.stdout,flush=True);print('XREPL STDERR\n'+p.stderr,flush=True);print('XREPL EXIT',p.returncode,flush=True);assert p.returncode==0
 rows=[json.loads(line) for line in p.stdout.splitlines() if line.strip()];out=[row['event'] for row in rows if row.get('event',{}).get('kind')=='outcome'];assert len(out)==2,out
 assert out[0]['phase']=='succeeded' and out[0]['preview']=={'truncated':True} and len(out[0]['value'].encode())<=8192
 assert out[1]['phase']=='succeeded' and out[1]['value']=='100000' and out[1]['preview']=={'truncated':False}
 print('ACTUAL RUST JSON TRUE/FALSE METADATA + FULL RETAINED BINDING PASS; two Outcome events, no two-observer composition claim.',flush=True)
finally:
 for name,p in reversed(processes):
  p.terminate()
  try:p.wait(timeout=5)
  except subprocess.TimeoutExpired:p.kill();p.wait()
  print('OWNED PROCESS',name,'EXIT',p.returncode,flush=True)
 for f in handles:f.close()
 for name,_ in processes:print(name+' LOG\n'+(d/(name+'.log')).read_text(),flush=True)
 shutil.rmtree(d)
