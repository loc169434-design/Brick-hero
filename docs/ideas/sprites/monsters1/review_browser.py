from pathlib import Path
from functools import partial
from http.server import ThreadingHTTPServer,SimpleHTTPRequestHandler
import threading,argparse,json,hashlib
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('monster');a=p.parse_args();base=Path(__file__).resolve().parent/a.monster
class Quiet(SimpleHTTPRequestHandler):
 def log_message(self,*args):pass
server=ThreadingHTTPServer(('127.0.0.1',0),partial(Quiet,directory=str(base)))
threading.Thread(target=server.serve_forever,daemon=True).start()
try:
 with sync_playwright() as pw:
  browser=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
  page=browser.new_page(viewport={'width':1480,'height':1100})
  page.goto(f'http://127.0.0.1:{server.server_port}/review.html');page.wait_for_function('Array.from(document.images).every(i=>i.complete&&i.naturalWidth>0)')
  captures=[]
  for i,t in enumerate([0,160,170,200]):
   if t:page.wait_for_timeout(t)
   data=page.screenshot(path=f'/tmp/{a.monster}_review_{i}.png',full_page=True);captures.append(hashlib.sha256(data).hexdigest())
  n=page.locator('img').count();assert n in (6,7) and len(set(captures))>1
  (base/'browser_review.json').write_text(json.dumps({'loaded_dark_gifs':n,'temporal_capture_sha256':captures,'animated_captures_differ':True},indent=2)+'\n')
  browser.close();print(a.monster,n,'GIFs loaded; four temporal captures differ')
finally:server.shutdown()
