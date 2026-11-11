from pathlib import Path
import json,hashlib
from PIL import Image
from playwright.sync_api import sync_playwright
root=Path(__file__).resolve().parent
imgs=sorted(root.glob('*/*_dark.gif'))
html='<!doctype html><meta charset="utf-8"><title>Monsters round 2 dark GIF review</title><style>body{background:#1e222b;color:#ddd;font:11px sans-serif;margin:8px}main{display:grid;grid-template-columns:repeat(7,180px);gap:5px}figure{margin:0}img{width:180px;height:180px}figcaption{height:24px}</style><main>'
for p in imgs:html+=f'<figure><figcaption>{p.parent.name}/{p.stem.removesuffix("_dark")}</figcaption><img src="{p.relative_to(root).as_posix()}"></figure>'
html+='</main>'; (root/'review.html').write_text(html)
with sync_playwright() as p:
 browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True)
 page=browser.new_page(viewport={'width':1310,'height':1300},device_scale_factor=1)
 page.goto('http://127.0.0.1:8820/review.html');page.wait_for_function('Array.from(document.images).every(i=>i.complete&&i.naturalWidth>0)')
 errors=[];page.on('pageerror',lambda e:errors.append(str(e)))
 samples=[]
 for i in range(4):
  page.wait_for_timeout(137)
  samples.append(page.evaluate('''() => Array.from(document.images).map(im=>{let c=document.createElement('canvas');c.width=im.naturalWidth;c.height=im.naturalHeight;c.getContext('2d').drawImage(im,0,0);return c.toDataURL()})'''))
  page.screenshot(path=str(root/f'gif_review_{i}.png'),full_page=True)
 boxes=page.evaluate('Array.from(document.images).map(i=>{let r=i.getBoundingClientRect();return [r.x,r.y,r.x+r.width,r.y+r.height]})')
 shots=[Image.open(root/f'gif_review_{i}.png').convert('RGB') for i in range(4)]
 changed=sum(len({hashlib.sha256(sh.crop(tuple(round(v) for v in boxes[i])).tobytes()).hexdigest() for sh in shots})>1 for i in range(len(imgs)))
 result={'browser':'Chromium','loaded_gifs':len(imgs),'sample_interval_ms':137,'samples':4,'changed_between_samples':changed,'page_errors':errors}
 (root/'browser_review.json').write_text(json.dumps(result,indent=2)); print(json.dumps(result));browser.close()
