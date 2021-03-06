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
sha_addr=0x5100 -- to 0x51ff
sha2_addr=0x5200 -- to 0x520f

tex_stone=4
tex_grass=6
tex_tangle=8
tex_rock=10
tex_dirt=12

all_tex={4,6,8,10,12,14,20,22}
function rnd_tex()
 return all_tex[rn(#all_tex)+1]
end

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

function nomaskcpy(
  src1,src2,mask,dest,bytes)
 for i=1,bytes do
  s1=peek(
   bor(plt_addr,peek(src1)))
  poke(dest,s1)
  src1+=1
  dest+=1
 end
end

function memspr(spr,go)
 maskspr2(spr,nil,nil,go)
end

function maskspr2(
  spr1,spr2,mask,go)
 so1=sprofs(spr1)
 local mcpy=maskcpy
 local mo=0
 if mask==nil then
  mcpy = nomaskcpy
 else
  mo=mask
 end
 if spr2==nil then
  so2 = go
 else
  so2 = sprofs(spr2)
 end
 --sprofs(mask)
 for h=0,7 do
  mcpy(
   so1,so2,
   mo,go,4)
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

function pal_switch(n)
 setpal(n)
 build_plt(plt_addr)
end

wall=2
floor=1
tex_wall=tex_rock
tex_floor=tex_tangle

function setpal(idx)
 for i=0,3 do
  pal(i,sget(idx,i+8))
 end
end

function getunusedcol(pal1,pal2,pal3)
 local c=15
 repeat
  local ok=true
  for i=0,3 do
   for p in all({pal1,pal2,pal3}) do
    if sget(p,i+8)==c then
     c-=1
     ok=false
    end
   end
  end
 until ok
 return c
end


function prerender(
  tex_a, tex_b,
  pal_a, pal_b,
  ptr_dest)
 pal_switch(pal_a)
 for i=0,15 do
  maskspr2(tex_a,nil,nil,
   ptr_dest+i*4)
 end
 pal_switch(pal_b)
 for i=0,15 do
  maskspr2(
   tex_b,nil,
   sprofs(zig_masks+i),
   ptr_dest+i*4)
 end
end

function rn(n)
 return flr(rnd(n))
end

function mkbiome(b)
 b.w={t=b.walt,p=b.walp}
 b.f={t=b.flot,p=b.flop}
 b.b={t=b.bort,p=b.borp}
 return b
end

function rndbiome()
 return mkbiome {
  walt=rnd_tex(),
  flot=rnd_tex(),
  bort=big_divs + 16*rn(3),
  walp=rn(24),
  flop=rn(24),
  borp=rn(24),
  wallstyle=rn(3)
 }
end

biomes={}

function genbiomes(seed)
 if (seed!=nil) srand(seed)
 for i=0,63 do
  biomes[i]=rndbiome()
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
 --borp=6
 borp=rn(24)
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
 borp=14
}

main_bordert=15
ex1_bordert=15
ex2_bordert=15

function counter(c,d)
 return function()
  local r=c
  c+=d
  return r
 end
end

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
  biome_ex1.walp,
  0x1800)
 prerender(
  biome_main.walt,
  biome_ex2.walt,
  biome_main.walp,
  biome_ex2.walp,
  0x1a00)
 prerender(
  biome_main.flot,
  biome_ex1.flot,
  biome_main.flop,
  biome_ex1.flop,
  0x1c00)
 prerender(
  biome_main.flot,
  biome_ex2.flot,
  biome_main.flop,
  biome_ex2.flop,
  0x1e00)
 
 --rectfill(0,0,127,7,0)
 memset(0x1600,0,0x200)
 ptr_spr=counter(sprofs(main_wavt),4)
 function do_variant(pt)
  pal_switch(pt.p)
  memspr(pt.t+1,ptr_spr())
 end
 do_variant(biome_main.w)
 do_variant(biome_main.f)
 do_variant(biome_ex1.w)
 do_variant(biome_ex1.f)
 do_variant(biome_ex2.w)
 do_variant(biome_ex2.f)

 pal_switch(biome_main.borp)
 main_bordert=
  getunusedcol(
   biome_main.borp,
   biome_ex1.borp,
   biome_ex2.borp)
 pal(3,main_bordert)
 build_plt(plt_addr)
 ptr_spr=counter(sprofs(main_bort),4)
 for i=0,7 do
  memspr(biome_main.bort+i,ptr_spr())
 end

 ptr_spr=counter(sprofs(ex1_bort),4)
 memset(0x1400,0,0x200)
 setpal(biome_ex1.borp)
 pal(3,main_bordert)
 build_plt(plt_addr)
 for i=0,7 do
  memspr(biome_ex1.bort+i,ptr_spr())
 end
 setpal(biome_ex2.borp)
 pal(3,main_bordert)
 build_plt(plt_addr)
 for i=0,7 do
  memspr(biome_ex2.bort+i,ptr_spr())
 end

 --Uncomment to dump sprites
 --back to screen
 --memcpy(0x6000,0x1400,0xc00)

 bake_map()
 clear_borders()
 bake_borders(1, main_bort)
 bake_borders(2, ex1_bort)
 bake_borders(3, ex2_bort)
