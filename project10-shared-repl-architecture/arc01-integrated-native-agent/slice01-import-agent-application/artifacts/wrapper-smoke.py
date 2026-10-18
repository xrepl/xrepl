import tempfile,subprocess,pathlib,socket,struct,json,time
root='/Users/oubiwann/lab/lfe/xrepl/xrepl'
with tempfile.TemporaryDirectory(prefix='cayrn-wrapper-',dir='/private/tmp') as directory:
 path=pathlib.Path(directory)/'agent socket.sock'
 log=open(pathlib.Path(directory)/'node.log','w+')
 child=subprocess.Popen([root+'/bin/cayrn-lfe',str(path)],cwd='/private/tmp',stdout=log,stderr=subprocess.STDOUT)
 try:
  end=time.monotonic()+10
  while not path.exists():
   if child.poll() is not None:log.seek(0);raise RuntimeError(log.read())
   if time.monotonic()>end:raise RuntimeError('socket timeout')
   time.sleep(.01)
  with socket.socket(socket.AF_UNIX,socket.SOCK_STREAM) as stream:
   stream.settimeout(5);stream.connect(str(path))
   def send(x):
    data=json.dumps(x).encode();stream.sendall(struct.pack('>I',len(data))+data)
   def exact(n):
    data=b''
    while len(data)<n:
     b=stream.recv(n-len(data))
     if not b:raise EOFError()
     data+=b
    return data
   def receive():return json.loads(exact(struct.unpack('>I',exact(4))[0]))
   send(dict(kind='hello',version=1,session='wrapper-session',generation='wrapper-generation',authority='wrapper-authority'))
   assert receive()['kind']=='ready'
   source='(lists:sort (lists:map (lambda (app) (element 1 app)) (application:which_applications)))'
   send(dict(kind='dispatch',operation='apps',generation='wrapper-generation',authority='wrapper-authority',source=source))
   result=receive();print(json.dumps(result));assert result['kind']=='outcome' and result['phase']=='succeeded'
   apps=set(result['value'].strip('()').split());assert {'cayrn_lfe','lfe'} <= apps;assert not apps & {'xrepl','ranch','xrepl_protocol','xrepl_term'},result
   send(dict(kind='close'));assert receive()['kind']=='closed'
  print('PASS: root wrapper from /private/tmp, socket path contains spaces; required native apps present; legacy services absent (LFE may load OTP compiler)')
 finally:
  child.terminate()
  try:child.wait(timeout=10)
  except subprocess.TimeoutExpired:child.kill();child.wait()
  log.close()
