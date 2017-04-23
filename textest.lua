function range(a,b)
 t={}
 for i=a,b do
  add(t,i)
 end
 return t
end

function _init()
 srand(1)
 --build_plt(plt_addr)
 --setup_room(
 -- dark_biome,
 -- darker_biome,
 -- forest_biome)
 grd=grid(16,16)
 world=maze(grd)
 world.kruskal()
 world.tighten(32)
 world.color(64)
 genbiomes()
 gx,gy=8,8
 ux,uy=60,60
 local xs=range(1,16)
 local ys=range(1,16)
 g_obelisks={}
 g_buried={}
 g_keys={}
 g_chests={}
 g_features={}
 function add_feature(f)
  g_features[
   grd.offs(f.x, f.y)
  ]=f
 end
 function rnd_feature(f)
  local x=dice(1,16)
  local y=dice(1,16)
  local o=grd.offs(x,y)
  if g_features[o] == nil then
   f.x=x
   f.y=y
   g_features[o] = f
   return f
  end
  -- try again (tail call)
  return rnd_feature(f)
 end
 for i=1,8 do
  add_feature{
   x=pickpop(xs),
   y=pickpop(ys),
   type='obelisk'
  }
  add_feature{
   x=pickpop(xs),
   y=pickpop(ys),
   type='buried'
  }
 end
 for i=1,8 do
  rnd_feature{type='key'}
  rnd_feature{type='chest'}
  rnd_feature{type='sage'}
  rnd_feature{type='trader'}
  rnd_feature{type='gem'}
 end
 init_fast_shadow(sha_addr)
 initroom()
end

function screenoff()
 for i=0,15 do
  pal(i,0,1)
 end
end

function screenon()
 for i=0,15 do
  pal(i,i,1)
 end
end

function initroom()
 --screenoff()
 local bm=world.getcol(gx,gy)
 local b1,b2
 bm=biomes[bm]
 local vert=((gx+gy)%2)==0
 if vert then
  b1=world.getcol(gx,gy-1) or 0
  b2=world.getcol(gx,gy+1) or 0
 else
  b1=world.getcol(gx-1,gy) or 0
  b2=world.getcol(gx+1,gy) or 0
 end
 b1=biomes[b1]
 b2=biomes[b2]
 random_walls(world,gx,gy,bm.wallstyle)
 setup_room(
  bm,b1,b2)
 local feature=g_features[grd.offs(gx,gy)]
 if feature then
  if feature.type == 'key' then
   sprites={player,chestkey}
   chestkey.x=gix*8-4
   chestkey.y=giy*8-4
  elseif feature.type == 'chest' then
   sprites={player,chest}
   chest.x=gix*8-4
   chest.y=giy*8-4
  else
   sprites={player}
  end
 else
  sprites={player}
 end
end

function overlap(a1,a2,b1,b2)
 return min(a2,b2)-max(a1,b1)+1
end
function eject(a1,a2,b1,b2)
 local l=a2-b1+1
 local r=b2-a1+1
 if l<r then
  return a1-l,a2-l
 end
 return a1+r,a2+r
end
function ejectwall(wx,wy,ori)
 local hov=overlap(ux+4,ux+11,wx*8,wx*8+7)
 local vov=overlap(uy+4,uy+11,wy*8,wy*8+7)
 if (hov<=0) return
 if (vov<=0) return
 ori=ori or hov<=vov
 if ori==0 then
  ux=eject(ux+4,ux+11,wx*8,wx*8+7)-4
  return
 end
 if ori==1 then
  uy=eject(uy+4,uy+11,wy*8,wy*8+7)-4
 end
end

function _update60()
 local going=false
 function go(dx,dy)
   gx=mid(0,gx+dx,15)
   gy=mid(0,gy+dy,15)
   ux=mid(0,ux-200*dx,120)
   uy=mid(0,uy-200*dy,120)
   going=true
 end
 function blocked(x,y)
  if (mget(x,y)==2) return true
  for f in all(sprites) do
   if f.solid then
    if flr((f.x+4)/8)==x and
     flr((f.y+4)/8)==y then
     return true
    end
   end
  end
  return false
 end
 function wk(dx,dy)
  ux+=dx
  uy+=dy
  local x1=flr((ux+4)/8)
  local y1=flr((uy+4)/8)
  local x2,y2=x1+1,y1+1
  local ori=dy!=0 and 1 or 0
  
  if blocked(x1,y1) then
   ejectwall(x1,y1,ori)
  end
  if blocked(x1,y2) then
   ejectwall(x1,y2,ori)
  end
  if blocked(x2,y1) then
   ejectwall(x2,y1,ori)
  end
  if blocked(x2,y2) then
   ejectwall(x2,y2,ori)
  end
 end
 if (btn(0)) wk(-1,0)
 if (btn(1)) wk(1,0)
 if (btn(2)) wk(0,-1)
 if (btn(3)) wk(0,1)
 if (ux>120) go(1,0)
 if (ux<0) go(-1,0)
 if (uy>120) go(0,1)
 if (uy<0) go(0,-1)
 if going then
  initroom()
 end
 if btn(4) then
  gem1.spr=56+dice(0,4)
 end
 if btn(5) then
  gem1.palette=
   primary_palettes[
    dice(1,8)
   ]
 end
end

player={
 x=64,
 y=64,
 palette=26,
 spr=52
}

chestkey={
 x=32,
 y=32,
 palette=0,
 spr=36,
 solid=false
}

chest={
 x=32,
 y=32,
 palette=0,
 spr=37,
 solid=true
}

gem1={
 x=96,
 y=96,
 palette=13,
 spr=57
}

sprites={
 player
}

pal_red=23
pal_pink=26
pal_tan=24
pal_violet=25
pal_blue=9
pal_green=13
pal_yellow=15
pal_orange=17

primary_palettes={
 pal_red,
 pal_pink,
 pal_tan,
 pal_violet,
 pal_blue,
 pal_green,
 pal_yellow,
 pal_orange
}

function drawsprites()
 for s in all(sprites) do
  setpal(s.palette)
  palt()
  palt(0,false)
  palt(3,true)
  spr(s.spr,s.x,s.y-3)
 end
end

function drawspriteshadows()
 for s in all(sprites) do
  slow_shadow(53,s.x,s.y)
 end
end

function _draw()
 if (btn(4)) return
 player.x=ux
 player.y=uy
 sort(sprites,function(s) return s.y end)
 draw_bg()
 -- Fast shadow isn't good
 -- because x can be odd
 -- and might overlap edge
 -- of screen.
 drawspriteshadows()
 --slow_shadow(53,ux,uy)
 draw_fg()
 pal()
 palt()
 drawsprites()
 --spr(52,ux,uy-3)
 pal()
 palt()
 palt(0,false)
 rectfill(0,0,31,5,0)
 print(stat(1),0,0,7)
 screenon()
end
