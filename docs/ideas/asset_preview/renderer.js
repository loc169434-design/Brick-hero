/* Pure deterministic Canvas renderer. Artwork comes from the generated PNGs. */
(() => {
  const pack = window.TILE_PACK;
  const root = new URL('../../../', document.currentScript.src || location.href);
  const urlFor = path => window.TILE_EMBEDDED?.[path] || new URL(path, root).href;
  const images = {};
  function load(key, path) {
    return new Promise((resolve, reject) => {
      const im = new Image();
      im.onload = () => { images[key] = im; resolve(); };
      im.onerror = () => reject(new Error('Không tải được: ' + path));
      im.src = urlFor(path);
    });
  }
  const ready = Promise.all([
    ...pack.colors.flatMap(c => [load('training_' + c, 'assets/tiles/training/tile_' + c + '.png'), load('orc_shield_' + c, 'assets/tiles/orc_shield/expressions_' + c + '.png')]),
    load('fx', 'assets/fx/tile_reactions/effects.png')
  ]);
  const clamp = x => Math.max(0, Math.min(1, x));
  const smooth = x => { x = clamp(x); return x * x * (3 - 2 * x); };
  function poseAt(animation, t) {
    let p = 0;
    for (const [at, pose] of pack.animations[animation].poses) if (t >= at) p = pose;
    return p;
  }
  function drawSource(ctx, family, color, pose, x, y, size) {
    const im = images[family + '_' + color];
    const sx = family === 'training' ? 0 : (pose % 3) * 128;
    const sy = family === 'training' ? 0 : Math.floor(pose / 3) * 128;
    ctx.drawImage(im, sx, sy, 128, 128, x, y, size, size);
  }
  function effect(ctx, i, x, y, size, alpha = 1) {
    ctx.save(); ctx.globalAlpha *= clamp(alpha);
    ctx.drawImage(images.fx, (i % 4) * 128, Math.floor(i / 4) * 128, 128, 128, x - size / 2, y - size / 2, size, size);
    ctx.restore();
  }
  function draw(ctx, { family, color, animation, t, fx = true, size = 192 }) {
    t = clamp(t);
    const spec = pack.animations[animation];
    let x = 96, y = 96, sx = 1, sy = 1, rotation = 0, alpha = 1;
    const orc = family === 'orc_shield';
    const laughing = (animation === 'taunt' || (animation === 'near_miss' && t > .6) || (orc && animation === 'lose' && t > .35));
    if (animation === 'idle') { sy = 1 + Math.sin(t * Math.PI * 2) * .015; y -= Math.sin(t * Math.PI * 2) * 1.3; }
    if (spec.motion === 'drop') {
      if (t < .65) { const p = t / .65; y = 18 + 78 * p * p; sx = .94; sy = 1.07; }
      else { const p = (t - .65) / .35; sx = 1 + .17 * Math.sin(p * Math.PI * 3) * (1 - p); sy = 2 - sx; }
    }
    if (spec.motion === 'land') { sx = 1 + .18 * Math.sin(t * Math.PI * 3) * (1 - t); sy = 2 - sx; }
    if (spec.motion === 'hurt') { x += Math.sin(t * 42) * 5 * (1 - t); rotation = Math.sin(t * 35) * .07 * (1 - t); }
    if (animation === 'fear' || (animation === 'near_miss' && t < .38)) { x += Math.sin(t * 140) * 2.6; sy = .97; }
    if (laughing) { y -= Math.abs(Math.sin(t * 30)) * 5; sx = 1 + Math.sin(t * 30) * .025; sy = 2 - sx; rotation = Math.sin(t * 12) * .035; }
    if (animation === 'gloat' || (orc && animation === 'lose')) rotation += Math.sin(t * 10) * .035;
    if (animation === 'combo') { const p = smooth((t - .38) / .58); sx = sy = 1 + .1 * Math.sin(t * Math.PI) - p * .9; alpha = 1 - p; rotation = p * .3; }
    const dying = animation === 'death' || (animation === 'win' && orc);
    if (dying) { const p = smooth((t - .43) / .52); x += Math.sin(t * 100) * 2 * (1 - p); sx = sy = 1 - .7 * p; y += 34 * p; rotation = p * .25; alpha = 1 - p; }
    if (animation === 'win' && !orc) { y -= Math.abs(Math.sin(t * Math.PI * 4)) * 12 * (1 - t); rotation = Math.sin(t * 16) * .045 * (1 - t); }
    if (animation === 'lose' && !orc) { rotation = Math.sin(t * 30) * .07 * (1 - t); y += 12 * smooth(t); alpha = 1 - .58 * smooth(t); }
    ctx.save(); ctx.scale(size / 192, size / 192);
    ctx.save(); ctx.translate(x, y); ctx.rotate(rotation); ctx.scale(sx, sy); ctx.globalAlpha = alpha;
    drawSource(ctx, family, color, poseAt(animation, t), -64, -64, 128);
    ctx.restore();
    if (fx) {
      if (animation === 'drop' && t > .65) { const p = (t - .65) / .35; effect(ctx, p < .45 ? 0 : 1, 96, 147, 80 + p * 70, 1 - p); }
      if (animation === 'land') effect(ctx, t < .4 ? 0 : 1, 96, 147, 70 + t * 75, 1 - t);
      if (animation === 'hurt' && t < .6) effect(ctx, 2, 138, 56, 56, 1 - t / .6);
      if (animation === 'combo' && t > .3) {
        const p = (t - .3) / .7;
        effect(ctx, p < .3 ? 3 : (p < .6 ? 4 : 5), 96, 96, 90 + p * 96, 1 - p);
      }
      if (dying && t > .52) effect(ctx, t < .72 ? 4 : 5, 96, 110, 110 + t * 64, (1 - t) * 1.8);
      if (animation === 'win' && t > .25) effect(ctx, t < .6 ? 6 : 7, 96, 76 + t * 20, 170, Math.sin((t - .25) / .75 * Math.PI));
      if (animation === 'lose' && !orc) { ctx.fillStyle = '#4a343b'; ctx.globalAlpha = t * .12; ctx.fillRect(32, 32, 128, 128); }
    }
    ctx.restore();
  }
  window.TileRenderer = { ready, draw, poseAt, images, root, urlFor };
})();
