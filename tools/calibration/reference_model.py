from pathlib import Path
import re
import numpy as np
from PIL import Image
PACKAGE=Path(__file__).resolve().parents[2]
SRC=PACKAGE/'project/cam2dvi/src'
MASK=int(re.search(r"SIGN_MASK=256.h([0-9a-f]+)",(SRC/'sign_templates.vh').read_text())[1],16)
def quantize(im):
    a = np.asarray(im.convert('RGB')).astype(np.uint16)
    packed = ((a[:,:,0]>>3)<<11)|((a[:,:,1]>>2)<<5)|(a[:,:,2]>>3)
    return packed, np.stack(((packed>>11)<<3, ((packed>>5)&63)<<2, (packed&31)<<3), axis=2).astype(np.int32)

def enhanced(im):
    packed,_=quantize(im)
    r=(packed>>11).astype(np.int32);g=((packed>>5)&63).astype(np.int32);b=(packed&31).astype(np.int32)
    a=np.stack(((r<<3)|(r>>2),(g<<2)|(g>>4),(b<<3)|(b>>2)),axis=2)
    a=np.repeat(np.repeat(a,5,axis=0),4,axis=1)
    pixel_min=a.min(axis=2); pixel_max=a.max(axis=2)
    horizontal=pixel_min.copy()
    for dx in range(1,15):horizontal[:,dx:]=np.minimum(horizontal[:,dx:],pixel_min[:,:-dx])
    dark=horizontal.copy()
    for dy in range(1,15):dark[dy:]=np.minimum(dark[dy:],horizontal[:-dy])
    romtext=(SRC/'gain_extra_rom.vh').read_text()
    rom=np.array([int(x) for x in re.findall(r"extra_rom=14'd(\d+)",romtext)],dtype=np.int32)
    delta=(a[:,:,0]+2*a[:,:,1]+a[:,:,2])//4-240
    correction=(delta*rom[dark])>>12
    floor=pixel_min-(pixel_min>>2)-(pixel_min>>3)
    correction=np.maximum(-floor,np.minimum(255-pixel_max,correction))
    out=np.clip(a+correction[:,:,None],0,255).astype(np.uint8)[::5,::4]
    return Image.fromarray(out)

def components(a):
    r,g,b = a[:,:,0],a[:,:,1],a[:,:,2]
    warm = ((r>80)&(g>65)&(5*r>=4*g)&(3*g>=r)&(5*b<3*g)&(5*b<3*r)) | ((r>170)&(g>150)&(r>g+15)&(b<g+20)&(b+20<r)&(4*g>3*r))
    tiles={}
    for y,x in zip(*np.nonzero(warm)):
        tiles.setdefault((int(y)//8,int(x)//8),[]).append((int(x),int(y)))
    found=[]
    while tiles:
        seed=next(iter(tiles)); queue=[seed]; pts=[]
        for cy,cx in queue:
            pts.extend(tiles.pop((cy,cx)))
            for dy in [-1,0,1]:
                for dx in [-1,0,1]:
                    q=(cy+dy,cx+dx)
                    if q in tiles and q not in queue:queue.append(q)
        xs,ys=zip(*pts); x,y=min(xs),min(ys); w,h=max(xs)-x+1,max(ys)-y+1; n=len(pts)
        if n>=25 and 8<=w<=240 and 8<=h<=140 and 2*w>=h and w<=2*h and 12*n>w*h and 4*n<3*w*h:
            found.append((n,(x,y,w,h)))
    return [v for _,v in sorted(found,reverse=True)[:4]]

def patches(im):
    _,a=quantize(im); result=[]
    for x,y,w,h in components(np.asarray(im).astype(np.int32)):
        vals=[]
        for i in range(256):
            px=x+(w*(2*(i%16)+1)//32);py=y+(h*(2*(i//16)+1)//32)
            r,g,b=a[py,px]; vals.append(int(r+2*g+b)//4)
        for rot in range(4):
            def idx(i):
                yy,xx=divmod(i,16)
                return [i,(15-xx)*16+yy,255-i,xx*16+15-yy][rot]
            active=[vals[i] for i in range(256) if MASK>>idx(i)&1]
            lo,hi=min(active),max(active); th=(lo+hi)//2
            bits=sum((int(vals[i]<=th)<<idx(i)) for i in range(256))
            result.append((bits,(x,y,w,h),rot,hi-lo))
    return result

def classify(im, ts, cs):
    best=None
    for bits,box,rot,contrast in patches(im):
        scores=[min(((bits^t)&MASK).bit_count() for t,c in zip(ts,cs) if c==k) for k in range(1,6)]
        ids=sorted(range(5), key=lambda j:scores[j]); c=ids[0]+1; d=scores[ids[0]]
        dark=(bits&MASK).bit_count(); windows=[(25,67),(9,31),(24,46),(21,36),(14,56 if len(ts)!=53 else 31)]
        limit=19
        accept=c!=1 and d<=limit and scores[ids[1]]>=d+3 and windows[c-1][0]<=dark<=windows[c-1][1] and contrast>=12
        rec={'class':c if accept else 0,'best_class':c,'scores':scores,'dark':dark,'distance':d,'box':box,'rotation':rot}
        if best is None or (accept and (best['class']==0 or d<best['distance'])) or (not accept and best['class']==0 and d<best['distance']):best=rec
    return best

