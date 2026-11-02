/* Offline sprite-sheet player. No fetch(), external fonts, libraries, or services. */
(async () => {
  if (new URLSearchParams(location.search).has('export')) return;
  const P = window.TILE_PACK, R = window.TileRenderer, $ = s => document.querySelector(s);
  const root = R.root, urlFor = R.urlFor;
  const state = { family: 'orc_shield', color: 'red', animation: 'idle', time: 0, playing: !matchMedia('(prefers-reduced-motion: reduce)').matches, loop: true, speed: 1, queue: [], detailPose: null };
  const cache = new Map();
  const path = (f, c, a) => 'assets/tiles/' + f + '/animations/' + c + '_' + a + '.png';
  async function image(relative) {
    if (!cache.has(relative)) cache.set(relative, new Promise((res, rej) => { const im = new Image(); im.onload = () => res(im); im.onerror = () => rej(new Error('Không tải được ' + relative)); im.src = urlFor(relative); }));
    return cache.get(relative);
  }
  let sheets = {}, serial = 0;
  const notes = {
    idle:'Nghỉ và chớp mắt; trạng thái duy nhất mặc định lặp vô hạn.', drop:'Rơi có tăng tốc, nén khi chạm đất và bụi.', land:'Nén → nảy → đứng yên; dùng khi game đã tự di chuyển gạch.',
    combo:'Ô bị xóa: Orc hét, gạch thu nhỏ và văng vụn gỗ. Hết cảnh sẽ trong suốt.', hurt:'Trúng đòn nhưng còn sống: nhăn mặt, rung ngắn rồi trở về.', taunt:'Lượt không xóa ô / đòn hụt: Orc cười chọc một nhịp, không chê người chơi bằng chữ.',
    fear:'Dự đoán combo có thể hạ quái: mắt mở to, run sợ.', near_miss:'0–38% sợ · 38–60% nhẹ nhõm · 60–100% cười vì thoát chết.', gloat:'Người chơi gần thua: cười hiểm, chỉ phát khi trạng thái trận cho phép.',
    death:'Orc bị hạ: hoảng → hét → biến mất và văng vụn gỗ.', win:'Người chơi thắng: training nhảy mừng; Orc hét và biến mất, có giấy mừng.', lose:'Người chơi thua: training chùng xuống; Orc cười hiểm → cười lớn, vẫn còn trên sân.'
  };
  function error(e) { $('#status').textContent = e.message; $('#status').classList.add('error'); state.playing = false; }
  function syncPlay() { $('#play').textContent = state.playing ? 'Tạm dừng' : 'Phát'; $('#play').setAttribute('aria-label',state.playing?'Tạm dừng':'Phát'); }
  async function select(f, c, a, clearQueue = true) {
    const ticket = ++serial;
    state.family=f; state.color=c; state.animation=a; state.time=0; state.detailPose=null;
    if (clearQueue) state.queue=[];
    state.loop=!!P.animations[a].loop; $('#loop').checked=state.loop;
    $('#status').textContent='Đang tải sprite sheet…';
    try {
      const result = await Promise.all(P.colors.map(color => image(path(f,color,a))));
      if (ticket!==serial) return;
      sheets=Object.fromEntries(P.colors.map((color,i)=>[color,result[i]]));
      document.querySelectorAll('[data-family]').forEach(b=>b.setAttribute('aria-pressed',b.dataset.family===f));
      document.querySelectorAll('[data-color]').forEach(b=>b.classList.toggle('active',b.dataset.color===c));
      buildEvents(); buildExpressions();
      const spec=P.animations[a], relative=path(f,c,a);
      $('#stage-label').textContent=P.families[f].label.toUpperCase()+' / '+a.toUpperCase();
      $('#event-note').textContent=notes[a];
      $('#atlas').src=urlFor(relative);
      $('#atlas-download').href=urlFor(relative);
      $('#godot-download').href=urlFor('assets/tiles/'+f+'/sprite_frames_'+c+'.tres');
      $('#atlas-info').textContent='24 frame · ô 192×192 · 8 cột × 3 hàng · '+spec.seconds+' giây · '+(24/spec.seconds).toFixed(2)+' fps';
      $('#status').textContent=P.families[f].label+' · '+P.colorLabels[P.colors.indexOf(c)]+' · '+spec.label;
      $('#status').classList.remove('error');
      render(); syncPlay();
    } catch(e) { if(ticket===serial) error(e); }
  }
  function buildEvents() {
    $('#events').replaceChildren();
    for(const name of P.families[state.family].animations){const b=document.createElement('button');b.textContent=P.animations[name].label;b.dataset.animation=name;b.classList.toggle('active',name===state.animation);b.onclick=()=>{state.playing=true;select(state.family,state.color,name)};$('#events').append(b)}
    document.querySelectorAll('[data-scene]').forEach(b=>{b.disabled=state.family==='training'&&b.dataset.scene!=='training'});
  }
  function buildExpressions(){
    $('#expression-panel').hidden=state.family!=='orc_shield';
    $('#character-name').textContent=P.colorLabels[P.colors.indexOf(state.color)];
    $('#expressions').replaceChildren();
    if(state.family!=='orc_shield')return;
    P.expressions.forEach((pose,i)=>{const box=document.createElement('div');box.className='expression';const im=document.createElement('img');im.src=urlFor('assets/tiles/orc_shield/expressions/'+state.color+'_'+pose+'.png');im.alt=P.expressionLabels[i];const b=document.createElement('button');b.textContent=P.expressionLabels[i];b.onclick=()=>{state.playing=false;state.queue=[];state.detailPose=i;$('#detail-title').textContent='Ảnh gốc · '+P.expressionLabels[i];syncPlay();render()};box.append(im,b);$('#expressions').append(box)});
    $('#expression-download').href=urlFor('assets/tiles/orc_shield/expressions_'+state.color+'.png');
  }
  function paintFrame(ctx,im,frame,x,y,size){ctx.drawImage(im,(frame%8)*192,Math.floor(frame/8)*192,192,192,x,y,size,size)}
  function render(){
    if(!sheets[state.color])return;
    const spec=P.animations[state.animation],frame=Math.min(23,Math.floor(state.time/spec.seconds*24+1e-7));
    const c=$('#stage'),ctx=c.getContext('2d');ctx.clearRect(0,0,c.width,c.height);
    ctx.strokeStyle='#ffffff0b';ctx.lineWidth=1;for(let x=40;x<800;x+=48){ctx.beginPath();ctx.moveTo(x,65);ctx.lineTo(x,550);ctx.stroke()}for(let y=70;y<570;y+=48){ctx.beginPath();ctx.moveTo(30,y);ctx.lineTo(770,y);ctx.stroke()}
    ctx.fillStyle='#0005';ctx.beginPath();ctx.ellipse(400,486,115,18,0,0,Math.PI*2);ctx.fill();
    const size=$('#actual-size').checked?165:440;
    paintFrame(ctx,sheets[state.color],frame,400-size/2,300-size/2,size);
    ctx.font='600 18px system-ui';ctx.fillStyle='#c4bca9';ctx.textAlign='center';ctx.fillText(spec.label,400,565);
    $('#timeline').value=frame;
    $('#frame-info').textContent='Frame '+(frame+1)+' / 24';
    $('#timing-info').textContent=state.time.toFixed(2)+' / '+spec.seconds.toFixed(2)+' s';
    for(const color of P.colors){const m=document.querySelector('[data-mini="'+color+'"]');if(m){const mc=m.getContext('2d');mc.clearRect(0,0,192,192);paintFrame(mc,sheets[color],frame,0,0,192)}}
    const dc=$('#frame-detail').getContext('2d');dc.clearRect(0,0,192,192);
    if(state.detailPose!==null&&state.family==='orc_shield'){
      const i=state.detailPose;dc.drawImage(R.images['orc_shield_'+state.color],i%3*128,Math.floor(i/3)*128,128,128,32,32,128,128);
      $('#frame-path').textContent='expressions/'+state.color+'_'+P.expressions[i]+'.png';$('#pose-info').textContent='Ảnh biểu cảm riêng 128×128 · '+P.expressionLabels[i];
    }else{
      paintFrame(dc,sheets[state.color],frame,0,0,192);$('#detail-title').textContent='Chi tiết frame '+(frame+1);
      $('#frame-path').textContent=path(state.family,state.color,state.animation);
      const pose=R.poseAt(state.animation,Math.min(1,frame/23));
      $('#pose-info').textContent='Rect: '+(frame%8*192)+', '+(Math.floor(frame/8)*192)+', 192, 192 · '+(state.family==='training'?'Biểu tượng gỗ':P.expressionLabels[pose]);
    }
  }
  for(const [i,color] of P.colors.entries()){
    const b=document.createElement('button');b.className='color-chip';b.dataset.color=color;b.title=P.colorLabels[i];b.setAttribute('aria-label',P.colorLabels[i]);b.style.setProperty('--chip',['#c44935','#598d3a','#d4a337','#80549e'][i]);b.onclick=()=>select(state.family,color,state.animation);$('#colors').append(b);
    const box=document.createElement('div');box.className='mini';const cv=document.createElement('canvas');cv.width=cv.height=192;cv.dataset.mini=color;const text=document.createElement('small');text.textContent=P.colorLabels[i].split(' · ')[0];box.append(cv,text);$('#all-colors').append(box);
  }
  const fxNames=['dust_small','dust_large','impact_small','impact_large','splinters_small','splinters_large','confetti_small','confetti_large'];
  for(const name of fxNames){const a=document.createElement('a');a.className='fx-cell';a.href=urlFor('assets/fx/tile_reactions/'+name+'.png');a.download=name+'.png';const im=document.createElement('img');im.src=a.href;im.alt=name;const text=document.createElement('small');text.textContent=name;a.append(im,text);$('#fx-grid').append(a)}
  document.querySelectorAll('[data-family]').forEach(b=>b.onclick=()=>select(b.dataset.family,state.color,P.families[b.dataset.family].animations.includes(state.animation)?state.animation:'idle'));
  $('#play').onclick=()=>{if(state.time>=P.animations[state.animation].seconds)state.time=0;state.playing=!state.playing;state.detailPose=null;syncPlay()};
  $('#restart').onclick=()=>{state.time=0;state.playing=true;state.queue=[];state.detailPose=null;syncPlay()};
  $('#step').onclick=()=>{state.playing=false;state.queue=[];state.detailPose=null;const seconds=P.animations[state.animation].seconds;const next=Math.min(23,Math.floor(state.time/seconds*24+1e-7)+1);state.time=next/24*seconds;syncPlay();render()};
  $('#timeline').oninput=e=>{state.playing=false;state.queue=[];state.detailPose=null;state.time=Number(e.target.value)/24*P.animations[state.animation].seconds;syncPlay();render()};
  $('#speed').onchange=e=>state.speed=Number(e.target.value);
  $('#loop').onchange=e=>{state.loop=e.target.checked;state.queue=[]};
  $('#actual-size').onchange=render;
  const scenarios={near:['hurt','near_miss','idle'],victory:['hurt','win'],defeat:['gloat','lose'],training:['drop','land','combo','win']};
  document.querySelectorAll('[data-scene]').forEach(b=>b.onclick=()=>{const family=b.dataset.scene==='training'?'training':'orc_shield';const [first,...rest]=scenarios[b.dataset.scene];state.playing=true;select(family,state.color,first).then(()=>{state.queue=rest;state.loop=false;$('#loop').checked=false})});
  try{await R.ready;await select(state.family,state.color,'idle')}catch(e){error(e);return}
  let last=performance.now(),transitioning=false;
  function tick(now){const dt=Math.min(.1,(now-last)/1000);last=now;if(state.playing&&!transitioning){state.time+=dt*state.speed;const duration=P.animations[state.animation].seconds;if(state.time>=duration){if(state.queue.length){transitioning=true;const next=state.queue.shift();select(state.family,state.color,next,false).then(()=>{transitioning=false})}else if(state.loop){state.time%=duration}else{state.time=duration;state.playing=false;syncPlay()}}render()}requestAnimationFrame(tick)}
  requestAnimationFrame(tick);
  window.artPreview={state,ready:true,select,render,cache};
})();
