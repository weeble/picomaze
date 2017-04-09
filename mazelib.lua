function pickpop(a)
 -- remove a random item from
 -- the array and return it
 -- does not preserve order
 -- o(1)
 local i=flr(rnd(#a))+1
 local ret=a[i]
 a[i]=a[#a]
 a[#a]=nil
 return ret
end

function logbits(x)
 local v=0
 x-=1
 while x>0 do
  x=band(0xffff,shr(x,1))
  v+=1
 end
 return v
end

function getbits(x,shift,bits)
 local bitmask=shl(1,bits)-1
 return band(
  bitmask,shr(x,shift))
end

function grid(w,h)
 local xbits=logbits(w)
 local ybits=logbits(h)
 local g={["w"]=w,["h"]=h}
 g.offs = function(x,y)
  return x+y*w
 end
 g.xy = function(offs)
  return offs%w,flr(offs/w)
 end
 g.dcdl = function(l)
  -- decode link
  return getbits(l,0,xbits),
   getbits(l,xbits,ybits),
   getbits(l,xbits+ybits,1)
 end
 g.spll = function(l)
  -- split link
  x,y,ori = g.dcdl(l)
  return x,y,x+1-ori,y+ori,ori
 end
 g.encl = function(
  -- encode link
   x,y,ori)
  return bor(
   x,bor(
   shl(y,xbits),
   shl(ori,xbits+ybits)
  ))
 end
 g.alllinks = function()
  t={}
  for y=0,h-2 do
   for x=0,w-1 do
    add(t,g.encl(x,y,1))
   end
  end
  for y=0,h-1 do
   for x=0,w-2 do
    add(t,g.encl(x,y,0))
   end
  end
  return t
 end
 g.prl = function(l)
  --print link
  x,y,ori = g.dcdl(l)
  print(x..","..y.."/"..ori)
 end
 return g
end

function maze(g)
 local m={}
 local cells={}
 local colors={}
 for i=0,g.w*g.h-1 do
  cells[i]=0
 end
 m.haslink = function(l)
  local x,y,ori=g.dcdl(l)
  local v=cells[x+y*g.w]
  return band(v,ori+1)!=0
 end
 m.alllinks = function(state)
  if (state==nil) state=true
  local ret={}
  for l in all(g.alllinks()) do
   if m.haslink(l)==state then
    add(ret,l)
   end
  end
  return ret
 end
 m.kruskal = function()
  local k={}
  function super(i)
   local s=k[i]
   if (s==nil) then
    k[i]=i
    return i
   end
   if (s==i) return s
   k[i]=super(s)
   return k[i]
  end
  function superxy(x,y)
   return g.xy(
    super(g.offs(x,y)))
  end
  function kjoin(l)
   local x1,y1,x2,y2,ori=
    g.spll(l)
   local a=g.offs(x1,y1)
   local b=g.offs(x2,y2)
   local aa=super(a)
   local bb=super(b)
   if (aa==bb) return
   --merge discrete sets
   k[max(aa,bb)]=min(aa,bb)
   --form link
   cells[a]=bor(cells[a],ori+1)
  end
  local links=g.alllinks()
  while #links>0 do
   kjoin(pickpop(links))
  end
 end
 m.tighten=function(n)
  local links=m.alllinks(false)
  for i=1,n do
    local l=pickpop(links)
    local x,y,ori=g.dcdl(l)
    local a=x+g.w*y
    cells[a]=bor(cells[a],ori+1)
  end
 end
 m.color=function(n)
  local allcells={}
  for i=0,g.w*g.h-1 do
   allcells[i+1]=i
  end
  -- seeds
  for i=0,n-1 do
   while true do
    local idx=flr(rnd(#cells))
    if colors[idx]==nil then
     colors[idx]=i
     break
    end
   end
  end
  while #allcells>0 do
   local c=pickpop(allcells)
   if colors[c]==nil then
    local ns={}
    function nadd(nei,ori,lc)
     if band(cells[lc],ori+1)!=0 then
      add(ns,colors[nei])
     end
    end
    local x,y=g.xy(c)
    if (x>0) nadd(c-1,0,c-1)
    if (y>0) nadd(c-g.w,1,c-g.w)
    if (x<g.w-1) nadd(c+1,0,c)
    if (y<g.h-1) nadd(c+g.w,1,c)
    if #ns==0 then
     add(allcells,c)
    else
     colors[c]=ns[flr(rnd(#ns))+1]
    end
   end
  end
 end
 m.draw=function()
  for i=0,g.w*g.h-1 do
   local c=cells[i]
   local x,y=g.xy(i)
   x*=8 y*=8
   rectfill(x+2,y+2,x+5,y+5,colors[i]%8+8)
   rectfill(x+3,y+3,x+4,y+4,flr(colors[i]/8)+8)
   if c%2!=0 then
    rectfill(x+6,y+3,x+9,y+4,7)
   end
   if band(c,2)!=0 then
    rectfill(x+3,y+6,x+4,y+9,7)
   end
  end
 end
 return m
end
