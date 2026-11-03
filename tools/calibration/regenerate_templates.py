from pathlib import Path
import json,re
from PIL import Image,ImageOps,ImageEnhance,ImageFilter
from reference_model import MASK,enhanced,patches,SRC
HERE=Path(__file__).parent
seed=json.loads((HERE/'templates_seed_FFD8.json').read_text())
pairs=[(int(x['bits'],16),x['class']) for x in seed]
def fixture(card,width,mirror=False,angle=0,gain=1,blur=0):
 im=ImageOps.mirror(card) if mirror else card.copy()
 if angle:im=im.rotate(angle,Image.Resampling.BICUBIC,fillcolor=(205,205,205))
 im=im.resize((width,round(width*card.height/card.width)),Image.Resampling.LANCZOS)
 if gain!=1:im=ImageEnhance.Brightness(im).enhance(gain)
 if blur:im=im.filter(ImageFilter.GaussianBlur(blur))
 canvas=Image.new('RGB',(320,144),(100,110,120));canvas.paste(im,(150-width//2,20));return canvas
train=[dict(width=w,mirror=m) for w in [96,112,128] for m in [False,True]]+[dict(width=112,angle=a,mirror=m) for a in [-3,3] for m in [False,True]]+[dict(width=112,gain=.85),dict(width=120,blur=.4)]
for name,cls,lo,hi in [('children',4,21,36),('pedestrian',3,24,46)]:
 card=Image.open(HERE/'cards'/f'{name}.png').convert('RGB')
 for args in train:
  candidates=patches(enhanced(fixture(card,**args)))
  usable=[p for p in candidates if lo<=(p[0]&MASK).bit_count()<=hi]
  if usable:
   bits=usable[0][0]
   if (bits&MASK,cls) not in [(b&MASK,c) for b,c in pairs]:pairs.append((bits,cls))
assert len(pairs)<=128
s=f"// Regenerated data; review before replacing the verified project table.\nlocalparam [255:0] SIGN_MASK=256'h{MASK:064x};\nlocalparam integer TEMPLATE_COUNT={len(pairs)};\n"
s+='function [255:0] sign_template;input [6:0] id;begin case(id)\n'
s+='\n'.join(f"7'd{i}:sign_template=256'h{b:064x};" for i,(b,c) in enumerate(pairs))+'\ndefault:sign_template=0;endcase end endfunction\n'
s+='function [2:0] sign_class;input [6:0] id;begin case(id)\n'
s+='\n'.join(f"7'd{i}:sign_class=3'd{c};" for i,(b,c) in enumerate(pairs))+'\ndefault:sign_class=0;endcase end endfunction\n'
(HERE/'generated_templates.vh').write_text(s)
original=(SRC/'sign_templates.vh').read_text()
ob=[int(v,16) for v in re.findall(r'sign_template=256.h([0-9a-f]+)',original)]
oc=[int(v) for v in re.findall(r"sign_class=3'd(\d)",original)]
assert pairs==list(zip(ob,oc)), 'Generated data differs from verified 74C3; review and rebuild before using.'
print(f'PASS: {len(pairs)} regenerated templates match verified 74C3 data. Project source unchanged.')
