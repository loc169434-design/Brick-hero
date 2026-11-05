"""Repack whole, already drawn figures after the #41 cell-boundary review.

No painting, alpha masking, body-part assembly or new art. Requires Pillow.
Sources and measured rectangular crop boxes: campaign_g2_sources.json.
"""
import json
from PIL import Image
import pack_campaign_g2 as p

def main():
    p.MANIFEST=json.loads((p.DOC/'campaign_g2_sources.json').read_text())
    # These sources have uneven row spacing: repack every clip and standing pose.
    for cid in ['crocodile','toad_spitter']:
        p.character(cid,p.actor_cells(cid))
    # Other sources require only isolated cell corrections. Preserve all other
    # exported cells, timings, rig anchors and neutral-boundary conventions.
    for cid,key,rows,clip,mapping in [
        ('toad_witch','toad_witch',8,'attack',{2:6,3:7}),
        ('goblin_bomber','goblin_bomber',8,'special',{4:18}),
        ('swamp_spider','swamp_spider',8,'special',{4:18}),
        ('toad_witch_giant','toad_witch_giant',8,'defeat',{5:27}),
        ('fairy_fickle','npc_fairy_fickle',3,'wave',{1:5}),
    ]:
        raw=p.actor_cells(key,rows);frames=p.register(raw)
        dest=p.ROOT/'assets/characters'/cid
        path=dest/'anim'/f'fresh_{clip}.png';atlas=Image.open(path).convert('RGBA')
        for target,source in mapping.items():
            atlas.paste(frames[source],(target%4*512,target//4*512))
        atlas.save(path,optimize=True)
        meta=json.loads((dest/'anim/anim.json').read_text())['clips'][clip]
        exported=[atlas.crop((i%4*512,i//4*512,i%4*512+512,i//4*512+512)) for i in range(meta['frames'])]
        if clip=='defeat':exported[-1].save(dest/'defeat.png',optimize=True)
        p.preview(cid+'_'+clip,exported,meta['fps'])
    print('Repacked crocodile/toad_spitter completely and six corrected cells in five other actors.')

if __name__=='__main__':main()
