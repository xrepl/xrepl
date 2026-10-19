from pathlib import Path
import subprocess,tempfile,socket,json,struct,time,os
r=Path('/Users/oubiwann/lab/lfe/xrepl/xrepl'); out=r/'.worktrees/planning/project10-shared-repl-architecture/arc02-sustainable-native-evaluation/slice01-fenced-capture-lifetimes/artifacts'
base=Path(tempfile.mkdtemp(prefix='x21-cdc-launch.',dir='/private/tmp')); endpoint=base/'agent with spaces.sock'
records=[]
with (out/'cdc-root-launcher.log').open('w') as log:
 p=subprocess.Popen([str(r/'bin/cayrn-lfe'),str(endpoint)],cwd='/private/tmp',stdout=log,stderr=subprocess.STDOUT)
 try:
  until=time.monotonic()+10
  while not endpoint.exists():
   if p.poll() is not None:raise RuntimeError('owned agent exited before socket')
   if time.monotonic()>until:raise TimeoutError('owned agent socket')
   time.sleep(.02)
  with socket.socket(socket.AF_UNIX,socket.SOCK_STREAM) as s:
   s.settimeout(5);s.connect(str(endpoint))
   def send(v):
    b=json.dumps(v).encode();s.sendall(struct.pack('>I',len(b))+b);records.append({'sent':v})
   def readn(n):
    b=b''
    while len(b)<n:
     part=s.recv(n-len(b))
     if not part:raise EOFError('native stream ended')
     b+=part
    return b
   def recv():
    v=json.loads(readn(struct.unpack('>I',readn(4))[0]));records.append({'received':v});return v
   send({'kind':'hello','version':2,'session':'cdc-launcher','generation':'g','authority':'a'});ready=recv();assert ready['kind']=='ready' and ready['version']==2
   source='(lists:sort (lists:map (lambda (app) (element 1 app)) (application:which_applications)))'
   send({'kind':'dispatch','operation':'2','source':source,'generation':'g','authority':'a'})
   result=recv();assert result['kind']=='outcome' and result['phase']=='succeeded',result
   assert result['value']=='(cayrn_lfe compiler kernel lfe stdlib)',result
   send({'kind':'close'});assert recv()['kind']=='closed'
 finally:
  p.terminate()
  try:rc=p.wait(timeout=5)
  except subprocess.TimeoutExpired:p.kill();p.wait();raise
  log.write('\nIndependent /root launcher transcript:\n'+json.dumps({'cwd':'/private/tmp','endpoint':str(endpoint),'source':'7228183','records':records,'owned_process_exit':rc},indent=2)+'\n')
print('Root native-only launcher, spaced socket, v2 evaluation and close pass')
