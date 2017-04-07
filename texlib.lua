--cornercode
-- 0x1 = topleft
-- 0x2 = topright
-- 0x4 = botleft
-- 0x8 = botright
--combine, e.g.
-- 0x3 = top
-- 0xd = l-shape
-- 0xf = all

--dividecode
-- same as cornercode, but no
-- high bit. e.g.
-- 0x1 = topleft
-- 0x2 = topright
-- 0x3 = top/bottom
-- 0x4 = botleft
-- 0x5 = left/right
-- 0x6 = crisscross (bad)
-- 0x7 = botright

big_divs=64
thin_divs=80
wall_divs=96
box_masks=112
zig_masks=128
plt_addr=0x5000 -- to 0x50ff

tex_stone=4
tex_grass=6
tex_tangle=8
tex_rock=10
tex_dirt=12

function ccode(tl,tr,bl,br)
 -- corder code
 return
  (tl and 1 or 0) +
  (tr and 2 or 0) +
  (bl and 4 or 0) +
  (br and 8 or 0)  
end

function abcl(a,b,v)
 -- a/b classify
 if (v==a) return 1
 if (v==b) return 2
 return 0
end

function ccodemap4(a,b,mx,my)
 -- read map to calculate corner code
 local
  tlc,trc,blc,brc
 tlc=abcl(a,b,mget(mx,my))
 trc=abcl(a,b,mget(mx+1,my))
 blc=abcl(a,b,mget(mx,my+1))
 brc=abcl(a,b,mget(mx+1,my+1))
 return ccode(
  tlc==0,trc==0,blc==0,brc==0),
  max(max(max(tlc,trc),
          blc),
      brc)
end

function sprofs(s, y)
 -- calculate address of sprite #s row y
 y=y or 0
 return
  (s%16)*4 +
  (flr(s/16)*512) +
  y*64 
end

function gfxofs(x, y)
 -- calculate address of screen
 -- x,y. when x is odd, round
 -- down to the byte
 return
  0x6000 +
  flr(x/2) +
  y*64
end

function maskcpy(
  src1,src2,mask,dest,bytes)
 -- copy pixel bytes with a
 -- mask, which should have
 -- 0x0 nibbles for clear and
 -- 0x7 nibbles for opaque
 -- applies a palette
 -- transform to src1 only
 for i=1,bytes do
  s1=peek(
   bor(plt_addr,peek(src1)))
  m=peek(mask)
  s2=peek(src2)
  v=band(s1,m)+band(s2,bnot(m))
  poke(dest,v)
  src1+=1
  src2+=1
  dest+=1
  mask+=1
 end
end

function maskspr(
  spr1,spr2,mask,x,y)
 -- draw a sprite using a mask
 -- spr2 may be nil
 x=2*flr(x/2)
 go=gfxofs(x,y)
 so1=sprofs(spr1)
 if spr2==nil then
  so2 = go
 else
  so2 = sprofs(spr2)
 end
 mo = sprofs(mask)
 go = gfxofs(x,y)
 local dx,w,sy,ey=0,4,0,7
 if x<0 then
  dx=-x/2
  w+=x/2
 end
 if x>120 then
  w-=(x-120)/2
 end
 if y<0 then
  sy=-y
  so1+=64*sy
  so2+=64*sy
  mo+=64*sy
  go+=64*sy
 end
 if y>120 then
  ey=127-y
 end
 for h=sy,ey do
  maskcpy(
   so1+dx,so2+dx,
   mo+dx,go+dx,w)
  so1+=64
  so2+=64
  mo+=64
  go+=64
 end
end

function build_plt(addr)
 -- build lookup table for
 -- palette to use in maskspr
 local ca,cb
 for a=0,15 do
  ca=shl(
   band(15,peek(0x5f00+a)),4)
  for b=0,15 do
   cb=band(15,peek(0x5f00+b))
   poke(
    addr+bor(shl(a,4),b),
    bor(ca,cb))
  end
 end
end

wall=2
floor=1
tex_wall=tex_rock
tex_floor=tex_tangle

style1=52
style2=36

