from pathlib import Path
import socket,struct,json,uuid,subprocess,tempfile,time,hashlib
root=Path('/Users/oubiwann/lab/lfe/xrepl/xrepl')
art=Path('/private/tmp/cdc-x03')
dir=Path(tempfile.mkdtemp(prefix='cayrn-x03-root launch ',dir='/private/tmp'))
path=dir/'agent socket.sock'
lines=['$ '+str(root/'bin/cayrn-lfe')+' '+repr(str(path)),'CWD /private/tmp']
proc_log=art/'cdc-root-launcher-process.log'
def write(s,v):
 b=json.dumps(v,separators=(',',':')).encode();s.sendall(struct.pack('!I',len(b))+b);lines.append('SEND '+json.dumps(v))
def exact(s,n):
 b=b''
 while len(b)<n:
  part=s.recv(n-len(b))
  if not part:raise RuntimeError('unexpected EOF')
  b+=part
 return b
def read(s):
 n=struct.unpack('!I',exact(s,4))[0];assert n<=262144
 v=json.loads(exact(s,n));lines.append('RECV '+json.dumps(v,ensure_ascii=False));return v
def connect():
 s=socket.socket(socket.AF_UNIX,socket.SOCK_STREAM);s.settimeout(3);s.connect(str(path));return s
f=proc_log.open('w');p=subprocess.Popen([str(root/'bin/cayrn-lfe'),str(path)],cwd='/private/tmp',stdout=f,stderr=subprocess.STDOUT)
try:
 deadline=time.monotonic()+10
 while not path.exists():
  assert p.poll() is None,'launcher ended'
  if time.monotonic()>deadline:raise TimeoutError('launcher socket')
  time.sleep(.01)
 with connect() as authority:
  aid=str(uuid.uuid4());write(authority,dict(kind='authority_hello',version=4,authority=aid));grant=read(authority)
  assert grant['kind']=='authority_ready' and grant['version']==4
  with connect() as context:
   scope=dict(boot=grant['boot'],lease=grant['lease'],ticket='1');write(context,dict(kind='hello',version=4,session='root-smoke',generation='g',authority=aid,**scope));ready=read(context)
   assert ready['kind']=='ready' and ready['version']==4 and all(ready[k]==v for k,v in scope.items())
   for operation,source,expected in [('1','(+ 20 22)','42'),('2','(lists:sort (lists:map (lambda (entry) (element 1 entry)) (application:which_applications)))','(cayrn_lfe compiler crypto kernel lfe stdlib)')]:
    write(context,dict(kind='dispatch',operation=operation,source=source,generation='g',authority=aid));out=read(context)
    assert out['kind']=='outcome' and out['phase']=='succeeded' and out['value']==expected and out['preview']=={'truncated':False},out
   write(context,dict(kind='close'));assert read(context)['kind']=='closed'
 lines.append('EXIT 0')
except BaseException as exc:
 lines.append('FAIL '+repr(exc));lines.append('EXIT 1');raise
finally:
 p.terminate()
 try:p.wait(timeout=5)
 except subprocess.TimeoutExpired:p.kill();p.wait()
 f.close();lines.append('launcher process return '+str(p.returncode))
 (art/'cdc-root-launcher.log').write_text('\n'.join(lines)+'\n')
 if path.exists():path.unlink()
 dir.rmdir()
print('\n'.join(lines))
