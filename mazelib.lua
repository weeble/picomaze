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
 g.nbrl = function(x,y)
  -- neighbour links
  n={}
  if (x>0) add(n,g.encl(x-1,y,0))
  if (x<w-1) add(n,g.encl(x,y,0))
  if (y>0) add(n,g.encl(x,y-1,1))
  if (y<h-1) add(n,g.encl(x,y,1))
  return n
 end
 g.follow = function(x,y,l)
  -- follow link
  x2,y2,ori=g.dcdl(l)
  if ori==0 then
   if (y!=y2) return nil
   if (x==x2) return x+1,y
   if (x==x2+1) return x-1,y
   return nil
  end
  if (x!=x2) return nil
  if (y==y2) return x,y+1
  if (y==y2+1) return x,y-1
  return nil
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
 for i=0,g.w*g.h-1 do
  cells[i]=0
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
 m.draw=function()
  for i=0,g.w*g.h-1 do
   local c=cells[i]
   local x,y=g.xy(i)
   x*=8 y*=8
   rectfill(x+2,y+2,x+5,y+5,11)
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