function _init()
 build_plt(plt_addr)
 setup_room(
  dark_biome,
  darker_biome,
  forest_biome)
end

function setpal(idx)
 for i=0,7 do
  pal(i,sget(idx,i+8))
 end
end

function prerender(
 tex_a, tex_b,
 pal_a, pal_b)
 setpal(pal_a)
 for i=0,15 do
  spr(tex_a,i*8,0)
 end
 setpal(pal_b)
 build_plt(plt_addr)
 for i=0,15 do
  maskspr(
   tex_b,nil,
   zig_masks+i,
   i*8,0)
 end
end

ice_biome={
 walt=tex_rock,
 flot=tex_dirt,
 bort=wall_divs,
 walp=8,
 flop=10,
 borp=9
}

dark_biome={
 walt=tex_dirt,
 flot=tex_dirt,
 bort=big_divs,
 walp=11,
 flop=0,
 borp=6
}

forest_biome={
 walt=tex_tangle,
 flot=tex_grass,
 bort=thin_divs,
 walp=4,
 flop=12,
 borp=13
}

darker_biome={
 walt=tex_rock,
 flot=tex_dirt,
 bort=thin_divs,
 walp=0,
 flop=1,
 borp=1
}

function setup_room(
  biome_main,
  biome_ex1,
  biome_ex2)
 palt()
 palt(0,false)
 prerender(
  biome_main.walt,
  biome_ex1.walt,
  biome_main.walp,
  biome_ex1.walp)
 memcpy(0x1800,0x6000,0x200)
 prerender(
  biome_main.walt,
  biome_ex2.walt,
  biome_main.walp,
  biome_ex2.walp)
 memcpy(0x1a00,0x6000,0x200)
 prerender(
  biome_main.flot,
  biome_ex1.flot,
  biome_main.flop,
  biome_ex1.flop)
 memcpy(0x1c00,0x6000,0x200)
 prerender(
  biome_main.flot,
  biome_ex2.flot,
  biome_main.flop,
  biome_ex2.flop)
 memcpy(0x1e00,0x6000,0x200)
 rectfill(0,0,127,7,0)
 setpal(biome_main.walp)
 spr(biome_main.walt+1,64,0)
 setpal(biome_main.flop)
 spr(biome_main.flot+1,72,0)
 setpal(biome_ex1.walp)
 spr(biome_ex1.walt+1,80,0)
 setpal(biome_ex1.flop)
 spr(biome_ex1.flot+1,88,0)
 setpal(biome_ex2.walp)
 spr(biome_ex2.walt+1,96,0)
 setpal(biome_ex2.flop)
 spr(biome_ex2.flot+1,104,0)
 setpal(biome_main.borp)
 for i=0,7 do
  spr(biome_main.bort+i,8*i,0)
 end
 memcpy(0x1600,0x6000,0x200)

 rectfill(0,0,127,7,0)
 --setpal(biome_main.borp)
 --for i=0,7 do
 -- spr(biome_main.bort+i,8*i,0)
 --end
 setpal(biome_ex1.borp)
 for i=0,7 do
  spr(biome_ex1.bort+i,8*i,0)
 end
 setpal(biome_ex2.borp)
 for i=0,7 do
  spr(biome_ex2.bort+i,64+8*i,0)
 end
 memcpy(0x1400,0x6000,0x200)
 memcpy(0x6000,0x1400,0xc00)
end

-- wavt: wall/variant/tex
-- flvt: floor/variant/tex
main_wavt=0xb8
main_flvt=0xb9
ex1_wavt=0xba
ex1_flvt=0xbb
ex2_wavt=0xbc
ex2_flvt=0xbd
main_bort=0xb0
ex1_bort=0xa0
ex2_bort=0xa8
wall_ex1=0xc0
wall_ex2=0xd0
floor_ex1=0xe0
floor_ex2=0xf0

variants={
 [wall_ex1]=main_wavt,
 [wall_ex2]=main_wavt,
 [floor_ex1]=main_flvt,
 [floor_ex2]=main_flvt,
 [wall_ex1+0xf]=ex1_wavt,
 [wall_ex2+0xf]=ex2_wavt,
 [floor_ex1+0xf]=ex1_flvt,
 [floor_ex2+0xf]=ex2_flvt
}