end

-- We use sprites 0xb8..0xff
-- for pre-baking the map tiles
-- for room.

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
  idx=v
 end
 spr(idx,x,y)
end

function pickv(idx, x, y)
 if (x+y)%2==0 then
  return variants[idx] or idx
 end
 return idx
end

function clear_borders()
 mrect(54,0,54+16,16,0)
end

function bake_borders(code, texbase)
 local q
 for x=0,15 do
  for y=0,15 do
   q=ccodemap4(2,3,x,y)
   if band(q,8)==8 then
    q=bxor(q,0xf)
   end
   ex=mget(x+19,y+1)
   if ex==code and q>0 then
    mset(54+x,y,texbase+q)
   end
  end
 end
end


shadow_tiles={
 [4]=4,
 [6]=4,
 [8]=7,
 [9]=7,
 [12]=3,
 [13]=2,
 [14]=1
}

function draw_shadows()
 local q
 pal()
 palt(0,false)
 for x=0,15 do
  for y=0,15 do
   q=ccodemap4(2,3,x,y)
   if q>0 then
    q=peek(sha2_addr+q)
    if q>0 then
     fast_shadow(72+q,x*8,y*8)
    end
   end
  end
 end
end

function slow_shadow(sidx,x,y)
 -- Works anywhere
 local sx=8*(sidx%16)
 local sy=8*flr(sidx/16)
 for yy=0,7 do
  for xx=0,7 do
   local c=sget(xx+sx,yy+sy)
   local d=pget(x+xx,y+yy)
   c=peek(sha_addr+bor(d,shl(c,4)))
   pset(x+xx,y+yy,c)
  end
 end
end

function fast_shadow(sidx,x,y)
 -- Does not range check - not
 -- safe to use if it might
 -- fall outside the screen.
 -- Only for even x.
 local saddr=sprofs(sidx)
 local paddr=gfxofs(x,y)
 -- The most outrageous hack of
 -- all here is that we start
 -- yy from 3 since none of our
 -- shadow textures have content
 -- in the top three rows.
 for yy=3,7 do
  local ofs=yy*64
  for xx=0,3 do
   local cs=peek(saddr+ofs)
   local ds=peek(paddr+ofs)
   local clo=shl(band(cs,0x3),4)
   local dlo=band(ds,0xf)
   dlo=peek(bor(clo,dlo)+sha_addr)
   local chi=band(cs,0xf0)
   local dhi=shr(band(ds,0xf0),4)
   dhi=peek(bor(chi,dhi)+sha_addr)
   cs=bor(dlo,shl(dhi,4))
   poke(paddr+ofs,cs)
   ofs+=1
  end
 end

end

function init_fast_shadow(addr)
 -- build lookup table for
 -- palette to use fast_shadow
 for c=0,3 do
  for d=0,15 do
   local result=sget(c,d+16)
   poke(sha_addr+d+c*16,result)
  end
 end
 memset(sha2_addr,16,0)
 for idx,v in pairs(shadow_tiles) do
  poke(sha2_addr+idx,v)
 end
end

function dice(lo,hi)
 if (lo>=hi) return lo
 return rn(hi-lo+1)+lo
end

function mrect(x1,y1,x2,y2,v)
 for y=y1,y2 do
  for x=x1,x2 do
   mset(x,y,v)
  end
 end
end

seed_xlinks=77
seed_ylinks=78
seed_walls=79


clockwise={
 {0,-1},
 {1,-1},
 {1,0},
 {1,1},
 {0,1},
 {-1,1},
 {-1,0},
 {-1,-1}
}
cardinal={
 {0,-1},
 {1,0},
 {0,1},
 {-1,0}
}

