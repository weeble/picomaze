
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
 screenoff()
 random_walls(world,gx,gy)
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
 setup_room(
  bm,b1,b2)
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
 function wk(dx,dy)
  ux+=dx
  uy+=dy
  local x1=flr((ux+4)/8)
  local y1=flr((uy+4)/8)
  local x2,y2=x1+1,y1+1
  local ori=dy!=0 and 1 or 0
  
  if mget(x1,y1)==2 then
   ejectwall(x1,y1,ori)
  end
  if mget(x1,y2)==2 then
   ejectwall(x1,y2,ori)
  end
  if mget(x2,y1)==2 then
   ejectwall(x2,y1,ori)
  end
  if mget(x2,y2)==2 then
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
end

function _draw()
 draw_map()
 slow_shadow(53,ux,uy)
 pal()
 spr(52,ux,uy-3)
 palt(0,false)
 pal()
 palt()
 palt(0,false)
 --slow_shadow(73,72,72)
 screenon()
 print(stat(1),0,0,7)
end