function vspr(idx, x, y)
 local v=variants[idx] or idx
 if (flr(shr(x,3))+flr(shr(y,3)))%2==0 then
 --if rnd()>0.5 then
  idx=v
 end
 spr(idx,x,y)
end

room_seed=25

function draw_map()
 pal()
 palt()
 palt(0,false)
 srand(room_seed)
 local v,q,ex
 for x=0,16 do
  for y=0,16 do
   v=mget(x,y)
   if v==wall then
    q,ex=ccodemap4(2,3,x+18,y)
    q=bxor(0xf,q)
    if ex==0 then
     -- solid main wall
     vspr(wall_ex1,x*8-4,y*8-4)
    else
     vspr(wall_ex1+q+16*(ex-1),x*8-4,y*8-4)
    end
   else
    q,ex=ccodemap4(2,3,x+18,y)
    q=bxor(0xf,q)
    if ex==0 then
     -- solid main floor
     vspr(floor_ex1,x*8-4,y*8-4)
    else
     vspr(floor_ex1+q+16*(ex-1),x*8-4,y*8-4)
    end
   end
  end
 end
 --borders
 palt(0,true)
 for x=0,15 do
  for y=0,15 do
   q=ccodemap4(2,3,x,y)
   if band(q,8)==8 then
    q=bxor(q,0xf)
   end
   ex=mget(x+19,y+1)
   --ex=max(max(max(
   -- mget(x+18,y),
   -- mget(x+19,y),
   -- mget(x+18,y+1),
   -- mget(x+19,y+1))))
   if (ex==1) ex=main_bort
   if (ex==2) ex=ex1_bort
   if (ex==3) ex=ex2_bort
   spr(ex+q,
    x*8,y*8) 
   
  end
 end
end

function _draw()
 draw_map()
 if (true) return
 pal()
 palt()
 palt(0, false)
 build_plt(plt_addr)
 rectfill(0,0,127,127,5)
 for x=0,16 do
  for y=0,16 do
   v=mget(x,y)
   if v==wall then
    
    --sprite=
    -- (v==36) and
    -- 36 or 34
    --if x<3 and sprite==34 then
    -- sprite=52
    --end
    if true then
     q=ccodemap4(36,52,x+18,y)
     spr(wall_ex1+q,x*8-4,y*8-4)
     --maskspr(
     --   tex_wall+(x+y)%2,
     --   tex_wall+(x+y)%2,
     --   zig_masks+q,
     --   x*8-4,y*8-4)
     --spr(sprite+(x+y)%2,x*8-4,y*8-4)
    end
   else
    if v==floor then
     if true then
      q=ccodemap4(36,52,x+18,y)
      spr(floor_ex1+q,x*8-4,y*8-4)
      --maskspr(
      -- 36+(x+y)%2,
      -- 48+(x+y)%2,
      -- zig_masks+q,
      -- x*8-4,y*8-4)
     end
    else
     --q=ccodemap(36,52,x,y)
     if x<3 then
      sprite=52
     else
      sprite=34
     end
     --sprite=nil
     maskspr(
      36,sprite,box_masks+q,
      x*8-4,y*8-4)
    end 
   end
  end
 end
 palt()
 --borders
 for x=0,15 do
  for y=0,15 do
   v=mget(x,y)
   q=ccodemap4(36,52,x,y)
   if band(q,8)==8 then
    q=bxor(q,0xf)
   end
   --print(q)
   spr(big_divs+q,
    x*8,y*8)
  end
 end
 --maskspr(6,22,5,16,16)
 --for
 --q=ccodemap(36,52,4,2)
 --maskspr(36,52,box_masks+q,4*8,2*8)
 palt()
 palt(0,false)
 prerender(
  tex_tangle,tex_rock,
  6,8)
 memcpy(0x1200,0x6000,0x200)
 prerender(
  tex_dirt,tex_grass,
  7,5)
 memcpy(0x1400,0x6000,0x200)
end
