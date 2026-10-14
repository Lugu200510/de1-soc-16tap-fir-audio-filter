#!/usr/bin/env python3
"""Create a conceptual FIR sweep GIF from supplied tap coefficients."""
from pathlib import Path
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont
root=Path(__file__).resolve().parents[1]
assets=root/'assets';assets.mkdir(exist_ok=True)
W,H=1140,350
coeff=np.array([30,136,457,1119,2116,3278,4317,4932,4932,4317,3278,2116,1119,457,136,30],dtype=float)/32768
fs=40000
freq=np.linspace(0,20000,400)
resp=np.abs(np.array([sum(c*np.exp(-2j*np.pi*f/fs*k) for k,c in enumerate(coeff)) for f in freq]))
fnt='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
mono='/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'
title=ImageFont.truetype(fnt,30)
small=ImageFont.truetype(mono,15)
label=ImageFont.truetype(mono,18)
frames=[]
for phase in range(48):
    im=Image.new('RGB',(W,H),'#071421');d=ImageDraw.Draw(im)
    for x in range(0,W,40):d.line((x,0,x,H),fill='#102638')
    for y in range(0,H,35):d.line((0,y,W,y),fill='#102638')
    d.text((35,19),'16-TAP FIR  /  SEQUENTIAL MAC',font=title,fill='#EBFCFF')
    d.text((37,66),'Q0.15  ·  16-bit  ·  Cyclone V',font=small,fill='#62D9E8')
    # moving tap MAC selection (separate from previous FIFO animation)
    bx,by=35,105
    d.text((bx,by-22),'TAP SCAN  x[n-k] × h[k]',font=small,fill='#91AFC3')
    for k in range(16):
        x=bx+k*66
        selected=(phase//3)%16==k
        d.rounded_rectangle((x,by,x+53,by+48),radius=7,fill=('#007A93' if selected else '#142B3D'),outline=('#5CE9F7' if selected else '#28586F'),width=2)
        d.text((x+10,by+12),f'{k:02d}',font=label,fill=('#FFFFFF' if selected else '#9AC3D5'))
    d.text((37,177),'LOW-PASS RESPONSE  |H(f)|  (calculated from stored coefficients)',font=small,fill='#91AFC3')
    xx,yy,ww,hh=38,210,1053,113
    d.line((xx,yy,xx,yy+hh),fill='#436070',width=2)
    d.line((xx,yy+hh,xx+ww,yy+hh),fill='#436070',width=2)
    points=[]
    for i,(f,r) in enumerate(zip(freq,resp)):
        px=xx+ww*float(f)/20000
        py=yy+hh-hh*min(1.1,float(r))/1.1
        points.append((px,py))
    d.line(points,fill='#48D9F3',width=4,joint='curve')
    f0=phase/47*20000
    px=xx+ww*f0/20000
    idx=int(round(f0/20000*(len(freq)-1)))
    py=yy+hh-hh*min(1.1,resp[idx])/1.1
    d.line((px,yy-4,px,yy+hh),fill='#F8CB70',width=2)
    d.ellipse((px-5,py-5,px+5,py+5),fill='#F8CB70')
    d.text((xx+4,yy+hh+5),'0 Hz',font=small,fill='#7B9DAA')
    d.text((xx+ww-96,yy+hh+5),'20 kHz',font=small,fill='#7B9DAA')
    d.text((xx+ww-290,179),f'sweep {f0/1000:5.1f} kHz',font=small,fill='#F8CB70')
    frames.append(im)
frames[0].save(assets/'fir-sweep.gif',save_all=True,append_images=frames[1:],duration=100,loop=0,optimize=True)
frames[13].save(assets/'fir-sweep-preview.png')
print('saved',assets/'fir-sweep.gif', (assets/'fir-sweep.gif').stat().st_size)
