"""Read-only alpha topology checks. Requires Pillow, numpy and scipy.

An actor is one 8-connected silhouette. A detached island >200 visible pixels
fails unless its exact mask, bounds and area were reviewed as intentional FX.
Alpha <32 is resampling fringe; it does not join two visibly detached limbs.
Small dust/ticks are allowed. Exceptions never exempt an entire clip or frame.
"""
import hashlib
import numpy as np
from scipy import ndimage

ALPHA_THRESHOLD=32
MAX_SMALL_PARTICLE=200

def parts(frame):
    labels,_=ndimage.label(np.asarray(frame.convert('RGBA').getchannel('A'))>=ALPHA_THRESHOLD,np.ones((3,3)))
    sizes=np.bincount(labels.ravel());sizes[0]=0
    if not sizes.any():return []
    body=int(sizes.argmax());result=[]
    for index,slices in enumerate(ndimage.find_objects(labels),1):
        if slices is None:continue
        mask=labels[slices]==index
        result.append({'body':index==body,'area':int(sizes[index]),
                       'box':[slices[1].start,slices[0].start,slices[1].stop,slices[0].stop],
                       'sha256':hashlib.sha256(np.packbits(mask).tobytes()).hexdigest()})
    return result

def signature(part):
    return (part['area'],tuple(part['box']),part['sha256'])

def large_islands(frame):
    return [p for p in parts(frame) if not p['body'] and p['area']>MAX_SMALL_PARTICLE]

def violations(frame,exceptions=()):
    approved={signature(p) for p in exceptions}
    return [p for p in large_islands(frame) if signature(p) not in approved]