function cavernify(x,y,p)
 -- toggle map cell iff it
 -- won't affect topology
 -- assumes all map values
 -- are 1 or 2
 function getneib(dir)
  return mget(
   x+dir[1],
   y+dir[2])
 end
 local acc=0
 local prev=getneib(
  clockwise[
   #clockwise])
 for dir in all(clockwise) do
  local v=getneib(dir)
  if v!=prev then
   acc+=1
  end
  prev=v
 end
 if (acc!=2) return
 acc=0
 local cell=mget(x,y)
 for dir in all(cardinal) do
  if getneib(dir)!=cell then
   acc+=1
  end
 end
 if (acc==0) return
 if (acc==1 and dice(1,p)>1) return
 --printh('x'..x..' y'..y..' := '..(3-cell))
 mset(x,y,3-cell)
end

function pickitempos()
 local x,y
 while true do
  x=dice(2,14)
  y=dice(2,14)
  if mget(x,y)==1 then
   x=mid(3,x,13)
   y=mid(3,y,13)
   mrect(x-1,y-1,x+1,y+1,1)
   return {x,y}
  end
 end
end

ctrl=800

function random_walls(maze,gx,gy,walls)

 local topx=flr(prng(9,seed_xlinks,gx,gy))+4
 local topw=1
 local botx=flr(prng(9,seed_xlinks,gx,gy+1))+4
 local botw=1
 local lefty=flr(prng(9,seed_ylinks,gx,gy))+4
 local lefth=1
 local righty=flr(prng(9,seed_ylinks,gx+1,gy))+4
 local righth=1
 local minx=min(topx-topw,botx-botw)
 local maxx=max(topx+topw,botx+botw)
 local miny=min(lefty-lefth,righty-righth)
 local maxy=max(lefty+lefth,righty+righth)
 minx=dice(2,minx)
 maxx=dice(maxx,14)
 miny=dice(2,miny)
 maxy=dice(maxy,14)
 local vert=((gx+gy)%2)==0

 mrect(0,0,16,16,2)
 mrect(18,0,18+17,17,1)

 mrect(minx,miny,maxx,maxy,1)
 prng(-1,seed_walls,gx,gy)
 --for i=0,7 do
 -- local x=flr(rnd(maxx-minx+1))+minx
 -- local y=flr(rnd(maxy-miny+1))+miny
 -- mset(x,y,2)
 --end

 if maze.has(gx,gy-1,1) then
  mrect(topx-topw,0,topx+topw,miny,1)
  if vert then
   mrect(18+topx-topw-1,0,18+topx+topw+2,3,2)
   mrect(18+topx-topw,4,18+topx+topw+1,4,2)
  end
 end
 if maze.has(gx,gy,1) then
  mrect(botx-botw,maxy,botx+botw,16,1)
  if vert then
   mrect(18+botx-botw-1,14,18+botx+botw+2,17,3)
   mrect(18+botx-botw,13,18+botx+botw+1,13,3)
  end
 end
 if maze.has(gx-1,gy,0) then
  mrect(0,lefty-lefth,minx,lefty+lefth,1)
  if not vert then
   mrect(18,lefty-lefth-1,18+3,lefty+lefth+2,2)
   mrect(18+4,lefty-lefth,18+4,lefty+lefth+1,2)
  end
 end
 if maze.has(gx,gy,0) then
  mrect(maxx,righty-righth,16,righty+righth,1)
  if not vert then
   mrect(18+14,righty-righth-1,18+17,righty+righth+2,3)
   mrect(18+13,righty-righth,18+13,righty+righth+1,3)
  end
 end

 if walls>0 then
  for i=0,((walls==2) and 800 or 100) do
   cavernify(dice(2,14),dice(2,14),(walls==2) and 32 or 1)
  end
 end
 local itempos=pickitempos()
 gix=itempos[1]
 giy=itempos[2]
end

function bake_map()
 local v,q,ex
 for x=0,16 do
  for y=0,16 do
   v=mget(x,y)
   if v==wall then
    q,ex=ccodemap4(2,3,x+18,y)
    q=bxor(0xf,q)
    if ex==0 then
     -- solid main wall
     mset(x+36,y,pickv(wall_ex1,x,y))
    else
     mset(x+36,y,pickv(wall_ex1+q+16*(ex-1),x,y))
    end
   else
    q,ex=ccodemap4(2,3,x+18,y)
    q=bxor(0xf,q)
    if ex==0 then
     -- solid main floor
     mset(x+36,y,pickv(floor_ex1,x,y))
    else
     mset(x+36,y,pickv(floor_ex1+q+16*(ex-1),x,y))
    end
   end
  end
 end
end

function draw_bg()
 pal()
 palt()
 palt(0,false)
 map(36,0,-4,-4,17,17)
 draw_shadows()
end

function draw_fg()
 pal()
 palt()
 palt(0,false)
 palt(main_bordert,true)
 map(54,0,0,0,16,16)
end
